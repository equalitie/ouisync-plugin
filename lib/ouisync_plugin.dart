import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:isolate/ports.dart';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeOuiSyncLib = Platform.isAndroid
  ? DynamicLibrary.open('libnative_ouisync.so')
  : DynamicLibrary.process();

final nRegisterPostCObject = nativeOuiSyncLib.lookupFunction<
  Void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      functionPointer),
  void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      functionPointer)>('RegisterDart_PostCObject');

final nInitializeOuisyncRepository = nativeOuiSyncLib.lookupFunction<
  Void Function(
    Pointer<Utf8>
  ),
  void Function(
    Pointer<Utf8>
  )
>('initializeOuisyncRepository');

class NativeCallback {
  static void setupNativeCallbacks() {
    nRegisterPostCObject(NativeApi.postCObject);
    print('Native callbacks setup ok');
  }
}
