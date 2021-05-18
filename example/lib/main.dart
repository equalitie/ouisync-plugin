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
    load();
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
          title: const Text('Plugin example app'),
        ),
        body: Center(child: Text('Num files in /: ${dir?.length ?? 0}')),
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
