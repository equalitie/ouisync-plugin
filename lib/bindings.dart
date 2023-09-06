// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
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

  /// Creates a ouisync session. `post_c_object_fn` should be a pointer to the dart's
  /// `NativeApi.postCObject` function cast to `Pointer<Void>` (the casting is necessary to work
  /// around limitations of the binding generators).
  ///
  /// # Safety
  ///
  /// - `post_c_object_fn` must be a pointer to the dart's `NativeApi.postCObject` function
  /// - `configs_path` must be a pointer to a nul-terminated utf-8 encoded string
  SessionCreateResult session_create(
    ffi.Pointer<ffi.Void> post_c_object_fn,
    ffi.Pointer<ffi.Char> configs_path,
    ffi.Pointer<ffi.Char> log_path,
    int server_tx_port,
  ) {
    return _session_create(
      post_c_object_fn,
      configs_path,
      log_path,
      server_tx_port,
    );
  }

  late final _session_createPtr = _lookup<
      ffi.NativeFunction<
          SessionCreateResult Function(
              ffi.Pointer<ffi.Void>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>,
              Port_Bytes)>>('session_create');
  late final _session_create = _session_createPtr.asFunction<
      SessionCreateResult Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>, int)>();

  /// Destroys the ouisync session.
  ///
  /// # Safety
  ///
  /// `session` must be a valid session handle.
  void session_destroy(
    int session,
  ) {
    return _session_destroy(
      session,
    );
  }

  late final _session_destroyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(SessionHandle)>>(
          'session_destroy');
  late final _session_destroy =
      _session_destroyPtr.asFunction<void Function(int)>();

  /// # Safety
  ///
  /// `session` must be a valid session handle, `sender` must be a valid client sender handle,
  /// `payload_ptr` must be a pointer to a byte buffer whose length is at least `payload_len` bytes.
  void session_channel_send(
    int session,
    ffi.Pointer<ffi.Uint8> payload_ptr,
    int payload_len,
  ) {
    return _session_channel_send(
      session,
      payload_ptr,
      payload_len,
    );
  }

  late final _session_channel_sendPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SessionHandle, ffi.Pointer<ffi.Uint8>,
              ffi.Uint64)>>('session_channel_send');
  late final _session_channel_send = _session_channel_sendPtr
      .asFunction<void Function(int, ffi.Pointer<ffi.Uint8>, int)>();

  /// Shutdowns the network and closes the session. This is equivalent to doing it in two steps
  /// (`network_shutdown` then `session_close`), but in flutter when the engine is being detached
  /// from Android runtime then async wait for `network_shutdown` never completes (or does so
  /// randomly), and thus `session_close` is never invoked. My guess is that because the dart engine
  /// is being detached we can't do any async await on the dart side anymore, and thus need to do it
  /// here.
  ///
  /// # Safety
  ///
  /// `session` must be a valid session handle.
  void session_shutdown_network_and_close(
    int session,
  ) {
    return _session_shutdown_network_and_close(
      session,
    );
  }

  late final _session_shutdown_network_and_closePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(SessionHandle)>>(
          'session_shutdown_network_and_close');
  late final _session_shutdown_network_and_close =
      _session_shutdown_network_and_closePtr.asFunction<void Function(int)>();

  /// Copy the file contents into the provided raw file descriptor.
  ///
  /// This function takes ownership of the file descriptor and closes it when it finishes. If the
  /// caller needs to access the descriptor afterwards (or while the function is running), he/she
  /// needs to `dup` it before passing it into this function.
  ///
  /// # Safety
  ///
  /// `session` must be a valid session handle, `handle` must be a valid file holder handle, `fd`
  /// must be a valid and open file descriptor and `port` must be a valid dart native port.
  void file_copy_to_raw_fd(
    int session,
    int handle,
    int fd,
    int port,
  ) {
    return _file_copy_to_raw_fd(
      session,
      handle,
      fd,
      port,
    );
  }

  late final _file_copy_to_raw_fdPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(SessionHandle, Handle_FileHolder, ffi.Int,
              Port_Result_Error)>>('file_copy_to_raw_fd');
  late final _file_copy_to_raw_fd =
      _file_copy_to_raw_fdPtr.asFunction<void Function(int, int, int, int)>();

  /// Deallocate string that has been allocated on the rust side
  ///
  /// # Safety
  ///
  /// `ptr` must be a pointer obtained from a call to `CString::into_raw`.
  void free_string(
    ffi.Pointer<ffi.Char> ptr,
  ) {
    return _free_string(
      ptr,
    );
  }

  late final _free_stringPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Char>)>>(
          'free_string');
  late final _free_string =
      _free_stringPtr.asFunction<void Function(ffi.Pointer<ffi.Char>)>();

  /// Print log message
  ///
  /// # Safety
  ///
  /// `message_ptr` must be a pointer to a nul-terminated utf-8 encoded string
  void log_print(
    int level,
    ffi.Pointer<ffi.Char> scope_ptr,
    ffi.Pointer<ffi.Char> message_ptr,
  ) {
    return _log_print(
      level,
      scope_ptr,
      message_ptr,
    );
  }

  late final _log_printPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Uint8, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>>('log_print');
  late final _log_print = _log_printPtr.asFunction<
      void Function(int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();
}

abstract class ErrorCode {
  /// No error
  static const int ok = 0;

  /// Store error
  static const int store = 1;

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

  /// Failed to read from or write into the config file
  static const int config = 10;

  /// Argument passed to a function is not valid
  static const int invalidArgument = 11;

  /// Request or response is malformed
  static const int malformedMessage = 12;

  /// Storage format version mismatch
  static const int storageVersionMismatch = 13;

  /// Connection lost
  static const int connectionLost = 14;
  static const int vfsInvalidMountPoint = 2048;
  static const int vfsDriverInstall = 2049;
  static const int vfsBackend = 2050;

  /// Unspecified error
  static const int other = 65535;
}

class SessionCreateResult extends ffi.Struct {
  @SessionHandle()
  external int session;

  @ErrorCode1()
  external int error_code;

  external ffi.Pointer<ffi.Char> error_message;
}

typedef SessionHandle = UniqueHandle_Session;

/// FFI handle to a resource with unique ownership.
typedef UniqueHandle_Session = ffi.Uint64;
typedef ErrorCode1 = ffi.Uint16;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Bytes = RawPort;
typedef RawPort = ffi.Int64;
typedef Handle_FileHolder = ffi.Uint64;

/// Type-safe wrapper over native dart SendPort.
typedef Port_Result_Error = RawPort;

const int LOG_LEVEL_ERROR = 1;

const int LOG_LEVEL_WARN = 2;

const int LOG_LEVEL_INFO = 3;

const int LOG_LEVEL_DEBUG = 4;

const int LOG_LEVEL_TRACE = 5;

const int ENTRY_TYPE_FILE = 1;

const int ENTRY_TYPE_DIRECTORY = 2;

const int ACCESS_MODE_BLIND = 0;

const int ACCESS_MODE_READ = 1;

const int ACCESS_MODE_WRITE = 2;

const int NETWORK_EVENT_PROTOCOL_VERSION_MISMATCH = 0;

const int NETWORK_EVENT_PEER_SET_CHANGE = 1;
