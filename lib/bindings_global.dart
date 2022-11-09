import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'bindings.dart';
export 'bindings.dart';

final bindings = Bindings(_defaultLib());

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
