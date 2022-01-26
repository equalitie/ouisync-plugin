import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'bindings.dart';

/// MethodChannel handler for calling functions
/// implemented natively, and viceversa.
class NativeChannels {
  static final MethodChannel _channel = const MethodChannel('ouisync_plugin');

  static Repository? _repository;

  /// Provides the Session instance, to be used in file operations.
  /// [session] is the instance used in the OuiSync app for accessing the repository.
  ///
  /// This methoid also sets the method handler for the calls
  /// to and from native implementations.
  ///
  /// Important: This method needs to be called when the app starts
  /// to guarantee the callbacks to the native methods works as expected.
  static void init({Repository? repository}) {
    _channel.setMethodCallHandler(_methodHandler);

    if (repository != null) {
      _repository = repository;
    }
  }

  /// Replaces the current [repository] instance with a new one.
  ///
  /// This method is used when the user switch between repositories;
  /// the [repository] passed in to this function is used for any
  /// required operation.
  ///
  /// [repository] is the current repository in the app.
  static void setRepository(Repository repository) {
    if (_repository == null) {
      _repository = repository;
      return;
    }

    if (repository.handle != _repository!.handle) {
      _repository = repository;
    }
  }

  /// Handler method in charge of picking the right function based in the
  /// [call.method].
  ///
  /// [call] is the object sent from the native platform with the function name ([call.method])
  /// and any arguments included ([call.arguments])
  static Future<dynamic> _methodHandler(MethodCall call) async {
    switch (call.method) {
      case 'readOuiSyncFile':
        try {
          var args = call.arguments as Map<Object?, Object?>;

          var repo = args["repo"].toString();
          var path = args["path"].toString();
          var chunkSize = args["chunkSize"] as int;
          var offset = args["offset"] as int;

          print(
              'repo: $repo\nfile: $path\nchunk size: $chunkSize\noffset: $offset');

          return await _getFileChunk(_repository!, path, chunkSize, offset);
        } catch (e) {
          print('readOuiSyncFile method throwed an exception: $e');
        }

        break;

      default:
        throw Exception('No method called ${call.method} was found');
    }
  }

  /// Read a chunk of size [chunkSize], starting at [offset], from the file at [path].
  static Future<Uint8List> _getFileChunk(
      Repository repository, String filePath, int chunkSize, int offset) async {
    final file = await File.open(repository, filePath);
    var fileSize = await file.length;

    try {
      final chunk = await file.read(offset, chunkSize);
      return Uint8List.fromList(chunk);
    } catch (e) {
      print('_getFileChunk throwed and exception:\n'
          'file: $filePath ($fileSize) chunk size: $chunkSize, offset: $offset\n'
          'Message: $e');
    } finally {
      file.close();
    }

    return Uint8List(0);
  }

  /// Invokes the native method (In Android, it creates a share intent using the custom PipeProvider).
  ///
  /// [path] is the location of the file to share, including its full name (<path>/<file-name.ext>).
  /// [size] is the lenght of the file (bytes).
  static Future<void> shareOuiSyncFile(String path, int size) async {
    final dynamic result =
        await _channel.invokeMethod('shareFile', {"path": path, "size": size});
    print('shareFile result: $result');
  }

  /// Invokes the native method (In Android, it creates an intent using the custom PipeProvider).
  ///
  /// [path] is the location of the file to preview, including its full name (<path>/<file-name.ext>).
  /// [size] is the lenght of the file (bytes).
  static Future<void> previewOuiSyncFile(String path, int size) async {
    final dynamic result = await _channel
        .invokeMethod('previewFile', {"path": path, "size": size});
    print('previewFile result: $result');
  }
}

/// Entry point to the ouisync bindings. A session should be opened at the start of the application
/// and closed at the end. There can be only one session at the time.
class Session {
  final Bindings bindings;

  Session._(this.bindings);

  /// Opens a new session. [store] is a path to the sqlite database to store the local
  /// configuration in. If it doesn't exists, it will be created.
  static Future<Session> open(String store) async {
    final bindings = Bindings(_defaultLib());

    await _withPool((pool) => _invoke<void>((port) => bindings.session_open(
        NativeApi.postCObject.cast<Void>(), pool.toNativeUtf8(store), port)));

    return Session._(bindings);
  }

  /// Closes the session.
  void close() {
    bindings.session_close();
  }
}

/// A reference to a ouisync repository.
class Repository {
  final Bindings bindings;
  final int handle;

  Repository._(this.bindings, this.handle);

  /// Creates a new repository.
  static Future<Repository> create(Session session,
      {required String store,
      required String password,
      ShareToken? shareToken}) async {
    final bindings = session.bindings;
    final handle = await _withPool((pool) => _invoke<int>((port) =>
        bindings.repository_create(
            pool.toNativeUtf8(store),
            pool.toNativeUtf8(password),
            shareToken != null ? pool.toNativeUtf8(shareToken.token) : nullptr,
            port)));

    return Repository._(bindings, handle);
  }

  /// Opens an existing repository.
  static Future<Repository> open(Session session,
      {required String store, String? password}) async {
    final bindings = session.bindings;
    final handle = await _withPool((pool) => _invoke<int>((port) =>
        bindings.repository_open(pool.toNativeUtf8(store),
            password != null ? pool.toNativeUtf8(password) : nullptr, port)));

    return Repository._(bindings, handle);
  }

  /// Close the repository. Accessing the repository after it's been closed is undefined behaviour
  /// (likely crash).
  void close() {
    bindings.repository_close(handle);
  }

  /// Returns the type (file, directory, ..) of the entry at [path]. Returns `null` if the entry
  /// doesn't exists.
  Future<EntryType?> type(String path) async =>
      _decodeEntryType(await _withPool((pool) => _invoke<int>((port) => bindings
          .repository_entry_type(handle, pool.toNativeUtf8(path), port))));

  /// Returns whether the entry (file or directory) at [path] exists.
  Future<bool> exists(String path) async => await type(path) != null;

  /// Move/rename the file/directory from [src] to [dst].
  Future<void> move(String src, String dst) => _withPool((pool) =>
      _invoke<void>((port) => bindings.repository_move_entry(
          handle, pool.toNativeUtf8(src), pool.toNativeUtf8(dst), port)));

  /// Subscribe to change notifications from this repository. The returned handle can be used to
  /// cancel the subscription.
  Subscription subscribe(void Function() callback) {
    final recvPort = ReceivePort();
    final subscriptionHandle =
        bindings.repository_subscribe(handle, recvPort.sendPort.nativePort);

    return Subscription._(bindings, subscriptionHandle, recvPort, callback);
  }

  Future<bool> isDhtEnabled() async {
    final recvPort = ReceivePort();
    bindings.repository_is_dht_enabled(handle, recvPort.sendPort.nativePort);
    final result = await recvPort.first as bool;
    recvPort.close();
    return result;
  }

  Future<void> enableDht() async {
    final recvPort = ReceivePort();
    bindings.repository_enable_dht(handle, recvPort.sendPort.nativePort);
    await recvPort.first;
    recvPort.close();
  }

  Future<void> disableDht() async {
    final recvPort = ReceivePort();
    bindings.repository_disable_dht(handle, recvPort.sendPort.nativePort);
    await recvPort.first;
    recvPort.close();
  }

  /// Create a share token providing access to this repository with the given mode. Can optionally
  /// specify repository name which will be included in the token and suggested to the recipient.
  Future<ShareToken> createShareToken(
          {required AccessMode accessMode, String? name}) async =>
      ShareToken._(
          bindings,
          await _withPool((pool) => _invoke<String>((port) =>
              bindings.repository_create_share_token(
                  handle,
                  _encodeAccessMode(accessMode),
                  name != null ? pool.toNativeUtf8(name) : nullptr,
                  port))));
}

class ShareToken {
  final Bindings bindings;
  final String token;

  ShareToken._(this.bindings, this.token);

  ShareToken(Session session, this.token) : bindings = session.bindings;

  /// Decode share token from raw bytes (obtained for example from a QR code).
  /// Returns null if the decoding failed.
  static ShareToken? decode(Session session, Uint8List bytes) =>
      _withPoolSync((pool) {
        final buffer = pool<Uint8>(bytes.length);
        buffer.asTypedList(bytes.length).setAll(0, bytes);

        final tokenPtr =
            session.bindings.share_token_decode(buffer, bytes.length);

        if (tokenPtr != nullptr) {
          try {
            final token = tokenPtr.cast<Utf8>().toDartString();
            return ShareToken(session, token);
          } finally {
            freeNative(tokenPtr);
          }
        } else {
          return null;
        }
      });

  /// Encode this share token into raw bytes (for example to build a QR code from).
  Uint8List encode() => _withPoolSync((pool) {
        final tokenPtr = pool.toNativeUtf8(token);
        final buffer = bindings.share_token_encode(tokenPtr);

        if (buffer.ptr != nullptr) {
          try {
            // Creating a copy so we can deallocate the pointer.
            // TODO: is this the right way to do this?
            return Uint8List.fromList(buffer.ptr.asTypedList(buffer.len));
          } finally {
            freeNative(buffer.ptr);
          }
        } else {
          return Uint8List(0);
        }
      });

  /// Get the suggested repository name from the share token.
  String get suggestedName {
    final namePtr = _withPoolSync((pool) =>
        bindings.share_token_suggested_name(pool.toNativeUtf8(token)));
    final name = namePtr.cast<Utf8>().toDartString();
    freeNative(namePtr);

    return name;
  }

  /// Get the access mode the share token provides.
  AccessMode get mode => _decodeAccessMode(_withPoolSync(
      (pool) => bindings.share_token_mode(pool.toNativeUtf8(token))))!;

  @override
  String toString() => token;

  @override
  bool operator ==(Object other) => other is ShareToken && other.token == token;

  @override
  int get hashCode => token.hashCode;
}

enum AccessMode {
  blind,
  read,
  write,
}

int _encodeAccessMode(AccessMode mode) {
  switch (mode) {
    case AccessMode.blind:
      return ACCESS_MODE_BLIND;
    case AccessMode.read:
      return ACCESS_MODE_READ;
    case AccessMode.write:
      return ACCESS_MODE_WRITE;
  }
}

AccessMode? _decodeAccessMode(int n) {
  switch (n) {
    case ACCESS_MODE_BLIND:
      return AccessMode.blind;
    case ACCESS_MODE_READ:
      return AccessMode.read;
    case ACCESS_MODE_WRITE:
      return AccessMode.write;
    default:
      return null;
  }
}

/// A handle to a change notification subscription.
class Subscription {
  final Bindings bindings;
  final int handle;
  final ReceivePort port;
  final void Function() callback;

  Subscription._(this.bindings, this.handle, this.port, this.callback) {
    port.listen((_) => callback());
  }

  /// Cancel the subscription. No more notification events are received after this.
  void cancel() {
    bindings.subscription_cancel(handle);
    port.close();
  }
}

/// Type of a filesystem entry.
enum EntryType {
  /// Regular file.
  file,

  /// Directory.
  directory,
}

EntryType? _decodeEntryType(int n) {
  switch (n) {
    case ENTRY_TYPE_FILE:
      return EntryType.file;
    case ENTRY_TYPE_DIRECTORY:
      return EntryType.directory;
    default:
      return null;
  }
}

/// Single entry of a directory.
class DirEntry {
  final Bindings bindings;
  final int handle;

  DirEntry._(this.bindings, this.handle);

  /// Name of this entry.
  ///
  /// Note: this is just the name, not the full path.
  String get name =>
      bindings.dir_entry_name(handle).cast<Utf8>().toDartString();

  /// Type of this entry (file/directory).
  EntryType get type {
    return _decodeEntryType(bindings.dir_entry_type(handle)) ??
        (throw Error(ErrorCode.other, 'invalid dir entry type'));
  }
}

/// A reference to a directory (folder) in a [Repository].
///
/// This class is [Iterable], yielding the directory entries.
///
/// Note: Currently this is a read-only snapshot of the directory at the time is was opened.
/// Subsequent external changes to the directory (e.g. added files) are not recognized and the
/// directory needs to be manually reopened to do so.
class Directory with IterableMixin<DirEntry> {
  final Bindings bindings;
  final int handle;

  Directory._(this.bindings, this.handle);

  /// Opens a directory of [repo] at [path].
  ///
  /// Throws if [path] doesn't exist or is not a directory.
  ///
  /// Note: don't forget to [close] it when no longer needed.
  static Future<Directory> open(Repository repo, String path) async =>
      Directory._(
          repo.bindings,
          await _withPool((pool) => _invoke<int>((port) => repo.bindings
              .directory_open(repo.handle, pool.toNativeUtf8(path), port))));

  /// Creates a new directory in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<void> create(Repository repo, String path) =>
      _withPool((pool) => _invoke<void>((port) => repo.bindings
          .directory_create(repo.handle, pool.toNativeUtf8(path), port)));

  /// Remove a directory from [repo] at [path]. If [recursive] is false (which is the default),
  /// the directory must be empty otherwise an exception is thrown. If [recursive] it is true, the
  /// content of the directory is removed as well.
  static Future<void> remove(Repository repo, String path,
      {bool recursive = false}) {
    final fun = recursive
        ? repo.bindings.directory_remove_recursively
        : repo.bindings.directory_remove;

    return _withPool((pool) => _invoke<void>(
        (port) => fun(repo.handle, pool.toNativeUtf8(path), port)));
  }

  /// Closes this directory.
  void close() {
    bindings.directory_close(handle);
  }

  /// Returns an [Iterator] to iterate over entries of this directory.
  @override
  Iterator<DirEntry> get iterator => DirEntriesIterator._(bindings, handle);
}

/// Iterator for a [Directory]
class DirEntriesIterator extends Iterator<DirEntry> {
  final Bindings bindings;
  final int handle;
  final int count;
  int index = -1;

  DirEntriesIterator._(this.bindings, this.handle)
      : count = bindings.directory_num_entries(handle);

  @override
  DirEntry get current {
    assert(index >= 0 && index < count);
    return DirEntry._(bindings, bindings.directory_get_entry(handle, index));
  }

  @override
  bool moveNext() {
    index = min(index + 1, count);
    return index < count;
  }
}

/// Reference to a file in a [Repository].
class File {
  final Bindings bindings;
  final int handle;

  File._(this.bindings, this.handle);

  static const defaultChunkSize = 1024;

  /// Opens an existing file from [repo] at [path].
  ///
  /// Throws if [path] doesn't exists or is a directory.
  static Future<File> open(Repository repo, String path) async => File._(
      repo.bindings,
      await _withPool((pool) => _invoke<int>((port) => repo.bindings
          .file_open(repo.handle, pool.toNativeUtf8(path), port))));

  /// Creates a new file in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<File> create(Repository repo, String path) async => File._(
      repo.bindings,
      await _withPool((pool) => _invoke<int>((port) => repo.bindings
          .file_create(repo.handle, pool.toNativeUtf8(path), port))));

  /// Removes (deletes) a file at [path] from [repo].
  static Future<void> remove(Repository repo, String path) =>
      _withPool((pool) => _invoke<void>((port) => repo.bindings
          .file_remove(repo.handle, pool.toNativeUtf8(path), port)));

  /// Flushed and closes this file.
  Future<void> close() =>
      _invoke<void>((port) => bindings.file_close(handle, port));

  /// Flushes any pending writes to this file.
  Future<void> flush() =>
      _invoke<void>((port) => bindings.file_flush(handle, port));

  /// Read [size] bytes from this file, starting at [offset].
  ///
  /// To read the whole file at once:
  ///
  /// ```dart
  /// final length = await file.length;
  /// final content = await file.read(0, length);
  /// ```
  ///
  /// To read the whole file in chunks:
  ///
  /// ```dart
  /// final chunkSize = 1024;
  /// var offset = 0;
  ///
  /// while (true) {
  ///   final chunk = await file.read(offset, chunkSize);
  ///   offset += chunk.length;
  ///
  ///   doSomethingWithTheChunk(chunk);
  ///
  ///   if (chunk.length < chunkSize) {
  ///     break;
  ///   }
  /// }
  /// ```
  Future<List<int>> read(int offset, int size) async {
    var buffer = malloc<Uint8>(size);

    try {
      final actualSize = await _invoke<int>(
          (port) => bindings.file_read(handle, offset, buffer, size, port));
      return buffer.asTypedList(actualSize).toList();
    } finally {
      malloc.free(buffer);
    }
  }

  /// Write [data] to this file starting at [offset].
  Future<void> write(int offset, List<int> data) async {
    var buffer = malloc<Uint8>(data.length);

    try {
      buffer.asTypedList(data.length).setAll(0, data);
      await _invoke<void>((port) =>
          bindings.file_write(handle, offset, buffer, data.length, port));
    } finally {
      malloc.free(buffer);
    }
  }

  /// Truncate the file to [size] bytes.
  Future<void> truncate(int size) =>
      _invoke<void>((port) => bindings.file_truncate(handle, size, port));

  /// Returns the length of this file in bytes.
  Future<int> get length =>
      _invoke<int>((port) => bindings.file_len(handle, port));
}

/// The exception type throws from this library.
class Error implements Exception {
  final String message;
  final int code;

  Error(this.code, this.message);

  @override
  String toString() => message;
}

// Private helpers to simplify working with the native API:

DynamicLibrary _defaultLib() {
  final name = 'ouisync';

  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    if (Platform.isLinux) {
      return DynamicLibrary.open('build/test/lib$name.so');
    }

    if (Platform.isMacOS) {
      return DynamicLibrary.open('build/test/lib$name.dylib');
    }

    if (Platform.isWindows) {
      return DynamicLibrary.open('build/test/lib$name.dll');
    }
  }

  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$name.so');
  }

  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  throw Exception('unsupported platform ${Platform.operatingSystem}');
}

// Call the async function passing it a [_Pool] which will be released when the function returns.
Future<T> _withPool<T>(Future<T> Function(_Pool) fun) async {
  final pool = _Pool();

  try {
    return await fun(pool);
  } finally {
    pool.release();
  }
}

// Call the sync function passing it a [_Pool] which will be released when the function returns.
T _withPoolSync<T>(T Function(_Pool) fun) {
  final pool = _Pool();

  try {
    return fun(pool);
  } finally {
    pool.release();
  }
}

// Helper to invoke a native async function.
Future<T> _invoke<T>(void Function(int) fun) async {
  final recvPort = ReceivePort();

  try {
    fun(recvPort.sendPort.nativePort);

    var code = -1;

    // Is there a better way to retrieve the first two values of a stream?
    await for (var item in recvPort) {
      if (code == -1) {
        code = item as int;
      } else if (code == ErrorCode.ok) {
        return item as T;
      } else {
        throw Error(code, item as String);
      }
    }

    throw Exception('invoked native async function did not produce any result');
  } finally {
    recvPort.close();
  }
}

// Allocator that tracks all allocations and frees them all at the same time.
class _Pool implements Allocator {
  List<Pointer<NativeType>> ptrs = [];

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final ptr = malloc.allocate<T>(byteCount, alignment: alignment);
    ptrs.add(ptr);
    return ptr;
  }

  @override
  void free(Pointer<NativeType> ptr) {
    // free on [release]
  }

  void release() {
    for (var ptr in ptrs) {
      malloc.free(ptr);
    }
  }

  // Convenience function to convert a dart string to a C-style nul-terminated utf-8 encoded
  // string pointer. The pointer is allocated using this pool.
  Pointer<Int8> toNativeUtf8(String str) =>
      str.toNativeUtf8(allocator: this).cast<Int8>();
}

// Free a pointer that was allocated by the native side.
void freeNative(Pointer<NativeType> ptr) {
  // This *should* be fine as long as both sides are using the same allocator which *should* be the
  // case (malloc). If this assumption turns out to be wrong, we should expose a native function to
  // deallocate the pointer and call it here instead.
  malloc.free(ptr);
}
