import 'package:path/path.dart' as pathLib;
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';

class UserGameExe {
  late final bool added;
  late final bool brokenLink;
  late final String relativeExePath;
}

class UserGame {
  late final String path;
  late final String name;
  final List<String> exeFilePaths = [];

  UserGame(this.path) {
    List<String> pathComponents = pathLib.split(path);
    name = pathComponents.last;
  }

  void addExeFile(String exeFilePath) {
    exeFilePaths.add(exeFilePath);
  }

  void addExeFiles(List<String> filePaths) {
    exeFilePaths.addAll(filePaths);
  }

}