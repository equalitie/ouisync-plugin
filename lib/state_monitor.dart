import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:collection';
import 'package:messagepack/messagepack.dart';
import 'internal/util.dart';
import 'bindings.dart';

// Version is incremented every time the monitor or any of it's values or
// children changes.
typedef Version = int;

class StateMonitor {
  List<String> path;
  Bindings bindings;
  Version version;
  Map<String, String> values;
  Map<String, Version> children;

  static StateMonitor? getRoot(Bindings bindings) {
    return _getMonitor(bindings, <String>[]);
  }

  StateMonitor? child(String name) {
    return _getMonitor(bindings, [...path, name]);
  }

  int? parseIntValue(String name) {
    final str = values[name];
    if (str == null) return null;
    return int.tryParse(str);
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

    version = m.version;
    values = m.values;
    children = m.children;

    return true;
  }

  @override
  String toString() {
    return "StateMonitor{ path:${_pathStr(path)}, version:$version, values:$values, children:$children }";
  }

  StateMonitor._(
      this.path,
      this.bindings,
      this.version,
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

  static StateMonitor? _parse(List<String> path, Bindings bindings, Uint8List messagepackData) {
    if (messagepackData.isEmpty) {
      return null;
    }

    var unpacker = Unpacker(messagepackData);

    //// Struct is encoded as a list.  Use this for debugging. Note that
    //// unpackList returns a list of `Object?`s so we would need to do a lot
    //// of type casting if we were to use this function directly.
    //final struct = unpacker.unpackList();
    //print("Unpacked StateMonitor: $struct");
    //return null;

    final listLength = unpacker.unpackListLength();

    // Note: assertion happens only in the debug mode.
    assert(listLength == 3);

    final version = unpacker.unpackInt()!;
    final values = _unpackValues(unpacker);
    final children = _unpackChildren(unpacker);

    return StateMonitor._(
      path,
      bindings,
      version,
      values,
      children,
    );
  }

  static Map<String, String> _unpackValues(Unpacker u) {
    final valuesLen = u.unpackMapLength();
    var values = SplayTreeMap<String, String>();

    for (var i = 0; i < valuesLen; i++) {
      final key = u.unpackString()!;
      values[key] = u.unpackString()!;
    }

    return values;
  }

  static Map<String, int> _unpackChildren(Unpacker u) {
    final childrenLen = u.unpackMapLength();
    var children = SplayTreeMap<String, int>();

    for (var i = 0; i < childrenLen; i++) {
      final childName = u.unpackString()!;
      children[childName] = u.unpackInt()!;
    }

    return children;
  }
}

class Subscription {
  final Bindings _bindings;
  final int _handle;
  final ReceivePort _port;

  // Broadcast Streams don't buffer, which is what we want given that the
  // stream doesn't carry any meaningful value except for the information that
  // a change happened.
  late final Stream<void> broadcastStream;

  Subscription._(this._bindings, this._handle, this._port)
    : broadcastStream = _port.asBroadcastStream().cast<void>();

  void close() {
    _bindings.session_state_monitor_unsubscribe(_handle);
    _port.close();
  }
}
