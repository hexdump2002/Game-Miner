import 'dart:io';
import 'package:path/path.dart';

class FileTools {
  //Search for exe files inside the game folder
  static List<String> getFolderFiles(String path, {retrieveRelativePaths = false, bool recursive = true, String regExFilter = ""}) {
    final myDir = new Directory(path);
    var files = myDir.listSync(recursive: recursive, followLinks: false);

    late List<String> fileNames;

    if (regExFilter.isNotEmpty) {
      RegExp r = RegExp(regExFilter);
      files.retainWhere((p) {
        String fileName = basename(p.path);
        return r.hasMatch(fileName);
      });
    }

    int pathLength = path.length;
    fileNames = files.map((f) {
      var finalPath = f.path;

      //+1 to remove the / character at the end of the absolute path
      if (retrieveRelativePaths) finalPath = f.path.substring(pathLength+1);

      return finalPath;
    }).toList();

    return fileNames;
  }

  static Future<List<String>> getFolderFilesAsync(String path, {retrieveRelativePaths = false, bool recursive = true, String regExFilter = ""}) {
    final myDir = new Directory(path);
    var stream =  myDir.list(recursive: recursive, followLinks: false);

    if(regExFilter.isNotEmpty) {
      RegExp r = RegExp(regExFilter);

      stream = stream.where((event) {
          String fileName = basename(event.path);
          return r.hasMatch(fileName);
        });
    }

    int pathLength = path.length;
    Stream<String> fileNamesStream = stream.map<String>((f) {
      var finalPath = f.path;

      //+1 to remove the / character
      if (retrieveRelativePaths) finalPath = f.path.substring(pathLength+1);

      return finalPath;
    });

    return fileNamesStream.toList();
  }

  static String getHomeFolder() {
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    return envVars['HOME']!;
  }
}
