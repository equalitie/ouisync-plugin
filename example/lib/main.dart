import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:ouisync_plugin/ouisync.dart';
import 'package:ouisync_plugin_example/repos_actions.dart';
=======
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
>>>>>>> rust

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
<<<<<<< HEAD
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
=======
  Session? session;
  Repository? repo;
  Directory? dir;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() async {
    dir?.close();
    repo?.close();
    session?.close();

    super.dispose();
>>>>>>> rust
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OuiSync Plugin example app'),
        ),
<<<<<<< HEAD
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
=======
        body: Center(child: Text('Num files in /: ${dir?.length ?? 0}')),
>>>>>>> rust
      ),
    );
  }

  void load() async {
    final session = await Session.open(
        join((await getApplicationSupportDirectory()).path, 'db'));
    final repo = await Repository.open(session);
    final dir = await Directory.open(repo, '/');

    setState(() {
      this.session = session;
      this.repo = repo;
      this.dir = dir;
    });
  }
}
