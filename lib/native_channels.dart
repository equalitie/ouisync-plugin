import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';

import 'ouisync_plugin.dart' show Session, Repository, File;

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
        final s = session;
        session = null;

        if (s != null) {
          s.closeSync();
        }

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
  static Future<void> shareOuiSyncFile(
      String authority, String path, int size) async {
    final dynamic result = await _channel.invokeMethod(
        'shareFile', {"authority": authority, "path": path, "size": size});
    print('shareFile result: $result');
  }

  /// Invokes the native method (In Android, it creates an intent using the custom PipeProvider).
  ///
  /// [path] is the location of the file to preview, including its full name (<path>/<file-name.ext>).
  /// [size] is the lenght of the file (bytes).
  static Future<void> previewOuiSyncFile(
      String authority, String path, int size,
      {bool useDefaultApp = false}) async {
    var args = {"authority": authority, "path": path, "size": size};

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
