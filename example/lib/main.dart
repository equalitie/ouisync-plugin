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

  final contents = <String>[];

  @override
  void initState() {
    super.initState();

    initObjects().
      then((value) => loadFiles());
  }

  Future<void> initObjects() async {
    final session = await Session.open(
        join((await getApplicationSupportDirectory()).path, 'db'));

    NativeChannels.init(session);
    
    setState(() {
      this.session = session;
    });
  }

  void loadFiles() async =>
    getFiles('/');  

  @override
  void dispose() async {
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
        Padding(
          padding: EdgeInsets.all(4.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () async => 
                  await addFile()
                  .then((value) async => {
                    await getFiles('/')
                  }),
                child: Text('Add file')
              ),
            ],
          ),
        ),
        fileList(),
      ],
    );
  }

  Widget fileList() => ListView.separated(
        separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.transparent
        ),
        shrinkWrap: true,
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final item = contents[index];

          return Card(
            child: ListTile(
              title: Text(item),
              onTap: () => 
                showAlertDialog(context, item, 1)
            )
          );
        }
    );

  Future<void> addFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withReadStream: true);
    if (result != null) {
      final path = '/${result.files.single.name}';
      final file = await createFile(path);
      await saveFile(file, path, result.files.first.readStream!); 
    }
  }

  Future<File> createFile(String filePath) async {
    File? newFile;

    final repo = await Repository.open(session!);

    try {
      print('Creating file $filePath');
      newFile = await File.create(repo, filePath);
    } catch (e) {
      print('Error creating file $filePath: $e');
    }

    return newFile!;
  } 

  Future<void> saveFile(File file, String path, Stream<List<int>> stream) async {
    print('Writing file $path');
    
    int offset = 0;
    // final file = await File.open(repo!, path);

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
      print('Exception writing the fie $path:\n${e.toString()}');
    } finally {
      file.close();
    }
  }

  Future<void> getFiles(path) async {
    final repo = await Repository.open(session!);
    final dir = await Directory.open(repo, path);

    
    final items = <String>[];
    final iterator = dir.iterator;
    while (iterator.moveNext()) {
      items.add(iterator.current.name);
    }
    
    setState(() {
      contents.clear();
      contents.addAll(items);
    });

    dir.close();
    repo.close();
  }
}

showAlertDialog(BuildContext context, String path, int size) {
  Widget previewFileButton = TextButton(
    child: Text("Preview"),
    onPressed:  () async {
      Navigator.of(context).pop();
      await NativeChannels.previewOuiSyncFile(path, size);
    },
  );
  Widget shareFileButton = TextButton(
    child: Text("Share"),
    onPressed:  () async {
      Navigator.of(context).pop();
      await NativeChannels.shareOuiSyncFile(path, size);
    }
  );
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed:  () {
      Navigator.of(context).pop();
    },
  ); 

  AlertDialog alert = AlertDialog(
    title: Text("OuiSync Plugin Example App"),
    content: Text("File:\n$path"),
    actions: [
      previewFileButton,
      shareFileButton,
      cancelButton,
    ],
  );
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
