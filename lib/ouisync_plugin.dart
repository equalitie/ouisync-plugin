import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeOuiSyncLib = Platform.isAndroid
  ? DynamicLibrary.open('libnative_ouisync.so')
  : DynamicLibrary.process();

final int Function(int x, int y) nativeTest =
  nativeOuiSyncLib
    .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('native_test')
    .asFunction();


