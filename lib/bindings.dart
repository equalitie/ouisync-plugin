// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
import 'dart:ffi' as ffi;

/// Bindings to the ouisync library
class Bindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  Bindings(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  Bindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void directory_create(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _directory_create(
      repo,
      path,
      port,
    );
  }

  late final _directory_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result)>>('directory_create');
  late final _directory_create = _directory_createPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  void directory_open(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _directory_open(
      repo,
      path,
      port,
    );
  }

  late final _directory_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result_UniqueHandle_Directory)>>('directory_open');
  late final _directory_open = _directory_openPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  /// Removes the directory at the given path from the repository. The directory must be empty.
  void directory_remove(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _directory_remove(
      repo,
      path,
      port,
    );
  }

  late final _directory_removePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result)>>('directory_remove');
  late final _directory_remove = _directory_removePtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  /// Removes the directory at the given path including its content from the repository.
  void directory_remove_recursively(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _directory_remove_recursively(
      repo,
      path,
      port,
    );
  }

  late final _directory_remove_recursivelyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result)>>('directory_remove_recursively');
  late final _directory_remove_recursively = _directory_remove_recursivelyPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  void directory_close(
    int handle,
  ) {
    return _directory_close(
      handle,
    );
  }

  late final _directory_closePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(UniqueHandle_Directory)>>(
          'directory_close');
  late final _directory_close =
      _directory_closePtr.asFunction<void Function(int)>();

  int directory_num_entries(
    int handle,
  ) {
    return _directory_num_entries(
      handle,
    );
  }

  late final _directory_num_entriesPtr =
      _lookup<ffi.NativeFunction<ffi.Uint64 Function(UniqueHandle_Directory)>>(
          'directory_num_entries');
  late final _directory_num_entries =
      _directory_num_entriesPtr.asFunction<int Function(int)>();

  int directory_get_entry(
    int handle,
    int index,
  ) {
    return _directory_get_entry(
      handle,
      index,
    );
  }

  late final _directory_get_entryPtr = _lookup<
      ffi.NativeFunction<
          RefHandle_DirEntry Function(
              UniqueHandle_Directory, ffi.Uint64)>>('directory_get_entry');
  late final _directory_get_entry =
      _directory_get_entryPtr.asFunction<int Function(int, int)>();

  ffi.Pointer<ffi.Int8> dir_entry_name(
    int handle,
  ) {
    return _dir_entry_name(
      handle,
    );
  }

  late final _dir_entry_namePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Int8> Function(
              RefHandle_DirEntry)>>('dir_entry_name');
  late final _dir_entry_name =
      _dir_entry_namePtr.asFunction<ffi.Pointer<ffi.Int8> Function(int)>();

  int dir_entry_type(
    int handle,
  ) {
    return _dir_entry_type(
      handle,
    );
  }

  late final _dir_entry_typePtr =
      _lookup<ffi.NativeFunction<ffi.Uint8 Function(RefHandle_DirEntry)>>(
          'dir_entry_type');
  late final _dir_entry_type =
      _dir_entry_typePtr.asFunction<int Function(int)>();

  void file_open(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _file_open(
      repo,
      path,
      port,
    );
  }

  late final _file_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result_SharedHandle_Mutex_FfiFile)>>('file_open');
  late final _file_open = _file_openPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  void file_create(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _file_create(
      repo,
      path,
      port,
    );
  }

  late final _file_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result_SharedHandle_Mutex_FfiFile)>>('file_create');
  late final _file_create = _file_createPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  /// Remove (delete) the file at the given path from the repository.
  void file_remove(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _file_remove(
      repo,
      path,
      port,
    );
  }

  late final _file_removePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port_Result)>>('file_remove');
  late final _file_remove = _file_removePtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  void file_close(
    int handle,
    int port,
  ) {
    return _file_close(
      handle,
      port,
    );
  }

  late final _file_closePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile, Port_Result)>>('file_close');
  late final _file_close = _file_closePtr.asFunction<void Function(int, int)>();

  void file_flush(
    int handle,
    int port,
  ) {
    return _file_flush(
      handle,
      port,
    );
  }

  late final _file_flushPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile, Port_Result)>>('file_flush');
  late final _file_flush = _file_flushPtr.asFunction<void Function(int, int)>();

  /// Read at most `len` bytes from the file into `buffer`. Yields the number of bytes actually read
  /// (zero on EOF).
  void file_read(
    int handle,
    int offset,
    ffi.Pointer<ffi.Uint8> buffer,
    int len,
    int port,
  ) {
    return _file_read(
      handle,
      offset,
      buffer,
      len,
      port,
    );
  }

  late final _file_readPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile,
              ffi.Uint64,
              ffi.Pointer<ffi.Uint8>,
              ffi.Uint64,
              Port_Result_u64)>>('file_read');
  late final _file_read = _file_readPtr
      .asFunction<void Function(int, int, ffi.Pointer<ffi.Uint8>, int, int)>();

  /// Write `len` bytes from `buffer` into the file.
  void file_write(
    int handle,
    int offset,
    ffi.Pointer<ffi.Uint8> buffer,
    int len,
    int port,
  ) {
    return _file_write(
      handle,
      offset,
      buffer,
      len,
      port,
    );
  }

  late final _file_writePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, ffi.Uint64,
              ffi.Pointer<ffi.Uint8>, ffi.Uint64, Port_Result)>>('file_write');
  late final _file_write = _file_writePtr
      .asFunction<void Function(int, int, ffi.Pointer<ffi.Uint8>, int, int)>();

  /// Truncate the file to `len` bytes.
  void file_truncate(
    int handle,
    int len,
    int port,
  ) {
    return _file_truncate(
      handle,
      len,
      port,
    );
  }

  late final _file_truncatePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, ffi.Uint64,
              Port_Result)>>('file_truncate');
  late final _file_truncate =
      _file_truncatePtr.asFunction<void Function(int, int, int)>();

  /// Retrieve the size of the file in bytes.
  void file_len(
    int handle,
    int port,
  ) {
    return _file_len(
      handle,
      port,
    );
  }

  late final _file_lenPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile, Port_Result_u64)>>('file_len');
  late final _file_len = _file_lenPtr.asFunction<void Function(int, int)>();

  /// Copy the file contents into the provided raw file descriptor.
  /// This function takes ownership of the file descriptor and closes it when it finishes. If the
  /// caller needs to access the descriptor afterwards (or while the function is running), he/she
  /// needs to `dup` it before passing it into this function.
  void file_copy_to_raw_fd(
    int handle,
    int fd,
    int port,
  ) {
    return _file_copy_to_raw_fd(
      handle,
      fd,
      port,
    );
  }

  late final _file_copy_to_raw_fdPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, ffi.Int32,
              Port_Result)>>('file_copy_to_raw_fd');
  late final _file_copy_to_raw_fd =
      _file_copy_to_raw_fdPtr.asFunction<void Function(int, int, int)>();

  /// Subscribe to network event notifications.
  int network_subscribe(
    int port,
  ) {
    return _network_subscribe(
      port,
    );
  }

  late final _network_subscribePtr =
      _lookup<ffi.NativeFunction<UniqueHandle_JoinHandle Function(Port_u8)>>(
          'network_subscribe');
  late final _network_subscribe =
      _network_subscribePtr.asFunction<int Function(int)>();

  /// Return the local network endpoint as string. The format is
  /// "<TCP or UDP>:<IPv4 or [IPv6]>:<PORT>". Examples:
  ///
  /// For IPv4: "TCP:192.168.1.1:65522"
  /// For IPv6: "TCP:[2001:db8::1]:65522"
  ///
  /// IMPORTANT: the caller is responsible for deallocating the returned pointer.
  ffi.Pointer<ffi.Int8> network_listener_local_addr() {
    return _network_listener_local_addr();
  }

  late final _network_listener_local_addrPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Int8> Function()>>(
          'network_listener_local_addr');
  late final _network_listener_local_addr = _network_listener_local_addrPtr
      .asFunction<ffi.Pointer<ffi.Int8> Function()>();

  /// Return the list of peers with which we're connected, serialized with msgpack.
  Bytes network_connected_peers() {
    return _network_connected_peers();
  }

  late final _network_connected_peersPtr =
      _lookup<ffi.NativeFunction<Bytes Function()>>('network_connected_peers');
  late final _network_connected_peers =
      _network_connected_peersPtr.asFunction<Bytes Function()>();

  /// Return our currently used protocol version number.
  int network_current_protocol_version() {
    return _network_current_protocol_version();
  }

  late final _network_current_protocol_versionPtr =
      _lookup<ffi.NativeFunction<ffi.Uint32 Function()>>(
          'network_current_protocol_version');
  late final _network_current_protocol_version =
      _network_current_protocol_versionPtr.asFunction<int Function()>();

  /// Return the highest seen protocol version number. The value returned is always higher
  /// or equal to the value returned from network_current_protocol_version() fn.
  int network_highest_seen_protocol_version() {
    return _network_highest_seen_protocol_version();
  }

  late final _network_highest_seen_protocol_versionPtr =
      _lookup<ffi.NativeFunction<ffi.Uint32 Function()>>(
          'network_highest_seen_protocol_version');
  late final _network_highest_seen_protocol_version =
      _network_highest_seen_protocol_versionPtr.asFunction<int Function()>();

  /// Returns the local dht address for ipv4, if available.
  /// See [`network_local_addr`] for the format details.
  ///
  /// IMPORTANT: the caller is responsible for deallocating the returned pointer unless it is `null`.
  ffi.Pointer<ffi.Int8> network_dht_local_addr_v4() {
    return _network_dht_local_addr_v4();
  }

  late final _network_dht_local_addr_v4Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Int8> Function()>>(
          'network_dht_local_addr_v4');
  late final _network_dht_local_addr_v4 = _network_dht_local_addr_v4Ptr
      .asFunction<ffi.Pointer<ffi.Int8> Function()>();

  /// Returns the local dht address for ipv6, if available.
  /// See [`network_local_addr`] for the format details.
  ///
  /// IMPORTANT: the caller is responsible for deallocating the returned pointer unless it is `null`.
  ffi.Pointer<ffi.Int8> network_dht_local_addr_v6() {
    return _network_dht_local_addr_v6();
  }

  late final _network_dht_local_addr_v6Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Int8> Function()>>(
          'network_dht_local_addr_v6');
  late final _network_dht_local_addr_v6 = _network_dht_local_addr_v6Ptr
      .asFunction<ffi.Pointer<ffi.Int8> Function()>();

  /// Creates a new repository.
  void repository_create(
    ffi.Pointer<ffi.Int8> store,
    ffi.Pointer<ffi.Int8> master_password,
    ffi.Pointer<ffi.Int8> share_token,
    int port,
  ) {
    return _repository_create(
      store,
      master_password,
      share_token,
      port,
    );
  }

  late final _repository_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              Port_Result_SharedHandle_RepositoryHolder)>>('repository_create');
  late final _repository_create = _repository_createPtr.asFunction<
      void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>,
          ffi.Pointer<ffi.Int8>, int)>();

  /// Opens an existing repository.
  void repository_open(
    ffi.Pointer<ffi.Int8> store,
    ffi.Pointer<ffi.Int8> master_password,
    int port,
  ) {
    return _repository_open(
      store,
      master_password,
      port,
    );
  }

  late final _repository_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>,
              Port_Result_SharedHandle_RepositoryHolder)>>('repository_open');
  late final _repository_open = _repository_openPtr.asFunction<
      void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>, int)>();

  /// Closes a repository.
  void repository_close(
    int handle,
    int port,
  ) {
    return _repository_close(
      handle,
      port,
    );
  }

  late final _repository_closePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder, Port)>>('repository_close');
  late final _repository_close =
      _repository_closePtr.asFunction<void Function(int, int)>();

  /// Returns the type of repository entry (file, directory, ...).
  /// If the entry doesn't exists, returns `ENTRY_TYPE_INVALID`, not an error.
  void repository_entry_type(
    int handle,
    ffi.Pointer<ffi.Int8> path,
    int port,
  ) {
    return _repository_entry_type(
      handle,
      path,
      port,
    );
  }

  late final _repository_entry_typePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Int8>, Port_Result_u8)>>('repository_entry_type');
  late final _repository_entry_type = _repository_entry_typePtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Int8>, int)>();

  /// Move/rename entry from src to dst.
  void repository_move_entry(
    int handle,
    ffi.Pointer<ffi.Int8> src,
    ffi.Pointer<ffi.Int8> dst,
    int port,
  ) {
    return _repository_move_entry(
      handle,
      src,
      dst,
      port,
    );
  }

  late final _repository_move_entryPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              Port_Result)>>('repository_move_entry');
  late final _repository_move_entry = _repository_move_entryPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>, int)>();

  /// Subscribe to change notifications from the repository.
  int repository_subscribe(
    int handle,
    int port,
  ) {
    return _repository_subscribe(
      handle,
      port,
    );
  }

  late final _repository_subscribePtr = _lookup<
      ffi.NativeFunction<
          UniqueHandle_JoinHandle Function(
              SharedHandle_RepositoryHolder, Port)>>('repository_subscribe');
  late final _repository_subscribe =
      _repository_subscribePtr.asFunction<int Function(int, int)>();

  bool repository_is_dht_enabled(
    int handle,
  ) {
    return _repository_is_dht_enabled(
          handle,
        ) !=
        0;
  }

  late final _repository_is_dht_enabledPtr = _lookup<
      ffi.NativeFunction<
          ffi.Uint8 Function(
              SharedHandle_RepositoryHolder)>>('repository_is_dht_enabled');
  late final _repository_is_dht_enabled =
      _repository_is_dht_enabledPtr.asFunction<int Function(int)>();

  void repository_enable_dht(
    int handle,
  ) {
    return _repository_enable_dht(
      handle,
    );
  }

  late final _repository_enable_dhtPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(SharedHandle_RepositoryHolder)>>(
      'repository_enable_dht');
  late final _repository_enable_dht =
      _repository_enable_dhtPtr.asFunction<void Function(int)>();

  void repository_disable_dht(
    int handle,
  ) {
    return _repository_disable_dht(
      handle,
    );
  }

  late final _repository_disable_dhtPtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(SharedHandle_RepositoryHolder)>>(
      'repository_disable_dht');
  late final _repository_disable_dht =
      _repository_disable_dhtPtr.asFunction<void Function(int)>();

  void repository_create_share_token(
    int handle,
    int access_mode,
    ffi.Pointer<ffi.Int8> name,
    int port,
  ) {
    return _repository_create_share_token(
      handle,
      access_mode,
      name,
      port,
    );
  }

  late final _repository_create_share_tokenPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder,
              ffi.Uint8,
              ffi.Pointer<ffi.Int8>,
              Port_Result_String)>>('repository_create_share_token');
  late final _repository_create_share_token = _repository_create_share_tokenPtr
      .asFunction<void Function(int, int, ffi.Pointer<ffi.Int8>, int)>();

  int repository_access_mode(
    int handle,
  ) {
    return _repository_access_mode(
      handle,
    );
  }

  late final _repository_access_modePtr = _lookup<
      ffi.NativeFunction<
          ffi.Uint8 Function(
              SharedHandle_RepositoryHolder)>>('repository_access_mode');
  late final _repository_access_mode =
      _repository_access_modePtr.asFunction<int Function(int)>();

  /// Returns the syncing progress as a float in the 0.0 - 1.0 range.
  void repository_sync_progress(
    int handle,
    int port,
  ) {
    return _repository_sync_progress(
      handle,
      port,
    );
  }

  late final _repository_sync_progressPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_RepositoryHolder,
              Port_Result_Vec_u8)>>('repository_sync_progress');
  late final _repository_sync_progress =
      _repository_sync_progressPtr.asFunction<void Function(int, int)>();

  /// Returns the access mode of the given share token.
  int share_token_mode(
    ffi.Pointer<ffi.Int8> token,
  ) {
    return _share_token_mode(
      token,
    );
  }

  late final _share_token_modePtr =
      _lookup<ffi.NativeFunction<ffi.Uint8 Function(ffi.Pointer<ffi.Int8>)>>(
          'share_token_mode');
  late final _share_token_mode =
      _share_token_modePtr.asFunction<int Function(ffi.Pointer<ffi.Int8>)>();

  /// IMPORTANT: the caller is responsible for deallocating the returned pointer unless it is `null`.
  ffi.Pointer<ffi.Int8> share_token_suggested_name(
    ffi.Pointer<ffi.Int8> token,
  ) {
    return _share_token_suggested_name(
      token,
    );
  }

  late final _share_token_suggested_namePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Int8> Function(
              ffi.Pointer<ffi.Int8>)>>('share_token_suggested_name');
  late final _share_token_suggested_name = _share_token_suggested_namePtr
      .asFunction<ffi.Pointer<ffi.Int8> Function(ffi.Pointer<ffi.Int8>)>();

  /// IMPORTANT: the caller is responsible for deallocating the returned buffer unless it is `null`.
  Bytes share_token_encode(
    ffi.Pointer<ffi.Int8> token,
  ) {
    return _share_token_encode(
      token,
    );
  }

  late final _share_token_encodePtr =
      _lookup<ffi.NativeFunction<Bytes Function(ffi.Pointer<ffi.Int8>)>>(
          'share_token_encode');
  late final _share_token_encode = _share_token_encodePtr
      .asFunction<Bytes Function(ffi.Pointer<ffi.Int8>)>();

  /// IMPORTANT: the caller is responsible for deallocating the returned pointer unless it is `null`.
  ffi.Pointer<ffi.Int8> share_token_decode(
    ffi.Pointer<ffi.Uint8> bytes,
    int len,
  ) {
    return _share_token_decode(
      bytes,
      len,
    );
  }

  late final _share_token_decodePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Int8> Function(
              ffi.Pointer<ffi.Uint8>, ffi.Uint64)>>('share_token_decode');
  late final _share_token_decode = _share_token_decodePtr.asFunction<
      ffi.Pointer<ffi.Int8> Function(ffi.Pointer<ffi.Uint8>, int)>();

  /// Opens the ouisync session. `post_c_object_fn` should be a pointer to the dart's
  /// `NativeApi.postCObject` function cast to `Pointer<Void>` (the casting is necessary to work
  /// around limitations of the binding generators).
  void session_open(
    ffi.Pointer<ffi.Void> post_c_object_fn,
    ffi.Pointer<ffi.Int8> configs_path,
    int port,
  ) {
    return _session_open(
      post_c_object_fn,
      configs_path,
      port,
    );
  }

  late final _session_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Int8>,
              Port_Result)>>('session_open');
  late final _session_open = _session_openPtr.asFunction<
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Int8>, int)>();

  /// Retrieve a serialized state monitor corresponding to the `path`.  The path is in the form
  /// "a:b:c". An empty string returns the "root" state monitor.
  Bytes session_get_state_monitor(
    ffi.Pointer<ffi.Int8> path,
  ) {
    return _session_get_state_monitor(
      path,
    );
  }

  late final _session_get_state_monitorPtr =
      _lookup<ffi.NativeFunction<Bytes Function(ffi.Pointer<ffi.Int8>)>>(
          'session_get_state_monitor');
  late final _session_get_state_monitor = _session_get_state_monitorPtr
      .asFunction<Bytes Function(ffi.Pointer<ffi.Int8>)>();

  /// Closes the ouisync session.
  void session_close() {
    return _session_close();
  }

  late final _session_closePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('session_close');
  late final _session_close = _session_closePtr.asFunction<void Function()>();

  /// Cancel a notification subscription.
  void subscription_cancel(
    int handle,
  ) {
    return _subscription_cancel(
      handle,
    );
  }

  late final _subscription_cancelPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(UniqueHandle_JoinHandle)>>(
          'subscription_cancel');
  late final _subscription_cancel =
      _subscription_cancelPtr.asFunction<void Function(int)>();
}

abstract class ErrorCode {
  /// No error
  static const int ok = 0;

  /// Database error
  static const int db = 1;

  /// Insuficient permission to perform the intended operation
  static const int permissionDenied = 2;

  /// Malformed data
  static const int malformedData = 3;

  /// Entry already exists
  static const int entryExists = 4;

  /// Entry doesn't exist
  static const int entryNotFound = 5;

  /// Multiple matching entries found
  static const int ambiguousEntry = 6;

  /// The intended operation requires the directory to be empty but it isn't
  static const int directoryNotEmpty = 7;

  /// The indended operation is not supported
  static const int operationNotSupported = 8;

  /// Network error
  static const int network = 9;

  /// Failed to read from or write into the device ID config file
  static const int deviceIdConfig = 10;

  /// Unspecified error
  static const int other = 65536;
}

class Bytes extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Uint64()
  external int len;
}

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_Repository = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result = Port;
typedef Port = ffi.Int64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_UniqueHandle_Directory = Port;

/// FFI handle to a resource with unique ownership.
typedef UniqueHandle_Directory = ffi.Uint64;

/// FFI handle to a borrowed resource.
typedef RefHandle_DirEntry = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_SharedHandle_Mutex_FfiFile = Port;

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_Mutex_FfiFile = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_u64 = Port;

/// FFI handle to a resource with unique ownership.
typedef UniqueHandle_JoinHandle = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_u8 = Port;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_SharedHandle_RepositoryHolder = Port;

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_RepositoryHolder = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_u8 = Port;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_String = Port;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_Vec_u8 = Port;

const int NETWORK_EVENT_PROTOCOL_VERSION_MISMATCH = 0;

const int NETWORK_EVENT_PEER_SET_CHANGE = 1;

const int ENTRY_TYPE_INVALID = 0;

const int ENTRY_TYPE_FILE = 1;

const int ENTRY_TYPE_DIRECTORY = 2;

const int ACCESS_MODE_BLIND = 0;

const int ACCESS_MODE_READ = 1;

const int ACCESS_MODE_WRITE = 2;
