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
        store: '${temp.path}/repo.db', password: 'test123');
  });

  tearDown(() {
    session.close();
    temp.deleteSync;
  });

  test('Close a repository asynchronously in Windows fails', () async {
    await repo.close();
  });

  // test('Close a repository asynchronously  in Windows using microtask succeeds', () {
  //   Future.microtask(() async => await repo.close());
  // });
}
