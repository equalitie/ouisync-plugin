import 'dart:io' as io;
import 'package:async/async.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Session session;
  late Repository repo;

  bool bittorrentDhtEnabled = false;

  final contents = <String>[];

  @override
  void initState() {
    super.initState();
    initObjects().then((value) => getFiles('/'));
  }

  Future<void> initObjects() async {
    final dataDir = (await getApplicationSupportDirectory()).path;
    final session = Session.open(join(dataDir, 'config.db'));

    final store = join(dataDir, 'repo.db');
    final storeExists = await io.File(store).exists();

    final repo = storeExists
        ? await Repository.open(session, store: store, password: null)
        : await Repository.create(session,
            store: store, readPassword: null, writePassword: null);

    bittorrentDhtEnabled = repo.isDhtEnabled;

    NativeChannels.init(repository: repo);

    setState(() {
      this.session = session;
      this.repo = repo;
    });
  }

  @override
  void dispose() async {
    repo.close();
    session.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
                title: Text("Ouisync Example App"),
                bottom:
                    TabBar(tabs: [Tab(text: "Files"), Tab(text: "Settings")])),
            body: TabBarView(
              children: [
                makeFileListBody(),
                makeSettingsBody(),
              ],
            )));
  }

  Widget makeFileListBody() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.0),
          child: Row(
            children: [
              ElevatedButton(
                  onPressed: () async => await addFile()
                      .then((value) async => {await getFiles('/')}),
                  child: Text('Add file')),
            ],
          ),
        ),
        fileList(),
      ],
    );
  }

  Widget makeSettingsBody() {
    return Column(
      children: <Widget>[
        SwitchListTile(
          title: Text("BitTorrent DHT"),
          value: bittorrentDhtEnabled,
          onChanged: (bool value) {
            enableDisableDht(value);
          },
        ),
      ],
    );
  }

  void enableDisableDht(bool enable) {
    if (enable) {
      repo.enableDht();
    } else {
      repo.disableDht();
    }

    final isEnabled = repo.isDhtEnabled;

    setState(() {
      bittorrentDhtEnabled = isEnabled;
    });
  }

  Widget fileList() => ListView.separated(
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.transparent),
      shrinkWrap: true,
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final item = contents[index];

        return Card(
            child: ListTile(
                title: Text(item),
                onTap: () => showAlertDialog(context, item, 1)));
      });

  Future<void> addFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withReadStream: true);

    if (result != null) {
      final path = '/${result.files.single.name}';
      final file = await createFile(path);
      await saveFile(file, path, result.files.first.readStream!);
    }
  }

  Future<File> createFile(String filePath) async {
    File? newFile;

    try {
      print('Creating file $filePath');
      newFile = await File.create(repo, filePath);
    } catch (e) {
      print('Error creating file $filePath: $e');
    }

    return newFile!;
  }

  Future<void> saveFile(
      File file, String path, Stream<List<int>> stream) async {
    print('Writing file $path');

    int offset = 0;

    try {
      final streamReader = ChunkedStreamReader(stream);
      while (true) {
        final buffer = await streamReader.readChunk(64000);
        print('Buffer size: ${buffer.length} - offset: $offset');

        if (buffer.isEmpty) {
          print('The buffer is empty; reading from the stream is done!');
          break;
        }

        await file.write(offset, buffer);
        offset += buffer.length;
      }
    } catch (e) {
      print('Exception writing the file $path:\n${e.toString()}');
    } finally {
      file.close();
    }
  }

  Future<void> getFiles(String path) async {
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
  }
}

void showAlertDialog(BuildContext context, String path, int size) {
  Widget previewFileButton = TextButton(
    child: Text("Preview"),
    onPressed: () async {
      Navigator.of(context).pop();
      await NativeChannels.previewOuiSyncFile(
          "ie.equalit.ouisync_plugin_example", path, size);
    },
  );
  Widget shareFileButton = TextButton(
      child: Text("Share"),
      onPressed: () async {
        Navigator.of(context).pop();
        await NativeChannels.shareOuiSyncFile(
            "ie.equalit.ouisync_plugin_example", path, size);
      });
  Widget cancelButton = TextButton(
    child: Text("Cancel"),
    onPressed: () {
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

  showDialog<AlertDialog>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
