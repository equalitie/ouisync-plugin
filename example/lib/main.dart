import 'package:flutter/material.dart';
import 'package:ouisync_plugin/ouisync.dart';
import 'package:ouisync_plugin_example/repos_actions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> _repositories = [];
  String _newRepoName;

  bool _createDirAsyncResult;

  @override
  void initState() {
    super.initState(); 

    OuiSync.setupCallbacks();
    initializeRepositories();
  }

  void initializeRepositories() async {
    var repositories = await getRepositories();
    if (repositories.isEmpty) {
      return;
    }

    initializeUserRepositories(repositories);

    setState(() {
      _repositories = repositories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OuiSync Plugin example app'),
        ),
        body: Center(
          child: _repositories.isNotEmpty
          ? _listOfRepositories(context, _repositories)
          : _createRepository(context)
        ),
      )
    );
  }

  Widget _listOfRepositories(BuildContext context, List<String> repositories) {
    return ListView.builder(
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repo = repositories[index];
        return Text('$repo');
      },
    );
  }

  Widget _createRepository(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          TextField(
            onChanged: (newRepoName) {
              setState(() {
                _newRepoName = newRepoName;
              });
            },
          ),
          OutlinedButton(
            onPressed: () {
              if (_newRepoName.isEmpty) {
                return;
              }

              if (_repositories.contains(_newRepoName)) {
                final snackBar = SnackBar(
                  content: Text('This repository already exist')
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return;
              }

              createRepository(_newRepoName);
              this.build(context);
            }, 
            child: Text('create')),
        ],
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
