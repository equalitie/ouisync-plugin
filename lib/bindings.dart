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
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _directory_create(
      repo,
      path,
      port,
      error,
    );
  }

  late final _directory_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('directory_create');
  late final _directory_create = _directory_createPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  void directory_open(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _directory_open(
      repo,
      path,
      port,
      error,
    );
  }

  late final _directory_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Repository,
              ffi.Pointer<ffi.Int8>,
              Port_UniqueHandle_Directory,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('directory_open');
  late final _directory_open = _directory_openPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Removes the directory at the given path from the repository. The directory must be empty.
  void directory_remove(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _directory_remove(
      repo,
      path,
      port,
      error,
    );
  }

  late final _directory_removePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('directory_remove');
  late final _directory_remove = _directory_removePtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Removes the directory at the given path including its content from the repository.
  void directory_remove_recursively(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _directory_remove_recursively(
      repo,
      path,
      port,
      error,
    );
  }

  late final _directory_remove_recursivelyPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
                  Port, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>(
      'directory_remove_recursively');
  late final _directory_remove_recursively =
      _directory_remove_recursivelyPtr.asFunction<
          void Function(int, ffi.Pointer<ffi.Int8>, int,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

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
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_open(
      repo,
      path,
      port,
      error,
    );
  }

  late final _file_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Repository,
              ffi.Pointer<ffi.Int8>,
              Port_SharedHandle_Mutex_FfiFile,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_open');
  late final _file_open = _file_openPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  void file_create(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_create(
      repo,
      path,
      port,
      error,
    );
  }

  late final _file_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Repository,
              ffi.Pointer<ffi.Int8>,
              Port_SharedHandle_Mutex_FfiFile,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_create');
  late final _file_create = _file_createPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Remove (delete) the file at the given path from the repository.
  void file_remove(
    int repo,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_remove(
      repo,
      path,
      port,
      error,
    );
  }

  late final _file_removePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Repository, ffi.Pointer<ffi.Int8>,
              Port, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_remove');
  late final _file_remove = _file_removePtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  void file_close(
    int handle,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_close(
      handle,
      port,
      error,
    );
  }

  late final _file_closePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_close');
  late final _file_close = _file_closePtr.asFunction<
      void Function(int, int, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  void file_flush(
    int handle,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_flush(
      handle,
      port,
      error,
    );
  }

  late final _file_flushPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_flush');
  late final _file_flush = _file_flushPtr.asFunction<
      void Function(int, int, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Read at most `len` bytes from the file into `buffer`. Yields the number of bytes actually read
  /// (zero on EOF).
  void file_read(
    int handle,
    int offset,
    ffi.Pointer<ffi.Uint8> buffer,
    int len,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_read(
      handle,
      offset,
      buffer,
      len,
      port,
      error,
    );
  }

  late final _file_readPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile,
              ffi.Uint64,
              ffi.Pointer<ffi.Uint8>,
              ffi.Uint64,
              Port_u64,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_read');
  late final _file_read = _file_readPtr.asFunction<
      void Function(int, int, ffi.Pointer<ffi.Uint8>, int, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Write `len` bytes from `buffer` into the file.
  void file_write(
    int handle,
    int offset,
    ffi.Pointer<ffi.Uint8> buffer,
    int len,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_write(
      handle,
      offset,
      buffer,
      len,
      port,
      error,
    );
  }

  late final _file_writePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_Mutex_FfiFile,
              ffi.Uint64,
              ffi.Pointer<ffi.Uint8>,
              ffi.Uint64,
              Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_write');
  late final _file_write = _file_writePtr.asFunction<
      void Function(int, int, ffi.Pointer<ffi.Uint8>, int, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Truncate the file to `len` bytes.
  void file_truncate(
    int handle,
    int len,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_truncate(
      handle,
      len,
      port,
      error,
    );
  }

  late final _file_truncatePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, ffi.Uint64, Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_truncate');
  late final _file_truncate = _file_truncatePtr.asFunction<
      void Function(int, int, int, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Retrieve the size of the file in bytes.
  void file_len(
    int handle,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _file_len(
      handle,
      port,
      error,
    );
  }

  late final _file_lenPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_Mutex_FfiFile, Port_u64,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('file_len');
  late final _file_len = _file_lenPtr.asFunction<
      void Function(int, int, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Creates a new repository.
  void repository_create(
    ffi.Pointer<ffi.Int8> store,
    ffi.Pointer<ffi.Int8> master_password,
    ffi.Pointer<ffi.Int8> share_token,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _repository_create(
      store,
      master_password,
      share_token,
      port,
      error,
    );
  }

  late final _repository_createPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              Port_SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('repository_create');
  late final _repository_create = _repository_createPtr.asFunction<
      void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>,
          ffi.Pointer<ffi.Int8>, int, ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Opens an existing repository.
  void repository_open(
    ffi.Pointer<ffi.Int8> store,
    ffi.Pointer<ffi.Int8> master_password,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _repository_open(
      store,
      master_password,
      port,
      error,
    );
  }

  late final _repository_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              Port_SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('repository_open');
  late final _repository_open = _repository_openPtr.asFunction<
      void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Closes a repository.
  void repository_close(
    int handle,
  ) {
    return _repository_close(
      handle,
    );
  }

  late final _repository_closePtr = _lookup<
          ffi.NativeFunction<ffi.Void Function(SharedHandle_RepositoryHolder)>>(
      'repository_close');
  late final _repository_close =
      _repository_closePtr.asFunction<void Function(int)>();

  /// Returns the type of repository entry (file, directory, ...).
  /// If the entry doesn't exists, returns `ENTRY_TYPE_INVALID`, not an error.
  void repository_entry_type(
    int handle,
    ffi.Pointer<ffi.Int8> path,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _repository_entry_type(
      handle,
      path,
      port,
      error,
    );
  }

  late final _repository_entry_typePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Int8>,
              Port_u8,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('repository_entry_type');
  late final _repository_entry_type = _repository_entry_typePtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Move/rename entry from src to dst.
  void repository_move_entry(
    int handle,
    ffi.Pointer<ffi.Int8> src,
    ffi.Pointer<ffi.Int8> dst,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _repository_move_entry(
      handle,
      src,
      dst,
      port,
      error,
    );
  }

  late final _repository_move_entryPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder,
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Int8>,
              Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('repository_move_entry');
  late final _repository_move_entry = _repository_move_entryPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

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

  /// Cancel the repository change notifications subscription.
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

  void repository_is_dht_enabled(
    int handle,
    int port,
  ) {
    return _repository_is_dht_enabled(
      handle,
      port,
    );
  }

  late final _repository_is_dht_enabledPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SharedHandle_RepositoryHolder,
              Port_bool)>>('repository_is_dht_enabled');
  late final _repository_is_dht_enabled =
      _repository_is_dht_enabledPtr.asFunction<void Function(int, int)>();

  void repository_enable_dht(
    int handle,
    int port,
  ) {
    return _repository_enable_dht(
      handle,
      port,
    );
  }

  late final _repository_enable_dhtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder, Port)>>('repository_enable_dht');
  late final _repository_enable_dht =
      _repository_enable_dhtPtr.asFunction<void Function(int, int)>();

  void repository_disable_dht(
    int handle,
    int port,
  ) {
    return _repository_disable_dht(
      handle,
      port,
    );
  }

  late final _repository_disable_dhtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              SharedHandle_RepositoryHolder, Port)>>('repository_disable_dht');
  late final _repository_disable_dht =
      _repository_disable_dhtPtr.asFunction<void Function(int, int)>();

  void repository_create_share_token(
    int handle,
    int access_mode,
    ffi.Pointer<ffi.Int8> name,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error,
  ) {
    return _repository_create_share_token(
      handle,
      access_mode,
      name,
      port,
      error,
    );
  }

  late final _repository_create_share_tokenPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  SharedHandle_RepositoryHolder,
                  ffi.Uint8,
                  ffi.Pointer<ffi.Int8>,
                  Port_String,
                  ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>(
      'repository_create_share_token');
  late final _repository_create_share_token =
      _repository_create_share_tokenPtr.asFunction<
          void Function(int, int, ffi.Pointer<ffi.Int8>, int,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

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

  /// IMPORTANT: the caller is responsible for deallocating `out_bytes` unless it is `null`.
  void share_token_encode(
    ffi.Pointer<ffi.Int8> token,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>> out_bytes,
    ffi.Pointer<ffi.Uint64> out_len,
  ) {
    return _share_token_encode(
      token,
      out_bytes,
      out_len,
    );
  }

  late final _share_token_encodePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<ffi.Int8>,
              ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
              ffi.Pointer<ffi.Uint64>)>>('share_token_encode');
  late final _share_token_encode = _share_token_encodePtr.asFunction<
      void Function(ffi.Pointer<ffi.Int8>, ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.Uint64>)>();

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
    ffi.Pointer<ffi.Int8> store,
    int port,
    ffi.Pointer<ffi.Pointer<ffi.Int8>> error_ptr,
  ) {
    return _session_open(
      post_c_object_fn,
      store,
      port,
      error_ptr,
    );
  }

  late final _session_openPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Int8>, Port,
              ffi.Pointer<ffi.Pointer<ffi.Int8>>)>>('session_open');
  late final _session_open = _session_openPtr.asFunction<
      void Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Int8>, int,
          ffi.Pointer<ffi.Pointer<ffi.Int8>>)>();

  /// Closes the ouisync session.
  void session_close() {
    return _session_close();
  }

  late final _session_closePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('session_close');
  late final _session_close = _session_closePtr.asFunction<void Function()>();
}

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_Repository = ffi.Uint64;
typedef Port = ffi.Int64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_UniqueHandle_Directory = Port;

/// FFI handle to a resource with unique ownership.
typedef UniqueHandle_Directory = ffi.Uint64;

/// FFI handle to a borrowed resource.
typedef RefHandle_DirEntry = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_SharedHandle_Mutex_FfiFile = Port;

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_Mutex_FfiFile = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_u64 = Port;

/// Type-safe wrapper over native dart SendPort.
typedef Port_SharedHandle_RepositoryHolder = Port;

/// FFI handle to a resource with shared ownership.
typedef SharedHandle_RepositoryHolder = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_u8 = Port;

/// FFI handle to a resource with unique ownership.
typedef UniqueHandle_JoinHandle = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_bool = Port;

/// Type-safe wrapper over native dart SendPort.
typedef Port_String = Port;

const int ENTRY_TYPE_INVALID = 0;

const int ENTRY_TYPE_FILE = 1;

const int ENTRY_TYPE_DIRECTORY = 2;

const int ACCESS_MODE_BLIND = 0;

const int ACCESS_MODE_READ = 1;

const int ACCESS_MODE_WRITE = 2;
