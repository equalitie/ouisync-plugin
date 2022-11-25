import 'dart:ffi';
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:collection';

import 'package:ffi/ffi.dart' as ffi;
import 'package:messagepack/messagepack.dart';

import 'bindings_global.dart';
import 'ouisync_plugin.dart' show BytesExtension;

// Version is incremented every time the monitor or any of it's values or
// children changes.
typedef Version = int;

// Used to identify child state monitors.
class MonitorId implements Comparable<MonitorId> {
  final String _name;
  // This one is now shown to the user, it allows us to have multiple monitors of the same name.
  final int _disambiguator;

  String get name => _name;

  MonitorId(this._name, this._disambiguator);

  // For when we expect the name to uniquely identify the child.
  static MonitorId expectUnique(String name) => MonitorId(name, 0);

  @override
  String toString() {
    return "MonitorId($_name, $_disambiguator)";
  }

  @override
  int compareTo(MonitorId other) {
    // Negative return value means `this` will be appear first.
    final cmp = _name.compareTo(other._name);
    if (cmp == 0) {
      return _disambiguator - other._disambiguator;
    }
    return cmp;
  }
}

class StateMonitor {
  List<MonitorId> path;
  Version version;
  Map<String, String> values;
  Map<MonitorId, Version> children;

  static StateMonitor? getRoot() {
    return _getMonitor(<MonitorId>[]);
  }

  StateMonitor? child(MonitorId childId) {
    return _getMonitor([...path, childId]);
  }

  Iterable<StateMonitor> childrenWithName(String name) {
    return children.entries
        .where((e) => e.key.name == name)
        .map((e) => child(e.key))
        // Filter out nulls.
        .whereType<StateMonitor>();
  }

  int? parseIntValue(String name) {
    final str = values[name];
    if (str == null) return null;
    return int.tryParse(str);
  }

  Subscription? subscribe() {
    final recvPort = ReceivePort();

    var subscriptionHandle = 0;

    final pathBytes = _pathBytes(path);
    _withPointer(pathBytes, (Pointer<Uint8> pathPtr) {
      subscriptionHandle = bindings.session_state_monitor_subscribe(
          pathPtr, pathBytes.length, recvPort.sendPort.nativePort);
    });

    if (subscriptionHandle == 0) {
      return null;
    }

    return Subscription._(bindings, subscriptionHandle, recvPort);
  }

  bool refresh() {
    final m = _getMonitor(path);

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
    return "StateMonitor{ path:$path, version:$version, values:$values, children:$children }";
  }

  StateMonitor._(
    this.path,
    this.version,
    this.values,
    this.children,
  );

  static _withPointer(Uint8List data, fn) {
    var buffer = ffi.malloc<Uint8>(data.length);

    try {
      buffer.asTypedList(data.length).setAll(0, data);
      fn(buffer);
    } finally {
      ffi.malloc.free(buffer);
    }
  }

  static Uint8List _pathBytes(List<MonitorId> path) {
    final p = Packer();
    p.packListLength(path.length);

    for (final item in path) {
      p.packListLength(2);
      p.packString(item._name);
      p.packInt(item._disambiguator);
    }

    return p.takeBytes();
  }

  static StateMonitor? _getMonitor(List<MonitorId> path) {
    StateMonitor? monitor;
    final pathBytes = _pathBytes(path);
    _withPointer(pathBytes, (Pointer<Uint8> pathPtr) {
      final bytes =
          bindings.session_get_state_monitor(pathPtr, pathBytes.length);
      monitor = StateMonitor._parse(path, bytes.intoUint8List());
    });
    return monitor;
  }

  static StateMonitor? _parse(List<MonitorId> path, Uint8List messagepackData) {
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

  static Map<MonitorId, int> _unpackChildren(Unpacker u) {
    final childrenLen = u.unpackMapLength();
    var children = SplayTreeMap<MonitorId, int>();

    for (var i = 0; i < childrenLen; i++) {
      // A string in the format "disambiguator:name".
      final idStr = u.unpackString()!;
      final colon = idStr.indexOf(':');
      final disambiguator = int.parse(idStr.substring(0, colon));
      final name = idStr.substring(colon + 1);
      children[MonitorId(name, disambiguator)] = u.unpackInt()!;
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
