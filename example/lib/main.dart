import 'package:chunked_stream/chunked_stream.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Session? session;
  Repository? repo;
  Directory? dir;

  @override
  void initState() {
    super.initState();

    initObjects();
  }

  void initObjects() async {
    final session = await Session.open(
        join((await getApplicationSupportDirectory()).path, 'db'));
    final repo = await Repository.open(session);
    final dir = await Directory.open(repo, '/');

    NativeChannels.init(repo);
    
    setState(() {
      this.session = session;
      this.repo = repo;
      this.dir = dir;
    });
  }

  @override
  void dispose() async {
    dir?.close();
    repo?.close();
    session?.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OuiSync Plugin example app'),
        ),
        body: body(),
      ),
    );
  }

  Widget body() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(withReadStream: true);
            if (result != null) {
              final filePath = '/${result.files.single.name}';
              await createFile(filePath);
              await saveFile(filePath, result.files.first.readStream!); 
            }
          },
          child: Text('Add file')
        ),
        ElevatedButton(
          onPressed: () async {
            await NativeChannels.shareOuiSyncFile('DrzmArg.png');
          },
          child: Text('Share file')
        )
      ],
    );
  }

  Future<File> createFile(String filePath) async {
    File? newFile;

    try {
      print('Creating file $filePath');
      newFile = await File.create(repo!, filePath);
    } catch (e) {
      print('Error creating file $filePath: $e');
    } finally {
      newFile!.close();
    }

    return newFile;
  } 

  Future<void> saveFile(String filePath, Stream<List<int>> stream) async {
    print('Writing file $filePath');
    
    int offset = 0;
    final file = await File.open(repo!, filePath);

    try {
      final streamReader = ChunkedStreamIterator(stream);
      while (true) {
        final buffer = await streamReader.read(64000);
        print('Buffer size: ${buffer.length} - offset: $offset');

        if (buffer.isEmpty) {
          print('The buffer is empty; reading from the stream is done!');
          break;
        }

        await file.write(offset, buffer);
        offset += buffer.length;
      }
    } catch (e) {
      print('Exception writing the fie $filePath:\n${e.toString()}');
    } finally {
      file.close();
    }
  }
}
