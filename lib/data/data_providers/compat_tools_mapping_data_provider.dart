import 'dart:io';

import 'package:game_miner/logic/io/text_vdf_file.dart';
import 'package:collection/collection.dart';

import '../../logic/Tools/file_tools.dart';
import '../../logic/Tools/steam_tools.dart';
import '../models/compat_tool_mapping.dart';

class CompatToolsMappingDataProvider {
  final String _absoluteConfigVdfPath = "${SteamTools.getSteamBaseFolder()}/config/config.vdf";
/*
  Future<List<CompatToolMapping>>  _loadCompatToolMappings() async {

    String fullPath = "${FileTools.getHomeFolder()}/$_relativeConfigVdfPath";
    var file =  File(fullPath);
    var fileExists = await file.exists();
    if(!fileExists) return [];

    await file.open();
    String json = await file.readAsString();

    List<CompatToolMapping> protonMappings = [];

    RegExp r = RegExp(r'"CompatToolMapping"\n\t*{\n(\t*("(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*}\n))*\t*}');
    var match = r.firstMatch(json);
    if(match!=null) {
      String compatToolMappingText = (json.substring(match!.start, match!.end));
      r = RegExp(r'"(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"(\d+)\"\n\t*}');
      var matches = r.allMatches(compatToolMappingText);



      for (var element in matches) {
        protonMappings.add(CompatToolMapping(element.group(1)!, element.group(2)!, element.group(3)!, element.group(4)!));
      }
    }

    return Future.value(protonMappings);
  }
*/
  Future<List<CompatToolMapping>> loadCompatToolMappings() async {

    String fullPath = _absoluteConfigVdfPath;
    if(! await FileTools.existsFile(fullPath)) {
      return [];
    }

    List<CompatToolMapping> protonMappings = [];

    TxtVdfFile file = TxtVdfFile();
    file.open(fullPath, FileMode.read);
    CanonicalizedMap<String,String,dynamic> data = await file.read();
    CanonicalizedMap<String,String,dynamic>? compatToolMappings = data['InstallConfigStore']['software']['Valve']['Steam']['CompatToolMapping'];
    if(compatToolMappings==null) return [];

    for(String key in compatToolMappings.keys) {
      CanonicalizedMap<String,String,dynamic> compaToolMapping = compatToolMappings[key];
      protonMappings.add(CompatToolMapping(key, compaToolMapping['name'] as String, compaToolMapping['config'] as String, compaToolMapping['priority'] as String));
    }

    return protonMappings;
  }

  Future<void> saveCompatToolMappings(String writePath, List<CompatToolMapping> compatToolMappings, Map<String, dynamic> extraParams ) async {
    String fullPath = _absoluteConfigVdfPath;

    TxtVdfFile readFile = TxtVdfFile();
    readFile.open(fullPath, FileMode.read);
    var data = await readFile.read();
    readFile.close();

    TxtVdfFile writeFile = TxtVdfFile();
    writeFile.open(writePath, FileMode.writeOnly);


    CanonicalizedMap<String,String,dynamic>? compatToolMappingsMap = data['InstallConfigStore']['software']['Valve']['Steam']['CompatToolMapping'];
    if(compatToolMappingsMap==null) {
      compatToolMappingsMap = CanonicalizedMap<String,String,dynamic>((key)=>key.toLowerCase());
      data['InstallConfigStore']['software']['Valve']['Steam']['CompatToolMapping']=compatToolMappingsMap;
    }

    for(CompatToolMapping ctm in compatToolMappings) {
      var map = CanonicalizedMap<String,String,dynamic>((key) => key.toLowerCase());
      map['name'] = ctm.name;
      map['config'] = ctm.config;
      map['priority'] = ctm.priority;
      compatToolMappingsMap[ctm.id] = map;
    }

    await writeFile.write(data);
    writeFile.close();
  }
/*
  Future<void> _saveCompatToolMappings(String writePath, List<CompatToolMapping> compatToolMappings, Map<String, dynamic> extraParams ) async {

    //String fullPath = "${FileTools.getHomeFolder()}/$_relativeConfigVdfPath";
    String fullPath = extraParams.isEmpty ? writePath : extraParams['sourceFile'];

    var file =  File(fullPath);
    await file.open();
    String contents = await file.readAsString();

    int rootIdent = _getCategoryIndentation(contents, "CompatToolMapping");

    RegExp r = RegExp(r'"CompatToolMapping"\n\t*{\n(\t*("(\d+)\"\n\t*{\n\t*\"name\"\t*\"(.*)\"\n\t*\"config\"\t*\"(.*)\"\n\t*\"priority\"\t*\"\d+\"\n\t*}\n))*\t*}');

    String dstString = '"CompatToolMapping"';
    dstString+="\n";
    dstString+=_al("{","\t",rootIdent);
    dstString+="\n";
    for(CompatToolMapping ctm in compatToolMappings) {
        dstString = _writeProntoMappingToStr(dstString, ctm, rootIdent + 1);
    }

    dstString+= _al("}","\t",rootIdent);

    contents = contents.replaceAll(r, dstString);

    await File(writePath).writeAsString(contents);
  }

  String _al(String source, String strToAdd, int count) {
    for(int i=0; i<count; ++i) {
      source=strToAdd+source;
    }

    return source;
  }

  int _getCategoryIndentation(String contents, String category)
  {
    var r = RegExp('\t*"$category"\n\t+{');
    var match = r.firstMatch(contents);

    if(match == null ) return -1;

    String s = contents.substring(match.start,match.end);

    bool finished = false;
    int i = 0;

    if(s[0]!='\t') {
      finished = true;
    }
    else {
      ++i;
      while (!finished && i < s.length) {
        if (s[i] != '\t') {
          finished = true;
        }
        else {
          ++i;
        }
      }
    }

    return finished ? i : -1;
  }

  String _writeProntoMappingToStr(String dstString, CompatToolMapping e, int indent) {
    dstString+=_al('"${e.id}"\n',"\t", indent);
    dstString+=_al("{\n","\t",indent);
    dstString+= _al('"name"\t\t"${e.name}"\n',"\t",indent+1);
    dstString+= _al('"config"\t\t"${e.config}"\n',"\t",indent+1);
    dstString+= _al('"priority"\t\t"${e.priority}"\n',"\t",indent+1);
    dstString+= _al('}',"\t",indent);
    dstString+= "\n";

    return dstString;
  }*/
}