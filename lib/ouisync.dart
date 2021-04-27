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

class OuiSync {
  static void setupCallbacks() {
    nRegisterPostCObject(NativeApi.postCObject);
    print('Callbacks setup ok');
  }

  static void initializeRepository(String repositoryName) async {
    nInitializeOuisyncRepository.call(repositoryName.toNativeUtf8());
    print('Repository $repositoryName initialized');
  } 

  static Future<dynamic> newFolder(String repositoryPath, String newFolderPath) async {
    print('Create new folder $newFolderPath in repository $repositoryPath');
    return singleResponseFuture((port) => nCreateDirAsync.call(port.nativePort, repositoryPath.toNativeUtf8(), newFolderPath.toNativeUtf8()));
  }

  static Future<dynamic> getObjectAttributes(String repositoryPath, List<String> objectsPathList) {
    final Pointer<Pointer<Utf8>> pointerPathList = calloc(objectsPathList.length);
    final List<Pointer<Utf8>> utf8PathList = objectsPathList.map((e) => e.toNativeUtf8()).toList();

    for (var i = 0; i < objectsPathList.length; i++) {
      pointerPathList[i] = utf8PathList[i];
    }

    print('Get object attributes (${objectsPathList.length} objects)');
    return singleResponseFuture((port) => nGetAttributesAsync.call(port.nativePort, repositoryPath.toNativeUtf8(), pointerPathList, objectsPathList.length));
  }

  static Future<List<dynamic>> readFolder(String repositoryPath, String folderPath) async {
    return singleResponseFuture((port) => nReadDirAsync(port.nativePort, repositoryPath.toNativeUtf8(), folderPath.toNativeUtf8()));
  }
}
