import 'dart:typed_data';
import 'dart:collection';
import 'package:ffi/ffi.dart';
import 'package:messagepack/messagepack.dart';
import 'internal/util.dart';
import 'bindings.dart';

// ChangeId is incremented every time the monitor or any of it's values or
// children changes.
typedef ChangeId = int;

class StateMonitor {
  List<String> path;
  Bindings bindings;
  ChangeId change_id;
  Map<String, String> values;
  Map<String, ChangeId> children;

  StateMonitor(
      this.path,
      this.bindings,
      this.change_id,
      this.values,
      this.children,
  );

  static StateMonitor? getRoot(Bindings bindings) {
    final bytes = _getMonitorBytes(bindings, "");
    return StateMonitor._parse(<String>[], bindings, bytes);
  }

  StateMonitor? child(String name) {
    final child_path = [...path, name];
    final bytes = _getMonitorBytes(bindings, child_path.join(':'));
    return StateMonitor._parse(child_path, bindings, bytes);
  }

  static Uint8List _getMonitorBytes(Bindings bindings, String path) {
    return bytesIntoUint8List(bindings.session_get_state_monitor(stringToNativeUtf8(path)));
  }

  static StateMonitor? _parse(List<String> path, Bindings bindings, Uint8List messagepack_data) {
    var unpacker = Unpacker(messagepack_data);

    //// Struct is encoded as a list.  Use this for debugging. Note that
    //// unpackList returns a list of `Object?`s so we would need to do a lot
    //// of type casting if we were to use this function directly.
    //final struct = unpacker.unpackList();
    //print("Unpacked StateMonitor: $struct");
    //return null;

    assert(unpacker.unpackListLength() == 3);

    // First of the three elements: change_id
    final change_id = unpacker.unpackInt()!;
    final values = _unpackValues(unpacker);
    final children = _unpackChildren(unpacker);

    return StateMonitor(
      path,
      bindings,
      change_id,
      values,
      children,
    );
  }

  static Map<String, String> _unpackValues(Unpacker u) {
    final values_len = u.unpackMapLength();
    var values = SplayTreeMap<String, String>();

    for (var i = 0; i < values_len; i++) {
      final key = u.unpackString()!;
      values[key] = u.unpackString()!;
    }

    return values;
  }

  static Map<String, int> _unpackChildren(Unpacker u) {
    final children_len = u.unpackMapLength();
    var children = SplayTreeMap<String, int>();

    for (var i = 0; i < children_len; i++) {
      final child_name = u.unpackString()!;
      children[child_name] = u.unpackInt()!;
    }

    return children;
  }
}
