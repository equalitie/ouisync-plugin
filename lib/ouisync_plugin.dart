import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:messagepack/messagepack.dart';

import 'bindings.dart';
import 'state_monitor.dart';
import 'internal/util.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

const bool debugTrace = false;

/// MethodChannel handler for calling functions
/// implemented natively, and viceversa.
class NativeChannels {
  // We need this "global" `session` variable to be able to close the session
  // from inside the java/kotlin code when the plugin is detached from the
  // engine. This is because when the app is set up to ignore battery
  // optimizations, Android may let the native (c/c++/rust) code running even
  // after the plugin was detached.
  static Session? session;

  static final MethodChannel _channel = const MethodChannel('ouisync_plugin');

  static Repository? _repository;

  // Cache of open files.
  static final _files = FileCache();

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
  static void setRepository(Repository? repository) {
    for (var file in _files.removeAll()) {
      file.close();
    }

    _repository = repository;
  }

  /// Handler method in charge of picking the right function based in the
  /// [call.method].
  ///
  /// [call] is the object sent from the native platform with the function name ([call.method])
  /// and any arguments included ([call.arguments])
  static Future<dynamic> _methodHandler(MethodCall call) async {
    switch (call.method) {
      case 'openFile':
        final args = call.arguments as Map<Object?, Object?>;
        final path = args["path"] as String;

        return await _openFile(path);

      case 'readFile':
        final args = call.arguments as Map<Object?, Object?>;
        final id = args["id"] as int;
        final chunkSize = args["chunkSize"] as int;
        final offset = args["offset"] as int;

        return await _readFile(id, chunkSize, offset);

      case 'closeFile':
        final args = call.arguments as Map<Object?, Object?>;
        final id = args["id"] as int;

        return await _closeFile(id);

      case 'copyFileToRawFd':
        final args = call.arguments as Map<Object?, Object?>;
        final srcPath = args["srcPath"] as String;
        final dstFd = args["dstFd"] as int;

        return await _copyFileToRawFd(srcPath, dstFd);

      case 'stopSession':
        session?.close();
        session = null;
        return;

      default:
        throw Exception('No method called ${call.method} was found');
    }
  }

  static Future<int?> _openFile(String path) async {
    final id = _files.insert(await File.open(_repository!, path));
    print('openFile(path=$path) -> id=$id');
    return id;
  }

  static Future<void> _closeFile(int id) async {
    print('closeFile(id=$id)');

    final file = _files.remove(id);

    if (file != null) {
      await file.close();
    }
  }

  static Future<Uint8List> _readFile(int id, int chunkSize, int offset) async {
    print('readFile(id=$id, chunkSize=$chunkSize, offset=$offset)');

    final file = _files[id];

    if (file != null) {
      final chunk = await file.read(offset, chunkSize);
      return Uint8List.fromList(chunk);
    } else {
      throw Exception('failed to read file with id=$id: not opened');
    }
  }

  static Future<void> _copyFileToRawFd(String srcPath, int dstFd) async {
    final file = await File.open(_repository!, srcPath);
    await file.copyToRawFd(dstFd);
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
  static Future<void> previewOuiSyncFile(String path, int size,
      {bool useDefaultApp = false}) async {
    var args = {"path": path, "size": size};

    if (useDefaultApp == true) {
      args["useDefaultApp"] = true;
    }

    final dynamic result = await _channel.invokeMethod('previewFile', args);
    print('previewFile result: $result');
  }
}

// Cache of open files.
class FileCache {
  final _files = HashMap<int, File>();
  var _nextId = 0;

  List<File> removeAll() {
    var files = _files.values.toList();
    _files.clear();
    return files;
  }

  int insert(File file) {
    final id = _nextId;
    _nextId += 1;
    _files[id] = file;
    return id;
  }

  File? remove(int id) => _files.remove(id);

  File? operator [](int id) => _files[id];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

/// Entry point to the ouisync bindings. A session should be opened at the start of the application
/// and closed at the end. There can be only one session at the time.
class Session {
  final Bindings bindings;

  Session._(this.bindings);

  /// Opens a new session. [configsDirPath] is a path to a directory where
  /// configuration files shall be stored. If it doesn't exists, it will be
  /// created.
  static Future<Session> open(String configsDirPath) async {
    if (debugTrace) {
      print("Session.open $configsDirPath");
    }

    final bindings = Bindings(_defaultLib());

    await _withPool((pool) => _invoke<void>((port) => bindings.session_open(
        NativeApi.postCObject.cast<Void>(),
        pool.toNativeUtf8(configsDirPath),
        port)));

    final session = Session._(bindings);
    NativeChannels.session = session;
    return session;
  }

  /// Subscribe to network event notifications.
  Subscription subscribeToNetworkEvents(void Function(NetworkEvent) callback) {
    if (debugTrace) {
      print("Session.subscribeToNetworkEvents");
    }

    final recvPort = ReceivePort();

    recvPort.listen((encoded) {
      final event = _decodeNetworkEvent(encoded as int);
      if (event != null) {
        callback(event);
      } else {
        print('invalid network event: $encoded');
      }
    });

    final subscriptionHandle =
        bindings.network_subscribe(recvPort.sendPort.nativePort);

    return Subscription._(bindings, subscriptionHandle, recvPort);
  }

  bool addUserProvidedQuicPeer(String addr) {
    return _withPoolSync((pool) =>
        bindings.network_add_user_provided_quic_peer(pool.toNativeUtf8(addr)));
  }

  bool removeUserProvidedQuicPeer(String addr) {
    return _withPoolSync((pool) => bindings
        .network_remove_user_provided_quic_peer(pool.toNativeUtf8(addr)));
  }

  String? get tcpListenerLocalAddressV4 => bindings
      .network_tcp_listener_local_addr_v4()
      .cast<Utf8>()
      .intoNullableDartString();

  String? get tcpListenerLocalAddressV6 => bindings
      .network_tcp_listener_local_addr_v6()
      .cast<Utf8>()
      .intoNullableDartString();

  String? get quicListenerLocalAddressV4 => bindings
      .network_quic_listener_local_addr_v4()
      .cast<Utf8>()
      .intoNullableDartString();

  String? get quicListenerLocalAddressV6 => bindings
      .network_quic_listener_local_addr_v6()
      .cast<Utf8>()
      .intoNullableDartString();

  List<ConnectedPeer> get connectedPeers {
    final bytes = bindings.network_connected_peers().intoUint8List();
    final unpacker = Unpacker(bytes);
    return ConnectedPeer.decodeAll(unpacker);
  }

  StateMonitor? getRootStateMonitor() {
    return StateMonitor.getRoot(bindings);
  }

  int get currentProtocolVersion => bindings.network_current_protocol_version();

  int get highestSeenProtocolVersion =>
      bindings.network_highest_seen_protocol_version();

  /// Enable netowork
  void enableNetwork() {
    bindings.network_enable();
  }

  /// Disable netowork
  void disableNetwork() {
    bindings.network_disable();
  }

  /// Is port forwarding (UPnP) enabled?
  bool get isPortForwardingEnabled =>
      bindings.network_is_port_forwarding_enabled();

  /// Enable port forwarding (UPnP)
  void enablePortForwarding() {
    bindings.network_enable_port_forwarding();
  }

  /// Disable port forwarding (UPnP)
  void disablePortForwarding() {
    bindings.network_disable_port_forwarding();
  }

  /// Is local discovery enabled?
  bool get isLocalDiscoveryEnabled =>
      bindings.network_is_local_discovery_enabled();

  /// Enable local discovery
  void enableLocalDiscovery() {
    bindings.network_enable_local_discovery();
  }

  /// Disable local discovery
  void disableLocalDiscovery() {
    bindings.network_disable_local_discovery();
  }

  /// Closes the session.
  void close() {
    if (debugTrace) {
      print("Session.close");
    }

    bindings.session_close();
    NativeChannels.session = null;
  }
}

class ConnectedPeer {
  final String ip;
  final int port;
  final String direction;
  final String state;

  ConnectedPeer(this.ip, this.port, this.direction, this.state);

  static ConnectedPeer decode(Unpacker unpacker) {
    final count = unpacker.unpackListLength();
    assert(count == 4);

    final ip = unpacker.unpackString()!;
    final port = unpacker.unpackInt()!;
    final direction = unpacker.unpackString()!;
    final state = unpacker.unpackString()!;

    return ConnectedPeer(ip, port, direction, state);
  }

  static List<ConnectedPeer> decodeAll(Unpacker unpacker) {
    final count = unpacker.unpackListLength();
    return Iterable.generate(count, (_) => ConnectedPeer.decode(unpacker))
        .toList();
  }

  @override
  String toString() => '$ip:$port, $direction, $state';
}

enum NetworkEvent {
  protocolVersionMismatch,
  peerSetChange,
}

NetworkEvent? _decodeNetworkEvent(int n) {
  switch (n) {
    case NETWORK_EVENT_PROTOCOL_VERSION_MISMATCH:
      return NetworkEvent.protocolVersionMismatch;
    case NETWORK_EVENT_PEER_SET_CHANGE:
      return NetworkEvent.peerSetChange;
    default:
      return null;
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
    if (debugTrace) {
      print("Repository.create $store");
    }

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
    if (debugTrace) {
      print("Repository.open $store");
    }

    final bindings = session.bindings;
    final handle = await _withPool((pool) => _invoke<int>((port) =>
        bindings.repository_open(pool.toNativeUtf8(store),
            password != null ? pool.toNativeUtf8(password) : nullptr, port)));

    return Repository._(bindings, handle);
  }

  /// Close the repository. Accessing the repository after it's been closed is undefined behaviour
  /// (likely crash).
  Future<void> close() async {
    if (debugTrace) {
      print("Repository.close");
    }

    final recvPort = ReceivePort();

    try {
      bindings.repository_close(handle, recvPort.sendPort.nativePort);
      await recvPort.first;
    } finally {
      recvPort.close();
    }
  }

  /// Returns the type (file, directory, ..) of the entry at [path]. Returns `null` if the entry
  /// doesn't exists.
  Future<EntryType?> type(String path) async {
    if (debugTrace) {
      print("Repository.type $path");
    }

    return _decodeEntryType(await _withPool((pool) => _invoke<int>((port) =>
        bindings.repository_entry_type(
            handle, pool.toNativeUtf8(path), port))));
  }

  /// Returns whether the entry (file or directory) at [path] exists.
  Future<bool> exists(String path) async {
    if (debugTrace) {
      print("Repository.exists $path");
    }

    return await type(path) != null;
  }

  /// Move/rename the file/directory from [src] to [dst].
  Future<void> move(String src, String dst) {
    if (debugTrace) {
      print("Repository.move $src -> $dst");
    }

    return _withPool((pool) => _invoke<void>((port) =>
        bindings.repository_move_entry(
            handle, pool.toNativeUtf8(src), pool.toNativeUtf8(dst), port)));
  }

  /// Subscribe to change notifications from this repository. The returned handle can be used to
  /// cancel the subscription.
  Subscription subscribe(void Function() callback) {
    if (debugTrace) {
      print("Repository.subscribe");
    }

    final recvPort = ReceivePort();
    recvPort.listen((_) => callback());

    final subscriptionHandle =
        bindings.repository_subscribe(handle, recvPort.sendPort.nativePort);

    return Subscription._(bindings, subscriptionHandle, recvPort);
  }

  bool get isDhtEnabled {
    if (debugTrace) {
      print("Repository.isDhtEnabled");
    }

    return bindings.repository_is_dht_enabled(handle);
  }

  void enableDht() {
    if (debugTrace) {
      print("Repository.enableDht");
    }

    bindings.repository_enable_dht(handle);
  }

  void disableDht() {
    if (debugTrace) {
      print("Repository.disableDht");
    }

    bindings.repository_disable_dht(handle);
  }

  bool get isPexEnabled {
    return bindings.repository_is_pex_enabled(handle);
  }

  void enablePex() {
    bindings.repository_enable_pex(handle);
  }

  void disablePex() {
    bindings.repository_disable_pex(handle);
  }

  AccessMode get accessMode {
    if (debugTrace) {
      print("Repository.get accessMode");
    }

    return _decodeAccessMode(bindings.repository_access_mode(handle))!;
  }

  /// Create a share token providing access to this repository with the given mode. Can optionally
  /// specify repository name which will be included in the token and suggested to the recipient.
  Future<ShareToken> createShareToken(
      {required AccessMode accessMode, String? name}) async {
    if (debugTrace) {
      print("Repository.createShareToken");
    }

    return ShareToken._(
        bindings,
        await _withPool((pool) => _invoke<String>((port) =>
            bindings.repository_create_share_token(
                handle,
                _encodeAccessMode(accessMode),
                name != null ? pool.toNativeUtf8(name) : nullptr,
                port))));
  }

  Future<Progress> syncProgress() async {
    final bytes = await _invoke<Uint8List>(
        (port) => bindings.repository_sync_progress(handle, port));
    final unpacker = Unpacker(bytes);
    return Progress.decode(unpacker);
  }

  StateMonitor? stateMonitor() {
    return StateMonitor.getRoot(bindings)
        ?.child("Repositories")
        ?.child(lowHexId());
  }

  String lowHexId() {
    return bindings.repository_low_hex_id(handle).cast<Utf8>().intoDartString();
  }
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
          final token = tokenPtr.cast<Utf8>().intoDartString();
          return ShareToken(session, token);
        } else {
          return null;
        }
      });

  /// Encode this share token into raw bytes (for example to build a QR code from).
  Uint8List encode() => _withPoolSync((pool) =>
      bindings.share_token_encode(pool.toNativeUtf8(token)).intoUint8List());

  /// Get the suggested repository name from the share token.
  String get suggestedName {
    final namePtr = _withPoolSync((pool) =>
        bindings.share_token_suggested_name(pool.toNativeUtf8(token)));
    final name = namePtr.cast<Utf8>().toDartString();
    freeNative(namePtr);

    return name;
  }

  String repositoryId() {
    final idPtr = _withPoolSync((pool) =>
        bindings.share_token_repository_low_hex_id(pool.toNativeUtf8(token)));
    return idPtr.cast<Utf8>().intoNullableDartString()!;
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

class Progress {
  final int value;
  final int total;

  Progress(this.value, this.total);

  static Progress decode(Unpacker unpacker) {
    final count = unpacker.unpackListLength();
    assert(count == 2);

    final value = unpacker.unpackInt()!;
    final total = unpacker.unpackInt()!;

    return Progress(value, total);
  }

  @override
  String toString() => '$value/$total';

  @override
  bool operator ==(Object other) =>
      other is Progress && other.value == value && other.total == total;

  @override
  int get hashCode => Object.hash(value, total);
}

/// A handle to a subscription.
class Subscription {
  final Bindings bindings;
  final int handle;
  final ReceivePort port;

  Subscription._(this.bindings, this.handle, this.port);

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
  static Future<Directory> open(Repository repo, String path) async {
    if (debugTrace) {
      print("Directory.open $path");
    }

    return Directory._(
        repo.bindings,
        await _withPool((pool) => _invoke<int>((port) => repo.bindings
            .directory_open(repo.handle, pool.toNativeUtf8(path), port))));
  }

  /// Creates a new directory in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<void> create(Repository repo, String path) {
    if (debugTrace) {
      print("Directory.create $path");
    }

    return _withPool((pool) => _invoke<void>((port) => repo.bindings
        .directory_create(repo.handle, pool.toNativeUtf8(path), port)));
  }

  /// Remove a directory from [repo] at [path]. If [recursive] is false (which is the default),
  /// the directory must be empty otherwise an exception is thrown. If [recursive] it is true, the
  /// content of the directory is removed as well.
  static Future<void> remove(Repository repo, String path,
      {bool recursive = false}) {
    if (debugTrace) {
      print("Directory.remove $path");
    }

    final fun = recursive
        ? repo.bindings.directory_remove_recursively
        : repo.bindings.directory_remove;

    return _withPool((pool) => _invoke<void>(
        (port) => fun(repo.handle, pool.toNativeUtf8(path), port)));
  }

  /// Closes this directory.
  void close() {
    if (debugTrace) {
      print("Directory.close");
    }

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
  static Future<File> open(Repository repo, String path) async {
    if (debugTrace) {
      print("File.open");
    }

    return File._(
        repo.bindings,
        await _withPool((pool) => _invoke<int>((port) => repo.bindings
            .file_open(repo.handle, pool.toNativeUtf8(path), port))));
  }

  /// Creates a new file in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<File> create(Repository repo, String path) async {
    if (debugTrace) {
      print("File.create $path");
    }

    return File._(
        repo.bindings,
        await _withPool((pool) => _invoke<int>((port) => repo.bindings
            .file_create(repo.handle, pool.toNativeUtf8(path), port))));
  }

  /// Removes (deletes) a file at [path] from [repo].
  static Future<void> remove(Repository repo, String path) {
    if (debugTrace) {
      print("File.remove $path");
    }

    return _withPool((pool) => _invoke<void>((port) =>
        repo.bindings.file_remove(repo.handle, pool.toNativeUtf8(path), port)));
  }

  /// Flushed and closes this file.
  Future<void> close() {
    if (debugTrace) {
      print("File.close");
    }

    return _invoke<void>((port) => bindings.file_close(handle, port));
  }

  /// Flushes any pending writes to this file.
  Future<void> flush() {
    if (debugTrace) {
      print("File.flush");
    }

    return _invoke<void>((port) => bindings.file_flush(handle, port));
  }

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
    if (debugTrace) {
      print("File.read");
    }

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
    if (debugTrace) {
      print("File.write");
    }

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
  Future<void> truncate(int size) {
    if (debugTrace) {
      print("File.truncate");
    }

    return _invoke<void>((port) => bindings.file_truncate(handle, size, port));
  }

  /// Returns the length of this file in bytes.
  Future<int> get length {
    if (debugTrace) {
      print("File.length");
    }

    return _invoke<int>((port) => bindings.file_len(handle, port));
  }

  /// Copy the contents of the file into the provided raw file descriptor.
  Future<void> copyToRawFd(int fd) {
    if (debugTrace) {
      print("File.copyToRawFd");
    }

    return _invoke<void>(
        (port) => bindings.file_copy_to_raw_fd(handle, fd, port));
  }
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
  final env = Platform.environment;

  if (env.containsKey('OUISYNC_LIB')) {
    return DynamicLibrary.open(env['OUISYNC_LIB']!);
  }

  final name = 'ouisync_ffi';

  if (env.containsKey('FLUTTER_TEST')) {
    late final String path;

    if (kReleaseMode) {
      path = 'ouisync/target/release';
    } else {
      path = 'ouisync/target/debug';
    }

    if (Platform.isLinux) {
      return DynamicLibrary.open('$path/lib$name.so');
    }

    if (Platform.isMacOS) {
      return DynamicLibrary.open('$path/lib$name.dylib');
    }

    if (Platform.isWindows) {
      return DynamicLibrary.open('$path/$name.dll');
    }
  }

  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$name.so');
  }

  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  if (Platform.isWindows) {
    return DynamicLibrary.open('$name.dll');
  }

  if (Platform.isLinux) {
    return DynamicLibrary.open('lib$name.so');
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

extension Utf8Pointer on Pointer<Utf8> {
  // Similar to [toDartString] but also deallocates the original pointer.
  String intoDartString() {
    final string = toDartString();
    freeNative(this);
    return string;
  }

  String? intoNullableDartString() {
    if (address == 0) {
      return null;
    }
    final string = toDartString();
    freeNative(this);
    return string;
  }
}

extension BytesExtension on Bytes {
  // Converts this `Bytes` into `Uint8List` and deallocates the original pointer.
  Uint8List intoUint8List() => bytesIntoUint8List(this);
}
