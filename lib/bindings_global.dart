import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'bindings.dart';
export 'bindings.dart';

import 'package:path/path.dart' as p;

final bindings = Bindings(_defaultLib());

DynamicLibrary _defaultLib() {
  final env = Platform.environment;

  if (env.containsKey('OUISYNC_LIB')) {
    return DynamicLibrary.open(env['OUISYNC_LIB']!);
  }

  final name = 'ouisync_ffi';

  if (env.containsKey('FLUTTER_TEST')) {
    late final String path;

    final root = env['APP_NAME'] == 'ouisync_plugin' ? '..' : '';

    final basePath = 'ouisync/target';
    final basePathWindows = 'build/windows/plugins/ouisync_plugin';

    if (kReleaseMode) {
      path = Platform.isWindows
          ? p.join(root, basePathWindows, 'Release')
          : p.join(basePath, 'release');
    } else {
      path = Platform.isWindows
          ? p.join(root, basePathWindows, 'Debug')
          : p.join(basePath, 'debug');
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
