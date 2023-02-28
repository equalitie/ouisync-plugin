import 'dart:convert';
import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';

void main() {
  late io.Directory temp;
  late Session session1;
  late Session session2;
  late Repository repo1;
  late Repository repo2;

  setUp(() async {
    temp = await io.Directory.systemTemp.createTemp();
    session1 = Session.create('${temp.path}/1/config');
    session2 = Session.create('${temp.path}/2/config');

    repo1 = await Repository.create(
      session1,
      store: '${temp.path}/1/repo.db',
      readPassword: null,
      writePassword: null,
    );
    final token = await repo1.createShareToken(accessMode: AccessMode.write);

    repo2 = await Repository.create(
      session2,
      store: '${temp.path}/2/repo.db',
      shareToken: token,
      readPassword: null,
      writePassword: null,
    );

    await session1.bindNetwork(quicV4: "127.0.0.1:0");
    final addr1 = await session1.quicListenerLocalAddressV4;

    await session2.bindNetwork(quicV4: "127.0.0.1:0");
    await session2.addUserProvidedQuicPeer(addr1!);
  });

  tearDown(() async {
    await repo2.close();
    await repo1.close();
    await session2.dispose();
    await session1.dispose();
    await temp.delete(recursive: true);
  });

  test('on create file', () async {
    // One event for each block created (one for the root directory and one for the file)
    final expect = expectLater(repo2.events, emitsInOrder([null, null]));

    final file = await File.create(repo1, "file.txt");
    await file.close();

    await expect;
  });
}
