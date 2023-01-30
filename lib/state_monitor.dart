import 'dart:collection';

import 'client.dart' show Subscription;
import 'ouisync_plugin.dart' show Session;

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

  static MonitorId parse(String raw) {
    // A string in the format "disambiguator:name".
    final colon = raw.indexOf(':');
    final disambiguator = int.parse(raw.substring(0, colon));
    final name = raw.substring(colon + 1);

    return MonitorId(name, disambiguator);
  }

  @override
  String toString() {
    return "$_name:$_disambiguator";
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

  static Future<StateMonitor?> getRoot(Session session) =>
      _getMonitor(session, <MonitorId>[]);

  Future<StateMonitor?> child(MonitorId childId) =>
      _getMonitor(session, [...path, childId]);

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

  Future<bool> refresh() async {
    final m = await _getMonitor(session, path);

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

  static Future<StateMonitor?> _getMonitor(
    Session session,
    List<MonitorId> path,
  ) async {
    final list = await session.client
        .invoke("state_monitor_get", path.join("/")) as List<Object?>;
    return StateMonitor._decode(session, path, list);
  }

  static StateMonitor? _decode(
    Session session,
    List<MonitorId> path,
    List<Object?> raw,
  ) {
    if (raw.length < 3) {
      return null;
    }

    final version = raw[0] as int;
    final values = _decodeValues(raw[1]);
    final children = _decodeChildren(raw[2]);

    return StateMonitor._(
      session,
      path,
      version,
      values,
      children,
    );
  }

  static Map<String, String> _decodeValues(Object? raw) =>
      SplayTreeMap<String, String>.from(raw as Map<String, String>);

  static Map<MonitorId, int> _decodeChildren(Object? raw) {
    final rawChildren = raw as Map<String, int>;
    var children = SplayTreeMap<MonitorId, int>();

    for (final entry in rawChildren.entries) {
      final id = MonitorId.parse(entry.key);
      children[id] = entry.value;
    }

    return children;
  }
}
