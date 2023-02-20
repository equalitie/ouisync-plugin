import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';

import 'bindings_global.dart';
import 'client.dart';
import 'native_channels.dart';
import 'state_monitor.dart';

export 'native_channels.dart' show NativeChannels;

const bool debugTrace = false;

/// Entry point to the ouisync bindings. A session should be opened at the start of the application
/// and closed at the end. There can be only one session at the time.
class Session {
  final int handle;
  final Client client;
  final Subscription _networkSubscription;

  Session._(this.handle, this.client)
      : _networkSubscription = Subscription(client, "network", null) {
    NativeChannels.session = this;
  }

  /// Creates a new session in this process. [configsDirPath] is a path to a directory where
  /// configuration files shall be stored. If it doesn't exists, it will be
  /// created.
  static Session create(String configsDirPath) {
    if (debugTrace) {
      print("Session.open $configsDirPath");
    }

    final result = _withPoolSync((pool) => bindings.session_create(
          NativeApi.postCObject.cast<Void>(),
          pool.toNativeUtf8(configsDirPath),
        ));

    int handle;

    if (result.error_code == ErrorCode.ok) {
      handle = result.session;
    } else {
      final errorMessage = result.error_message.cast<Utf8>().intoDartString();
      throw Error(result.error_code, errorMessage);
    }

    final socket = MemorySocket(handle);
    final client = Client(socket);

    return Session._(handle, client);
  }

  /// Connect to a ouisync session running in a different process or even on a different device.
  static Future<Session> connect(String endpoint) async {
    final socket = await WebSocket.connect(endpoint);
    final client = Client(socket);

    return Session._(0, client);
  }

  /// Binds network to the specified addresses.
  Future<void> bindNetwork({
    String? quicV4,
    String? quicV6,
    String? tcpV4,
    String? tcpV6,
  }) async {
    await client.invoke<void>("network_bind", {
      'quic_v4': quicV4,
      'quic_v6': quicV6,
      'tcp_v4': tcpV4,
      'tcp_v6': tcpV6,
    });
  }

  Stream<NetworkEvent> get networkEvents =>
      _networkSubscription.stream.map(_decodeNetworkEvent);

  Future<void> addUserProvidedQuicPeer(String addr) =>
      client.invoke<void>('network_add_user_provided_quic_peer', addr);

  Future<void> removeUserProvidedQuicPeer(String addr) =>
      client.invoke<void>('network_remove_user_provided_quic_peer', addr);

  Future<String?> get tcpListenerLocalAddressV4 =>
      client.invoke<String?>('network_tcp_listener_local_addr_v4');

  Future<String?> get tcpListenerLocalAddressV6 =>
      client.invoke<String?>('network_tcp_listener_local_addr_v6');

  Future<String?> get quicListenerLocalAddressV4 =>
      client.invoke<String?>('network_quic_listener_local_addr_v4');

  Future<String?> get quicListenerLocalAddressV6 =>
      client.invoke<String?>('network_quic_listener_local_addr_v6');

  /// Gets a stream that yields lists of known peers.
  Stream<List<PeerInfo>> get onPeersChange async* {
    await for (final _ in networkEvents) {
      yield await peers;
    }
  }

  Future<List<PeerInfo>> get peers => client
      .invoke<List<Object?>>('network_known_peers')
      .then(PeerInfo.decodeAll);

  StateMonitor get rootStateMonitor => StateMonitor.getRoot(this);

  Future<int> get currentProtocolVersion =>
      client.invoke<int>('network_current_protocol_version');

  Future<int> get highestSeenProtocolVersion =>
      client.invoke<int>('network_highest_seen_protocol_version');

  /// Is port forwarding (UPnP) enabled?
  Future<bool> get isPortForwardingEnabled =>
      client.invoke<bool>('network_is_port_forwarding_enabled');

  /// Enable port forwarding (UPnP)
  Future<void> enablePortForwarding() =>
      client.invoke<void>('network_set_port_forwarding_enabled', true);

  /// Disable port forwarding (UPnP)
  Future<void> disablePortForwarding() =>
      client.invoke<void>('network_set_port_forwarding_enabled', false);

  /// Is local discovery enabled?
  Future<bool> get isLocalDiscoveryEnabled =>
      client.invoke<bool>('network_is_local_discovery_enabled');

  /// Enable local discovery
  Future<void> enableLocalDiscovery() =>
      client.invoke<void>('network_set_local_discovery_enabled', true);

  /// Disable local discovery
  Future<void> disableLocalDiscovery() =>
      client.invoke<void>('network_set_local_discovery_enabled', false);

  Future<String> get thisRuntimeId =>
      client.invoke<String>('network_this_runtime_id');

  /// Destroys the session.
  Future<void> dispose() async {
    if (debugTrace) {
      print("Session.dispose");
    }

    await _networkSubscription.close();
    await client.close();

    if (handle != 0) {
      bindings.session_destroy(handle);
      NativeChannels.session = null;
    }
  }

  /// Try to gracefully close connections to peers.
  Future<void> shutdownNetwork() async {
    await client.invoke<void>('network_shutdown');
  }

  /// Try to gracefully close connections to peers then close the session.
  void shutdownNetworkAndClose() {
    if (handle != 0) {
      bindings.session_shutdown_network_and_close(handle);
    }
  }
}

class PeerInfo {
  final String ip;
  final int port;
  final String source;
  final String state;
  final String? runtimeId;

  PeerInfo({
    required this.ip,
    required this.port,
    required this.source,
    required this.state,
    this.runtimeId,
  });

  static PeerInfo decode(Object? raw) {
    final map = raw as List<Object?>;

    final ip = map[0] as String;
    final port = map[1] as int;
    final source = map[2] as String;
    final state = map[3] as String;
    final runtimeId = map.length > 4 ? map[4] as String? : null;

    return PeerInfo(
      ip: ip,
      port: port,
      source: source,
      state: state,
      runtimeId: runtimeId,
    );
  }

  static List<PeerInfo> decodeAll(List<Object?> raw) =>
      raw.map((rawItem) => PeerInfo.decode(rawItem)).toList();

  @override
  String toString() =>
      '$runtimeType(ip: $ip, port: $port, source: $source, state: $state, runtimeId: $runtimeId)';
}

enum NetworkEvent {
  protocolVersionMismatch,
  peerSetChange,
}

NetworkEvent _decodeNetworkEvent(Object? raw) {
  switch (raw) {
    case NETWORK_EVENT_PROTOCOL_VERSION_MISMATCH:
      return NetworkEvent.protocolVersionMismatch;
    case NETWORK_EVENT_PEER_SET_CHANGE:
      return NetworkEvent.peerSetChange;
    default:
      throw Exception('invalid network event');
  }
}

/// A reference to a ouisync repository.
class Repository {
  final Session session;
  final int handle;
  final String _store;
  final Subscription _subscription;

  Repository._(this.session, this.handle, this._store)
      : _subscription = Subscription(session.client, "repository", handle);

  /// Creates a new repository and set access to it based on the following table:
  ///
  /// local_read_password  |  local_write_password  |  token access  |  result
  /// ---------------------+------------------------+----------------+------------------------------
  /// null or any          |  null or any           |  blind         |  blind replica
  /// null                 |  null or any           |  read          |  read without password
  /// read_pwd             |  null or any           |  read          |  read with read_pwd as password
  /// null                 |  null                  |  write         |  read and write without password
  /// any                  |  null                  |  write         |  read (only!) with password
  /// null                 |  any                   |  write         |  read without password, require password for writing
  /// any                  |  any                   |  write         |  read with one password, write with (possibly same) one
  static Future<Repository> create(
    Session session, {
    required String store,
    required String? readPassword,
    required String? writePassword,
    ShareToken? shareToken,
  }) async {
    if (debugTrace) {
      print("Repository.create $store");
    }

    final handle = await session.client.invoke<int>(
      'repository_create',
      {
        'path': store,
        'read_password': readPassword,
        'write_password': writePassword,
        'share_token': shareToken?.token
      },
    );

    return Repository._(session, handle, store);
  }

  /// Opens an existing repository.
  static Future<Repository> open(
    Session session, {
    required String store,
    String? password,
  }) async {
    if (debugTrace) {
      print("Repository.open $store");
    }

    final handle = await session.client.invoke<int>('repository_open', {
      'path': store,
      'password': password,
    });

    return Repository._(session, handle, store);
  }

  /// Close the repository. Accessing the repository after it's been closed is an error.
  Future<void> close() async {
    if (debugTrace) {
      print("Repository.close");
    }

    await _subscription.close();
    await session.client.invoke('repository_close', handle);
  }

  /// Returns the type (file, directory, ..) of the entry at [path]. Returns `null` if the entry
  /// doesn't exists.
  Future<EntryType?> type(String path) async {
    if (debugTrace) {
      print("Repository.type $path");
    }

    final raw = await session.client.invoke<int?>('repository_entry_type', {
      'repository': handle,
      'path': path,
    });

    return raw != null ? _decodeEntryType(raw) : null;
  }

  /// Returns whether the entry (file or directory) at [path] exists.
  Future<bool> exists(String path) async {
    if (debugTrace) {
      print("Repository.exists $path");
    }

    return await type(path) != null;
  }

  /// Move/rename the file/directory from [src] to [dst].
  Future<void> move(String src, String dst) async {
    if (debugTrace) {
      print("Repository.move $src -> $dst");
    }

    await session.client.invoke<void>('repository_move_entry', {
      'repository': handle,
      'src': src,
      'dst': dst,
    });
  }

  Stream<void> get events => _subscription.stream.cast<void>();

  Future<bool> get isDhtEnabled async {
    if (debugTrace) {
      print("Repository.isDhtEnabled");
    }

    return await session.client
        .invoke<bool>('repository_is_dht_enabled', handle);
  }

  Future<void> enableDht() async {
    if (debugTrace) {
      print("Repository.enableDht");
    }

    await session.client.invoke<void>('repository_set_dht_enabled', {
      'repository': handle,
      'enabled': true,
    });
  }

  Future<void> disableDht() async {
    if (debugTrace) {
      print("Repository.disableDht");
    }

    await session.client.invoke<void>('repository_set_dht_enabled', {
      'repository': handle,
      'enabled': false,
    });
  }

  Future<bool> get isPexEnabled =>
      session.client.invoke<bool>('repository_is_pex_enabled', handle);

  Future<void> enablePex() =>
      session.client.invoke<void>('repository_set_pex_enabled', {
        'repository': handle,
        'enabled': true,
      });

  Future<void> disablePex() =>
      session.client.invoke<void>('repository_set_pex_enabled', {
        'repository': handle,
        'enabled': false,
      });

  Future<AccessMode> get accessMode {
    if (debugTrace) {
      print("Repository.get accessMode");
    }

    return session.client
        .invoke<int>('repository_access_mode', handle)
        .then((n) => _decodeAccessMode(n)!);
  }

  /// Create a share token providing access to this repository with the given mode. Can optionally
  /// specify repository name which will be included in the token and suggested to the recipient.
  Future<ShareToken> createShareToken({
    required AccessMode accessMode,
    String? password,
    String? name,
  }) {
    if (debugTrace) {
      print("Repository.createShareToken");
    }

    return session.client.invoke<String>('repository_create_share_token', {
      'repository': handle,
      'password': password,
      'access_mode': _encodeAccessMode(accessMode),
      'name': name,
    }).then((token) => ShareToken._(session, token));
  }

  Future<Progress> get syncProgress => session.client
      .invoke<List<Object?>>('repository_sync_progress', handle)
      .then(Progress.decode);

  StateMonitor get stateMonitor => StateMonitor.getRoot(session)
      .child(MonitorId.expectUnique("Repositories"))
      .child(MonitorId.expectUnique("repo(store=\"$_store\")"));

  Future<String> get infoHash =>
      session.client.invoke<String>("repository_info_hash", handle);

  Future<void> setReadWriteAccess({
    required String? oldPassword,
    required String newPassword,
    required ShareToken? shareToken,
  }) =>
      session.client.invoke<void>('repository_set_read_and_write_access', {
        'repository': handle,
        'old_password': oldPassword,
        'new_password': newPassword,
        'share_token': shareToken?.toString(),
      });

  Future<void> setReadAccess({
    required String newPassword,
    required ShareToken? shareToken,
  }) =>
      session.client.invoke<void>('repository_set_read_access', {
        'repository': handle,
        'password': newPassword,
        'share_token': shareToken?.toString(),
      });

  Future<String> hexDatabaseId() async {
    final bytes = await session.client
        .invoke<Uint8List>("repository_database_id", handle);
    return HEX.encode(bytes);
  }
}

class ShareToken {
  final Session session;
  final String token;

  ShareToken._(this.session, this.token);

  static Future<ShareToken> fromString(Session session, String s) =>
      session.client
          .invoke<String>('share_token_normalize', s)
          .then((s) => ShareToken._(session, s));

  /// Decode share token from raw bytes (obtained for example from a QR code).
  /// Returns null if the decoding failed.
  static Future<ShareToken?> decode(Session session, Uint8List bytes) => session
      .client
      .invoke<String?>('share_token_decode', bytes)
      .then((token) => (token != null) ? ShareToken._(session, token) : null);

  /// Encode this share token into raw bytes (for example to build a QR code from).
  Future<Uint8List> encode() =>
      session.client.invoke<Uint8List>('share_token_encode', token);

  /// Get the suggested repository name from the share token.
  Future<String> get suggestedName =>
      session.client.invoke<String>('share_token_suggested_name', token);

  Future<String> get infoHash =>
      session.client.invoke<String>('share_token_info_hash', token);

  /// Get the access mode the share token provides.
  Future<AccessMode> get mode => session.client
      .invoke<int>('share_token_mode', token)
      .then((n) => _decodeAccessMode(n)!);

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

  static Progress decode(List<Object?> raw) {
    final value = raw[0] as int;
    final total = raw[1] as int;

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

/// Type of a filesystem entry.
enum EntryType {
  /// Regular file.
  file,

  /// Directory.
  directory,
}

EntryType _decodeEntryType(int n) {
  switch (n) {
    case ENTRY_TYPE_FILE:
      return EntryType.file;
    case ENTRY_TYPE_DIRECTORY:
      return EntryType.directory;
    default:
      throw Exception('invalid entry type');
  }
}

/// Single entry of a directory.
class DirEntry {
  final String name;
  final EntryType entryType;

  DirEntry(this.name, this.entryType);

  static DirEntry decode(Object? raw) {
    final map = raw as List<Object?>;
    final name = map[0] as String;
    final type = map[1] as int;

    return DirEntry(name, _decodeEntryType(type));
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
  final List<DirEntry> entries;

  Directory._(this.entries);

  /// Opens a directory of [repo] at [path].
  ///
  /// Throws if [path] doesn't exist or is not a directory.
  ///
  /// Note: don't forget to [close] it when no longer needed.
  static Future<Directory> open(Repository repo, String path) async {
    if (debugTrace) {
      print("Directory.open $path");
    }

    final rawEntries = await repo.session.client.invoke<List<Object?>>(
      'directory_open',
      {
        'repository': repo.handle,
        'path': path,
      },
    );
    final entries = rawEntries.map(DirEntry.decode).toList();

    return Directory._(entries);
  }

  /// Creates a new directory in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<void> create(Repository repo, String path) {
    if (debugTrace) {
      print("Directory.create $path");
    }

    return repo.session.client.invoke<void>('directory_create', {
      'repository': repo.handle,
      'path': path,
    });
  }

  /// Remove a directory from [repo] at [path]. If [recursive] is false (which is the default),
  /// the directory must be empty otherwise an exception is thrown. If [recursive] it is true, the
  /// content of the directory is removed as well.
  static Future<void> remove(
    Repository repo,
    String path, {
    bool recursive = false,
  }) {
    if (debugTrace) {
      print("Directory.remove $path");
    }

    return repo.session.client.invoke<void>('directory_remove', {
      'repository': repo.handle,
      'path': path,
      'recursive': recursive,
    });
  }

  /// Returns an [Iterator] to iterate over entries of this directory.
  @override
  Iterator<DirEntry> get iterator => entries.iterator;
}

/// Reference to a file in a [Repository].
class File {
  Session session;
  final int handle;

  File._(this.session, this.handle);

  static const defaultChunkSize = 1024;

  /// Opens an existing file from [repo] at [path].
  ///
  /// Throws if [path] doesn't exists or is a directory.
  static Future<File> open(Repository repo, String path) async {
    if (debugTrace) {
      print("File.open");
    }

    return File._(
        repo.session,
        await repo.session.client.invoke<int>('file_open', {
          'repository': repo.handle,
          'path': path,
        }));
  }

  /// Creates a new file in [repo] at [path].
  ///
  /// Throws if [path] already exists of if the parent of [path] doesn't exists.
  static Future<File> create(Repository repo, String path) async {
    if (debugTrace) {
      print("File.create $path");
    }

    return File._(
        repo.session,
        await repo.session.client.invoke<int>('file_create', {
          'repository': repo.handle,
          'path': path,
        }));
  }

  /// Removes (deletes) a file at [path] from [repo].
  static Future<void> remove(Repository repo, String path) {
    if (debugTrace) {
      print("File.remove $path");
    }

    return repo.session.client.invoke<void>('file_remove', {
      'repository': repo.handle,
      'path': path,
    });
  }

  /// Flushed and closes this file.
  Future<void> close() {
    if (debugTrace) {
      print("File.close");
    }

    return session.client.invoke<void>('file_close', handle);
  }

  /// Flushes any pending writes to this file.
  Future<void> flush() {
    if (debugTrace) {
      print("File.flush");
    }

    return session.client.invoke<void>('file_flush', handle);
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
  Future<List<int>> read(int offset, int size) {
    if (debugTrace) {
      print("File.read");
    }

    return session.client.invoke<Uint8List>(
        'file_read', {'file': handle, 'offset': offset, 'len': size});
  }

  /// Write [data] to this file starting at [offset].
  Future<void> write(int offset, List<int> data) {
    if (debugTrace) {
      print("File.write");
    }

    return session.client.invoke<void>('file_write', {
      'file': handle,
      'offset': offset,
      'data': Uint8List.fromList(data),
    });
  }

  /// Truncate the file to [size] bytes.
  Future<void> truncate(int size) {
    if (debugTrace) {
      print("File.truncate");
    }

    return session.client.invoke<void>('file_truncate', {
      'file': handle,
      'len': size,
    });
  }

  /// Returns the length of this file in bytes.
  Future<int> get length {
    if (debugTrace) {
      print("File.length");
    }

    return session.client.invoke<int>('file_len', handle);
  }

  /// Copy the contents of the file into the provided raw file descriptor.
  Future<void> copyToRawFd(int fd) {
    if (debugTrace) {
      print("File.copyToRawFd");
    }

    return _invoke<void>((port) =>
        bindings.file_copy_to_raw_fd(session.handle, handle, fd, port));
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

class MemorySocket extends ClientSocket {
  MemorySocket._(
    Stream<Uint8List> stream,
    Sink<Uint8List> sink,
  ) : super(stream, sink);

  factory MemorySocket(int sessionHandle) {
    final recvPort = ReceivePort();
    final senderHandle = bindings.session_channel_open(
      sessionHandle,
      recvPort.sendPort.nativePort,
    );

    final stream = recvPort.cast<Uint8List>();
    final sink = MemorySink(sessionHandle, senderHandle);

    return MemorySocket._(stream, sink);
  }
}

class MemorySink extends Sink<Uint8List> {
  final int _session;
  final int _sender;

  MemorySink(this._session, this._sender);

  @override
  void add(Uint8List data) {
    // TODO: is there a way to do this without having to allocate whole new buffer?
    var buffer = malloc<Uint8>(data.length);

    try {
      buffer.asTypedList(data.length).setAll(0, data);
      bindings.session_channel_send(_session, _sender, buffer, data.length);
    } finally {
      malloc.free(buffer);
    }
  }

  @override
  void close() {
    bindings.session_channel_close(_session, _sender);
  }
}

class WebSocket extends ClientSocket {
  WebSocket._(Stream<Uint8List> stream, Sink<Uint8List> sink)
      : super(stream, sink);

  static Future<WebSocket> connect(String endpoint) async {
    final inner = await io.WebSocket.connect('ws://$endpoint');
    final transformer = StreamTransformer<dynamic, Uint8List>.fromHandlers(
      handleData: (data, sink) {
        if (data is List<int>) {
          sink.add(Uint8List.fromList(data));
        }
      },
    );
    final stream = inner.transform(transformer);
    final sink = inner as Sink<Uint8List>;

    return WebSocket._(stream, sink);
  }

  @override
  Future<void> close() async {
    await (sink as io.WebSocket).close();
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
  Pointer<Char> toNativeUtf8(String str) =>
      str.toNativeUtf8(allocator: this).cast<Char>();
}

extension Utf8Pointer on Pointer<Utf8> {
  // Similar to [toDartString] but also deallocates the original pointer.
  String intoDartString() {
    final string = toDartString();
    freeString(this);
    return string;
  }
}

// Free a pointer that was allocated by the native side.
void freeString(Pointer<Utf8> ptr) {
  bindings.free_string(ptr.cast<Char>());
}
