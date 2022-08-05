import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../bindings.dart';

// Convenience function to convert a dart string to a C-style nul-terminated utf-8 encoded
// string pointer.
Pointer<Int8> stringToNativeUtf8(String str) =>
    str.toNativeUtf8(allocator: _NativeStringAllocator()).cast<Int8>();

class _NativeStringAllocator implements Allocator {
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    return malloc.allocate<T>(byteCount, alignment: alignment);
  }

  @override
  void free(Pointer<NativeType> ptr) {
    malloc.free(ptr);
  }
}

// Converts `Bytes` into `Uint8List` and deallocates the original pointer.
Uint8List bytesIntoUint8List(Bytes bytes) {
  if (bytes.ptr != nullptr) {
    try {
      // Creating a copy so we can deallocate the pointer.
      // TODO: is this the right way to do this?
      return Uint8List.fromList(bytes.ptr.asTypedList(bytes.len));
    } finally {
      malloc.free(bytes.ptr);
    }
  } else {
    return Uint8List(0);
  }
}
