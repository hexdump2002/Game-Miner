import 'dart:io';

import '../../logic/Tools/file_tools.dart';
import '../models/compat_tool_mapping.dart';

class CompatToolsMappingDataProvider {
  final String _relativeConfigVdfPath = ".local/share/Steam/config/config.vdf";

  Future<List<CompatToolMapping>>  loadCompatToolMappings() async {

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

  Future<void> saveCompatToolMappings(String writePath, List<CompatToolMapping> compatToolMappings, Map<String, dynamic> extraParams ) async {

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
  }
}