import 'dart:convert';
import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

void main() {
  late io.Directory temp;
  late Session session;
  late Repository repo;

  setUp(() async {
    temp = await io.Directory.systemTemp.createTemp();
    session = await Session.open('${temp.path}/config');
    repo = await Repository.create(session,
        store: ':memory:', password: 'test123');
  });

  tearDown(() {
    repo.close();
    session.close();
    temp.deleteSync(recursive: true);
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

    try {
      expect(rootDir, isEmpty);
    } finally {
      rootDir.close();
    }
  });

  test('share token access mode', () async {
    for (var mode in AccessMode.values) {
      final token = await repo.createShareToken(accessMode: mode);
      expect(token.mode, equals(mode));
    }
  });

  test('encode and decode share token', () async {
    final token =
        await repo.createShareToken(accessMode: AccessMode.read, name: 'test');
    final encoded = token.encode();
    final decoded = ShareToken.decode(session, encoded);

    expect(token, equals(decoded));
  });

  test('repository access mode', () {
    expect(repo.accessMode, equals(AccessMode.write));
  });

  test('local addrs', () async {
    print('listener: ${session.listenerLocalAddress}');
    print('dht v4:   ${session.dhtLocalAddressV4}');
    print('dht v6:   ${session.dhtLocalAddressV6}');
  });
}
