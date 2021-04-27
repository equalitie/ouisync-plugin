import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _createDirAsyncResult;

  @override
  void initState() {
    super.initState(); 
    OuiSync.setupCallbacks();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('createDirAsync returned $_createDirAsyncResult'),
        ),
      ),
    );
  }

  Future<void> createFolder(String repoDir, String newFolderRelativePath)  async {
    await OuiSync.newFolder(repoDir, newFolderRelativePath)
    .catchError((onError) {
      print('Error on createDirAsync call: $onError');
    })
    .then((returned) => {
      setState(() {
        _createDirAsyncResult = returned == 0;
      })
    })
    .whenComplete(() => {
      print('createFolderAsync completed')
    });
  }
}
