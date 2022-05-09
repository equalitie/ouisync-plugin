import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
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
  ChangeId changeId;
  Map<String, String> values;
  Map<String, ChangeId> children;

  static StateMonitor? getRoot(Bindings bindings) {
    return _getMonitor(bindings, <String>[]);
  }

  StateMonitor? child(String name) {
    return _getMonitor(bindings, [...path, name]);
  }

  Subscription? subscribe() {
    final recvPort = ReceivePort();

    final subscriptionHandle =
        bindings.session_state_monitor_subscribe(
            stringToNativeUtf8(_pathStr(path)),
            recvPort.sendPort.nativePort);

    if (subscriptionHandle == 0) {
      return null;
    }

    return Subscription._(
        bindings,
        subscriptionHandle,
        recvPort
    );
  }

  bool refresh() {
    final m = _getMonitor(bindings, path);

    if (m == null) {
      values.clear();
      children.clear();
      return false;
    }

    changeId = m.changeId;
    values = m.values;
    children = m.children;

    return true;
  }

  @override
  String toString() {
    return "StateMonitor{ path:${_pathStr(path)}, changeId:$changeId, values:$values, children:$children }";
  }

  StateMonitor._(
      this.path,
      this.bindings,
      this.changeId,
      this.values,
      this.children,
  );

  static String _pathStr(List<String> path) {
    return path.join(':');
  }

  static StateMonitor? _getMonitor(Bindings bindings, List<String> path) {
    final bytes = _getMonitorBytes(bindings, _pathStr(path));
    return StateMonitor._parse(path, bindings, bytes);
  }

  static Uint8List _getMonitorBytes(Bindings bindings, String path) {
    return bytesIntoUint8List(bindings.session_get_state_monitor(stringToNativeUtf8(path)));
  }

  static StateMonitor? _parse(List<String> path, Bindings bindings, Uint8List messagepack_data) {
    if (messagepack_data.length == 0) {
      return null;
    }

    var unpacker = Unpacker(messagepack_data);

    //// Struct is encoded as a list.  Use this for debugging. Note that
    //// unpackList returns a list of `Object?`s so we would need to do a lot
    //// of type casting if we were to use this function directly.
    //final struct = unpacker.unpackList();
    //print("Unpacked StateMonitor: $struct");
    //return null;

    assert(unpacker.unpackListLength() == 3);

    // First of the three elements: changeId
    final changeId = unpacker.unpackInt()!;
    final values = _unpackValues(unpacker);
    final children = _unpackChildren(unpacker);

    return StateMonitor._(
      path,
      bindings,
      changeId,
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

class Subscription {
  final Bindings _bindings;
  final int _handle;
  final ReceivePort _port;

  late final Stream<Null> stream;

  Subscription._(this._bindings, this._handle, this._port) {
    final ctrl = StreamController<Null>();
    _port.listen((Null) { ctrl.add(null); });
    stream = ctrl.stream;
  }

  void close() {
    _bindings.session_state_monitor_unsubscribe(_handle);
    _port.close();
  }
}
