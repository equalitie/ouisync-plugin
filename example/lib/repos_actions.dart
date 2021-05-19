import 'dart:io';

import 'package:ouisync_plugin/ouisync.dart';
import 'package:path_provider/path_provider.dart';

const String repositories_folder = "repos";

Future<String> _getRepositoriesBasePath() async {
  final Directory supportDirectory = await getApplicationSupportDirectory();
  final String reposBasePath = '${supportDirectory.path}/$repositories_folder';

  print('Repositories base path: $reposBasePath');
  return reposBasePath;
}

Future<List<String>> getRepositories() async {
  final String repositoriesBasePath = await _getRepositoriesBasePath();

  bool exist = await Directory(repositoriesBasePath).exists();
  if (!exist) {
    print('No repositories were found');
    return [];
  }

  List<FileSystemEntity> repoList = await Directory(repositoriesBasePath).list().toList();
  print('Repositories found: ${repoList.length}:\n');

  return repoList.map((e) {
    print('${e.path}\n');
    e.path;
  }).toList();
}

void initializeUserRepositories(List<String> reposList) {
  reposList.forEach((repo) => {
    print('Initilializing repository: $repo'),
    OuiSync.initializeRepository(repo)
  });
}

void createRepository(String newRepositoryPath) async {
  final String repositoriesBasePath = await _getRepositoriesBasePath();
  String fullPath = '$repositoriesBasePath/$newRepositoryPath';

  print('Creating repository: $newRepositoryPath');
  OuiSync.initializeRepository(fullPath);
}