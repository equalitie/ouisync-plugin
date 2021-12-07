import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:test/scaffolding.dart';
import 'package:test/test.dart';

void main() {
  late Session session;
  late Repository repository;
  late Subscription subscription;

  const String resourceFilePath = 'test/test_resources/simmel.pdf';

  const String directoryPath = '/';
  const String filePath = '/test_file.pdf';

  const int bufferSize = 64000;

  Future<void> syncDirectory(Repository repo, String path) async {
    print('Syncing directory $path');
    
    final folder1Contents = await Directory.open(repo, path);
    final contents = folder1Contents.toList();
    folder1Contents.close();

    print('$path: $contents');
  }

  setUp(() async {
    session = await Session.open(':memory:');
    repository = await Repository.open(session, ':memory:');

    subscription = repository.subscribe(() async =>
      await syncDirectory(repository, directoryPath)
    );
  });

  tearDown(() {
    subscription.cancel();
    repository.close();
    session.close();
  });

  test('Create file, write to file (no chunks), then get file length',
  () async {

    // - Get stream from /test/test_resources/simmel.pdf,
    // - Create new file /test_file.pdf
    // - Write to file /test_file.pdf (no chunks)
    // - Close/cancel file and stream reader
    {
      final testFile = io.File(resourceFilePath);
      final bytes = await testFile.readAsBytes();
    
      try {
        final file = await File.create(repository, filePath);
        file.write(0, bytes.toList());
        // file.write(0, utf8.encode(fileContents));
        file.close(); 
      } catch (e) {
        print(e.toString());
      } 
    }

    // Get file length for /test_file.pdf throws an error
    {
      print('Getting lenght of file $filePath');

      int length = -1;
      try {
        final file = await File.open(repository, filePath);
        length = await file.length;
        file.close();

        print('File $filePath length: $length');
      } catch (e) {
        print('${e.runtimeType}: ${e.toString()}');
      }

      expect(length, greaterThan(0));  
    }
  }, timeout: Timeout.none);

  test('Create file, write to file in chunks from stream, then get file length',
  () async {
    // - Get stream from /test/test_resources/simmel.pdf,
    // - Create new file /test_file.pdf
    // - Write to file /test_file.pdf in chunks of bufferSize (64,000)
    // - Close/cancel file and stream reader
    {
      final testFile = io.File(resourceFilePath);
      final streamReader = ChunkedStreamReader(testFile.openRead());
    
      final file = await File.create(repository, filePath);
      int offset = 0;
      
      try {
        while (true) {
          final buffer = await streamReader.readChunk(bufferSize);
          print('Buffer size: ${buffer.length} - offset: $offset');

          if (buffer.isEmpty) {
            print('The buffer is empty; reading from the stream is done!');
            break;
          }

          await file.write(offset, buffer);
          offset += buffer.length;
        }
      } catch (e) {
        print('Exception writing to file $filePath:\n${e.toString()}');
      } finally {
        streamReader.cancel();
        file.close();

        print('New file: $filePath created successfully');
      }
    }
    
    // Get file length for /test_file.pdf
    {
      print('Getting lenght of file $filePath');

      int length = -1;
      try {
        final file = await File.open(repository, filePath);
        length = await file.length;
        file.close();

        print('File $filePath length: $length');
      } catch (e) {
        print('${e.runtimeType}: ${e.toString()}');
      }

      expect(length, greaterThan(0));  
    }
  }, timeout: Timeout.none);

}