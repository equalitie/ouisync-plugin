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

final nReadDirAsync = nativeOuiSyncLib.lookupFunction<
  Void Function(
    Int64, 
    Pointer<Utf8>,
    Pointer<Utf8>
  ),
  void Function(
    int, 
    Pointer<Utf8>,
    Pointer<Utf8>
  )
>('readDir');

final nGetAttributesAsync = nativeOuiSyncLib.lookupFunction<
  Void Function(
    Int64,
    Pointer<Utf8>,
    Pointer<Pointer<Utf8>>,
    Int32
  ),
  void Function(
    int,
    Pointer<Utf8>,
    Pointer<Pointer<Utf8>>,
    int
  )
>('getAttributes');

final nCreateDirAsync = nativeOuiSyncLib.lookupFunction<
  Int32 Function(
    Int64,
    Pointer<Utf8>,
    Pointer<Utf8>
  ),
  int Function(
    int,
    Pointer<Utf8>,
    Pointer<Utf8>
  )
>('createDir');

class NativeCallback {
  static void setupNativeCallbacks() {
    nRegisterPostCObject(NativeApi.postCObject);
    print('Native callbacks setup ok');
  }

  static void initializeOuisyncRepository(String repoDir) async {
    nInitializeOuisyncRepository.call(repoDir.toNativeUtf8());
  } 

  static Future<dynamic> createDirAsync(String repoPath, String newFolderPath) async {
    return singleResponseFuture((port) => nCreateDirAsync.call(port.nativePort, repoPath.toNativeUtf8(), newFolderPath.toNativeUtf8()));
  }

  static Future<dynamic> getAttributesAsync(String repoPath, List<String> pathList) {
    final Pointer<Pointer<Utf8>> pointerPathList = calloc(pathList.length);
    final List<Pointer<Utf8>> utf8PathList = pathList.map((e) => e.toNativeUtf8()).toList();

    for (var i = 0; i < pathList.length; i++) {
      pointerPathList[i] = utf8PathList[i];
    }

    return singleResponseFuture((port) => nGetAttributesAsync.call(port.nativePort, repoPath.toNativeUtf8(), pointerPathList, pathList.length));
  }

  static Future<List<dynamic>> readDirAsync(String repoPath, String folderPath) async {
    return singleResponseFuture((port) => nReadDirAsync(port.nativePort, repoPath.toNativeUtf8(), folderPath.toNativeUtf8()));
  }
}
