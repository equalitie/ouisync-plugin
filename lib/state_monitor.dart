import 'dart:ffi';
import 'dart:typed_data';
import 'dart:collection';

import 'package:ffi/ffi.dart' as ffi;
import 'package:messagepack/messagepack.dart';

import 'bindings_global.dart';
import 'client.dart' show Subscription;
import 'ouisync_plugin.dart' show BytesExtension, Session;

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
    return "$_name[$_disambiguator]";
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
  final Session session;
  List<MonitorId> path;
  Version version;
  Map<String, String> values;
  Map<MonitorId, Version> children;

  static StateMonitor? getRoot(Session session) {
    return _getMonitor(session, <MonitorId>[]);
  }

  StateMonitor? child(MonitorId childId) {
    return _getMonitor(session, [...path, childId]);
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

  Subscription subscribe() =>
      Subscription(session.client, "state_monitor", path.join("/"));

  bool refresh() {
    final m = _getMonitor(session, path);

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
    this.session,
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

  static StateMonitor? _getMonitor(Session session, List<MonitorId> path) {
    StateMonitor? monitor;
    final pathBytes = _pathBytes(path);
    _withPointer(pathBytes, (Pointer<Uint8> pathPtr) {
      final bytes = bindings.session_get_state_monitor(
        session.handle,
        pathPtr,
        pathBytes.length,
      );
      monitor = StateMonitor._parse(session, path, bytes.intoUint8List());
    });
    return monitor;
  }

  static StateMonitor? _parse(
    Session session,
    List<MonitorId> path,
    Uint8List messagepackData,
  ) {
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
      session,
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
