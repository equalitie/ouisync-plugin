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

          print('repo: $repo\nfile: $path\nchunk size: $chunkSize\noffset: $offset');

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
    Repository repository,
    String filePath,
    int chunkSize,
    int offset
  ) async {
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

    await _withPool((pool) => _invoke<void>((port, error) =>
        bindings.session_open(NativeApi.postCObject.cast<Void>(),
            pool.toNativeUtf8(store), port, error)));

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

  /// Opens a repository. [store] is a path to the sqlite database where the repository content
  /// should be stored. If it doesn't exist, it will be created.
  ///
  /// Important: don't forget to [close] the repository after being done with it. Failure to do so
  /// could cause a memory leak.
  static Future<Repository> open(Session session, String store) async {
    final bindings = session.bindings;
    final handle = await _withPool((pool) => _invoke<int>((port, error) =>
        bindings.repository_open(pool.toNativeUtf8(store), port, error)));

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
      _decodeEntryType(await _withPool((pool) => _invoke<int>((port, error) =>
          bindings.repository_entry_type(
              handle, pool.toNativeUtf8(path), port, error))));

  /// Returns whether the entry (file or directory) at [path] exists.
  Future<bool> exists(String path) async => await type(path) != null;

  /// Move/rename the file/directory from [src] to [dst].
  Future<void> move(String src, String dst) => _withPool((pool) =>
      _invoke<void>((port, error) => bindings.repository_move_entry(handle,
          pool.toNativeUtf8(src), pool.toNativeUtf8(dst), port, error)));

  /// Subscribe to change notifications from this repository. The returned handle can be used to
  /// cancel the subscription.
  Subscription subscribe(void Function() callback) {
    final recvPort = ReceivePort();
    final subscriptionHandle =
        bindings.repository_subscribe(handle, recvPort.sendPort.nativePort);

    return Subscription._(bindings, subscriptionHandle, recvPort, callback);
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
        (throw Error('invalid dir entry type'));
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
          await _withPool((pool) => _invoke<int>((port, error) => repo.bindings
              .directory_open(
                  repo.handle, pool.toNativeUtf8(path), port, error))));

  /// Creates a new directory in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<void> create(Repository repo, String path) => _withPool(
      (pool) => _invoke<void>((port, error) => repo.bindings.directory_create(
          repo.handle, pool.toNativeUtf8(path), port, error)));

  /// Remove a directory from [repo] at [path]. If [recursive] is false (which is the default),
  /// the directory must be empty otherwise an exception is thrown. If [recursive] it is true, the
  /// content of the directory is removed as well.
  static Future<void> remove(Repository repo, String path, {recursive: false}) {
    final fun = recursive
        ? repo.bindings.directory_remove_recursively
        : repo.bindings.directory_remove;

    return _withPool((pool) => _invoke<void>((port, error) =>
        fun(repo.handle, pool.toNativeUtf8(path), port, error)));
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
      await _withPool((pool) => _invoke<int>((port, error) => repo.bindings
          .file_open(repo.handle, pool.toNativeUtf8(path), port, error))));

  /// Creates a new file in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<File> create(Repository repo, String path) async => File._(
      repo.bindings,
      await _withPool((pool) => _invoke<int>((port, error) => repo.bindings
          .file_create(repo.handle, pool.toNativeUtf8(path), port, error))));

  /// Removes (deletes) a file at [path] from [repo].
  static Future<void> remove(Repository repo, String path) =>
      _withPool((pool) => _invoke<void>((port, error) => repo.bindings
          .file_remove(repo.handle, pool.toNativeUtf8(path), port, error)));

  /// Flushed and closes this file.
  Future<void> close() =>
      _invoke<void>((port, error) => bindings.file_close(handle, port, error));

  /// Flushes any pending writes to this file.
  Future<void> flush() =>
      _invoke<void>((port, error) => bindings.file_flush(handle, port, error));

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
      final actualSize = await _invoke<int>((port, error) =>
          bindings.file_read(handle, offset, buffer, size, port, error));
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
      await _invoke<void>((port, error) => bindings.file_write(
          handle, offset, buffer, data.length, port, error));
    } finally {
      malloc.free(buffer);
    }
  }

  /// Truncate the file to [size] bytes.
  Future<void> truncate(int size) => _invoke<void>(
      (port, error) => bindings.file_truncate(handle, size, port, error));

  /// Returns the length of this file in bytes.
  Future<int> get length =>
      _invoke<int>((port, error) => bindings.file_len(handle, port, error));
}

/// The exception type throws from this library.
class Error implements Exception {
  final String _message;

  Error(this._message);

  @override
  String toString() => _message;
}

// Private helpers to simplify working with the native API:

DynamicLibrary _defaultLib() {
  final name = 'ouisync';

  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    if (Platform.isLinux) {
      return DynamicLibrary.open('build/test/lib$name.so');
    }

    if (Platform.isMacOS) {
      return DynamicLibrary.open('build/test/$name.dylib');
    }

    if (Platform.isWindows) {
      return DynamicLibrary.open('build/test/$name.dll');
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

// Call the function passing it a [_Pool] which will be released when the function returns.
Future<T> _withPool<T>(Future<T> Function(_Pool) fun) async {
  final pool = _Pool();

  try {
    return await fun(pool);
  } finally {
    pool.release();
  }
}

// Helper to invoke a native async function.
Future<T> _invoke<T>(void Function(int, Pointer<Pointer<Int8>>) fun) async {
  final error = _ErrorHelper();
  final recvPort = ReceivePort();

  fun(recvPort.sendPort.nativePort, error.ptr);

  final result = await recvPort.first;

  recvPort.close();
  error.check();

  return result;
}

// Helper to translate native errors to dart exceptions.
class _ErrorHelper {
  var ptr = malloc<Pointer<Int8>>();

  _ErrorHelper();

  void check() {
    assert(ptr != nullptr);

    if (ptr.value != nullptr) {
      final error = ptr.value.cast<Utf8>().toDartString();

      // NOTE: we are freeing a pointer here that was allocated by the native side. This *should*
      // be fine as long as both sides are using the same allocator which *should* be the case here.
      // In case this turns out to be wrong, we should expose a native function to deallocate the
      // string and call it here instead.
      malloc.free(ptr.value);

      malloc.free(ptr);
      ptr = nullptr;

      throw Error(error);
    }
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
