import 'dart:convert';
import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:ouisync_plugin/state_monitor.dart';

void main() {
  late io.Directory temp;
  late Session session;
  late Repository repo;

  setUp(() async {
    temp = await io.Directory.systemTemp.createTemp();
    session = Session.create('${temp.path}/config');
    repo = await Repository.create(session,
        store: '${temp.path}/repo.db', readPassword: null, writePassword: null);
  });

  tearDown(() async {
    await repo.close();
    await session.dispose();
    await temp.delete(recursive: true);
  });

  test('file write and read', () async {
    final path = '/test.txt';
    final origContent = 'hello world';

    {
      final file = await File.create(repo, path);
      await file.write(0, utf8.encode(origContent));
      await file.close();
    }

    {
      final file = await File.open(repo, path);

      try {
        final length = await file.length;
        final readContent = utf8.decode(await file.read(0, length));

        expect(readContent, equals(origContent));
      } finally {
        await file.close();
      }
    }
  });

  test('empty directory', () async {
    final rootDir = await Directory.open(repo, '/');
    expect(rootDir, isEmpty);
  });

  test('share token access mode', () async {
    for (var mode in AccessMode.values) {
      final token = await repo.createShareToken(accessMode: mode);
      expect(await token.mode, equals(mode));
    }
  });

  test('encode and decode share token', () async {
    final token =
        await repo.createShareToken(accessMode: AccessMode.read, name: 'test');
    final encoded = await token.encode();
    final decoded = await ShareToken.decode(session, encoded);

    expect(token, equals(decoded));
  });

  test('repository access mode', () async {
    expect(await repo.accessMode, equals(AccessMode.write));
  });

  test('repository sync progress', () async {
    final progress = await repo.syncProgress;
    expect(progress, equals(Progress(0, 0)));
  });

  test('state monitor missing node', () async {
    final monitor =
        session.rootStateMonitor.child(MonitorId.expectUnique("invalid"));
    final node = await monitor.load();
    expect(node, isNull);

    // This is to assert that no exception is thrown
    final monitorSubscription = monitor.subscribe();
    final streamSubscription = monitorSubscription.stream.listen((_) {});

    await streamSubscription.cancel();
    await monitorSubscription.close();
  });
}
