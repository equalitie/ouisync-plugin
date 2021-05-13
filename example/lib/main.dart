import 'package:flutter/material.dart';
//import 'package:ouisync_plugin/ouisync.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const Text('TODO'),
      ),
    );
  }

  //Future<void> createFolder(String repoDir, String newFolderRelativePath)  async {
  //  await OuiSync.newFolder(repoDir, newFolderRelativePath)
  //  .catchError((onError) {
  //    print('Error on createDirAsync call: $onError');
  //  })
  //  .then((returned) => {
  //    setState(() {
  //      _createDirAsyncResult = returned == 0;
  //    })
  //  })
  //  .whenComplete(() => {
  //    print('createFolderAsync completed')
  //  });
  //}
}
