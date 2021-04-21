import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeOuiSyncLib = Platform.isAndroid
  ? DynamicLibrary.open('libnative_ouisync.so')
  : DynamicLibrary.process();

final int Function(int x, int y) nativeTest =
  nativeOuiSyncLib
    .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('native_test')
    .asFunction();

final nRegisterPostCObject = nativeOuiSyncLib.lookupFunction<
  Void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      functionPointer),
  void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      functionPointer)>('RegisterDart_PostCObject');

class NativeCallback {
  static void setupNativeCallbacks() {
    nRegisterPostCObject(NativeApi.postCObject);
    print('Native callbacks setup ok');
  }
}
