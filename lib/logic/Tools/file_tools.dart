import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:tuple/tuple.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

class FileTools {
  //Search for exe files inside the game folder
  /*static List<String> getFolderFiles(String path, {retrieveRelativePaths = false, bool recursive = true, String regExFilter = ""}) {
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
  }*/

  //Returns null if the folder couldn't be read
  static Future<List<String>?> getFolderFilesAsync(String path, {retrieveRelativePaths = false, bool recursive = true, String regExFilter = "", onlyFolders=false, bool regExCaseSensitive=true}) async{
    final myDir = new Directory(path);

    if(!await myDir.exists()) return [];

    var stream =  myDir.list(recursive: recursive, followLinks: false);

    if(onlyFolders) {
      stream = stream.where((event) {
        return event.runtimeType.toString() == "_Directory"; // "event.runtimeType is Directory" is not working for me
      });
    }

    if(regExFilter.isNotEmpty) {
      RegExp r = RegExp(regExFilter,caseSensitive: regExCaseSensitive);

      stream = stream.where((event) {
          String fileName = p.basename(event.path);
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

    List<String>? foundFiles;

    try {
      foundFiles = await fileNamesStream.toList();
    }
    on FileSystemException catch (m, ex) {
      print("Folder couldn't be read: $m");
    }

    return foundFiles;
  }

  static String getHomeFolder() {
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    return envVars['HOME']!;
  }

  static Future<Map<String, int>> getFolderMetaData(String dirPath, {bool recursive=false}) async{
    int fileCount = 0;
    int totalSize = 0;
    int creationDate = 0;

    var dir = Directory(dirPath);
    try {
      if (await dir.exists()) {
        FileStat fs = await dir.stat();
        creationDate = fs.modified.microsecondsSinceEpoch;
        await dir.list(recursive: recursive, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            fileCount++;
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      print(e.toString());
    }

    return {'fileCount': fileCount, 'size': totalSize, 'creationDate':creationDate};
  }

  static bool existsFileSync(String path) {
    return File(path).existsSync();
  }

  static bool existsFolderSync(String path) {
    return Directory(path).existsSync();
  }

  static Future<bool> existsFile(String path) async{
    return await File(path).exists();
  }

  static Future<bool> existsFolder(String path) async{
    return await Directory(path).exists();
  }

  //Returns if the writer wrote anything. If not, there was no file modification
  static Future<bool> saveFileSecure<T>(String path, T data, Map<String, dynamic> extraParams, Future<bool> Function(String,T, Map<String,dynamic> extraParams) writer, int maxBackups) async {
    String dirName = p.dirname(path);
    String fileName = p.basename(path);

    //Copy current file to backup
    Tuple2 backupFiles = await getNextBackupFile(path, maxBackups);

    if(await File(path).exists()) {
      var file = File(path);
      await file.copy("${dirName}/${backupFiles.item1}");
    }

    if(backupFiles.item2 != null) {
      //Create new and delete old backup
      await File(backupFiles.item2).delete();

    }

    //Create temp file, copy over the old old one and delete temp
    String tempFileName ="${dirName}/tempFile";
    bool didWrite = await writer(tempFileName,data, extraParams);
    if(didWrite) {
      var tempFile = File(tempFileName);
      await tempFile.copy(path);
      await tempFile.delete();
      return true;
    }

    return false;
  }

  //Tuple[0] new backup file Tuple[1] the backup file that must be deleted to rotate (because we reach max backups
  static Future<Tuple2<String,String?>> getNextBackupFile(String path, int maxBackups) async
  {
    String? backupToDelete;

    String fileName = p.basename(path);
    String folder = p.dirname(path);

    if(! await Directory(folder).exists()) throw NotFoundException("Folder $folder does not exist when saving backup.");

    List<String>? files = await getFolderFilesAsync(folder,recursive: false, regExFilter: "${fileName}_.*");
    if(files!.length>=maxBackups)
    {
        files.sort();
        backupToDelete = files[0];
    }

    String newBackupFile = "${fileName}_${DateTime.now().millisecondsSinceEpoch}";

    return Tuple2(newBackupFile, backupToDelete);
  }

  static Future<void> clampBackupsToCount(String path, int maxBackups) async
  {
    String fileName = p.basename(path);
    String folder = p.dirname(path);

    if(! await Directory(folder).exists()) throw NotFoundException("Folder $folder does not exist when saving backup.");

    List<String>? files = await getFolderFilesAsync(folder,recursive: false, regExFilter: "${fileName}_.*");

    if(files!.length>=maxBackups)
    {
      files.sort();

      //delete all not needed backups (older)
      int deleteCount = files.length - maxBackups;
      for(int i=0; i<deleteCount; ++i) {
        await File(files[i]).delete();
      }
    }
  }

}
