import 'dart:convert';

import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:test/test.dart';

void main() {
  late Session session;

  late Repository repository;
  late Subscription subscription;

  late String currentPath;

  final folder1Path = '/folder1';
  final file1InFolder1Path = '/folder1/file1.txt';
  final file1Content = 'Lorem ipsum dolor sit amet';

  Future<void> getDirectoryContents(Repository repo, String path) async {
    final folder1Contents = await Directory.open(repo, path);
    print('Directory contents: ${folder1Contents.toList()}');
    folder1Contents.close();
  }

  setUp(() async {
    session = await Session.open(':memory:');
    repository = await Repository.open(session, ':memory:');

    currentPath = '/';

    subscription = repository.subscribe(() async {
      print('Syncing $currentPath');
      await getDirectoryContents(repository, currentPath);
    });
  });

  tearDown(() {
    subscription.cancel();
    repository.close();

    session.close();
  });

  test('Add file to directory with syncing not in directory',
  () async {
    // Create folder1 (/folder1)
    { 
      await Directory.create(repository, folder1Path);
      print('New folder: $folder1Path');
    }
    // Create file1.txt inside folder1 (/folder1/file1.txt)
    {
      print('About to create file $file1InFolder1Path');
      final file = await File.create(repository, file1InFolder1Path);
      await file.write(0, utf8.encode(file1Content));
      await file.close();
    }
    // Get contents of folder1 (/folder1) and confirm it contains only one entry
    {
      final folder1Contents = await Directory.open(repository, folder1Path);
      expect(folder1Contents.toList().length, equals(1));

      print('Folder1 contents: ${folder1Contents.toList()}');
    }
  });

  test('Add file with syncing in directory',
  () async {
    // Create folder1 (/folder1)
    { 
      await Directory.create(repository, folder1Path);
      print('New folder: $folder1Path');

      currentPath = folder1Path;
    }
    // Create file1 inside folder1 (/folder1/file1.txt)
    {
      print('About to create new file $file1InFolder1Path');
      final file = await File.create(repository, file1InFolder1Path);
      await file.write(0, utf8.encode(file1Content));
      await file.close();
    }
    // Get contents of folder1 (/folder1) and confirm it contains only one entry
    {
      final folder1Contents = await Directory.open(repository, folder1Path);
      expect(folder1Contents.toList().length, equals(1));

      print('Folder1 contents: ${folder1Contents.toList()}');
    }
  });
}