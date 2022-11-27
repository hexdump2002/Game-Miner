import 'package:path/path.dart' as pathLib;
import 'package:steamdeck_toolbox/logic/Tools/file_tools.dart';

class UserGameExe {
  late bool added;
  late bool brokenLink;
  late String relativeExePath;

  UserGameExe(this.added, this.brokenLink, this.relativeExePath);
}

class UserGame {
  late final String path;
  late final String name;
  final List<UserGameExe> exeFileEntries = [];

  UserGame(this.path) {
    List<String> pathComponents = pathLib.split(path);
    name = pathComponents.last;
  }

  void addExeFile(String absoluteFilePath, {added = false}) {
    exeFileEntries.add(UserGameExe(added, false, absoluteFilePath));
  }

  void addExeFiles(List<String> filePaths) {
    filePaths.forEach((filePath) {
      addExeFile(filePath);
    });

  }

}