import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:isolate/ports.dart';

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

final nCreateFileAsync = nativeOuiSyncLib.lookupFunction<
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
>('createFile');

final nWriteFileAsync = nativeOuiSyncLib.lookupFunction<
  Int32 Function(
    Int64,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    Uint64,
    Uint64
  ),
  int Function(
    int,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    int
  )
>('writeFile');

final nReadFileAsync = nativeOuiSyncLib.lookupFunction<
  Int32 Function(
    Int64,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    Uint64,
    Uint64
  ),
  int Function(
    int,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    int,
    int
  )
>('readFile');

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
    return singleResponseFuture((port) =>
    nCreateDirAsync.call(
      port.nativePort,
      repositoryPath.toNativeUtf8(),
      newFolderPath.toNativeUtf8()
    ));
  }

  static Future<dynamic> getObjectAttributes(String repositoryPath, List<String> objectsPathList) {
    final Pointer<Pointer<Utf8>> pathListPtr = calloc(objectsPathList.length);
    final List<Pointer<Utf8>> utf8PathList = objectsPathList.map((e) => e.toNativeUtf8()).toList();

    for (var i = 0; i < objectsPathList.length; i++) {
      pathListPtr[i] = utf8PathList[i];
    }

    print('Get object attributes (${objectsPathList.length} objects)');
    return singleResponseFuture((port) => 
    nGetAttributesAsync.call(
      port.nativePort,
      repositoryPath.toNativeUtf8(),
      pathListPtr,
      objectsPathList.length
    ));
  }

  static Future<List<dynamic>> readFolder(String repositoryPath, String folderPath) async {
    return singleResponseFuture((port) => 
    nReadDirAsync(
      port.nativePort,
      repositoryPath.toNativeUtf8(),
      folderPath.toNativeUtf8()
    ));
  }

  static Future<dynamic> newFile(String repositoryPath, String newFilePath) async {
    print('Create new file $newFilePath in repository $repositoryPath');
    return singleResponseFuture((port) =>
    nCreateFileAsync.call(
      port.nativePort,
      repositoryPath.toNativeUtf8(),
      newFilePath.toNativeUtf8()
    ));
  }

  static Future<dynamic> writeFile(String repositoryPath, String filePath, List<int> buffer, int offset) {
    final bufferPtr = calloc<Uint8>(buffer.length);
    bufferPtr
      .asTypedList(buffer.length)
      .setAll(0, buffer);

    return singleResponseFuture((port) => 
    nWriteFileAsync(
      port.nativePort,
      repositoryPath.toNativeUtf8(),
      filePath.toNativeUtf8(),
      bufferPtr,
      buffer.length,
      offset
    ));
  }

  static Stream<dynamic> readFile(String repositoryPath, String filePath, int bufferSize, int totalBytes) async* {
    
    final bufferPtr = calloc<Uint8>(bufferSize);
    int offset = 0;

    while(true) {

      var result = await singleResponseFuture((port) => 
      nReadFileAsync(
        port.nativePort,
        repositoryPath.toNativeUtf8(),
        filePath.toNativeUtf8(),
        bufferPtr,
        bufferSize,
        offset
      ));

      print(result);

      int readBytes = int.tryParse(result.split(':')[1]);
      offset += readBytes;
      
      if (readBytes > 0) {
        yield bufferPtr.asTypedList(readBytes);
      }

      if (readBytes < bufferSize) {
        print('No more bytes to read.\nTotal bytes read:$offset');
        break;
      }
    }

    yield "EOF";
  }
}
