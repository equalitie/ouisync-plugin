import 'dart:convert';
import 'package:test/test.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

void main() {
  late Session session;
  late Repository repo;

  setUp(() async {
    session = await Session.open(':memory:');
    repo = await Repository.create(session,
        store: ':memory:', password: 'test123');
  });

  tearDown(() {
    repo.close();
    session.close();
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
}
