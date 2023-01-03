

import 'dart:io';
import 'dart:typed_data';

import 'package:game_miner/data/models/compat_tool.dart';
import 'package:tuple/tuple.dart';

import '../../logic/Tools/file_tools.dart';
import 'package:path/path.dart' as p;

import '../../logic/io/binary_vdf_buffer.dart';

//Gets data in raw format. Provider will model it into domain data
//Raw means not processed data. Only a model to hold the retrieved data. If This data has to be aggregated, etc. will be
//processed in a repository to offer it to the domain logic in domain format (model that the domain logic expects and understands)
class CompatToolsDataProvider {

  final int _kEndOfEntryMark = 0x0800;
  final int _kEndOfCompToolsMark = 0x0808;

  Future<List<CompatTool>> loadExternalCompatTools() async {

    String homeFolder = FileTools.getHomeFolder();
    String path = "$homeFolder/.local/share/Steam/compatibilitytools.d";
    var compatToolFolders =  await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false);

    List<CompatTool> compatTools = [];
    //Read manifests
    for(int i=0; i<compatToolFolders.length; ++i) {
      var e = compatToolFolders[i];
      var fullPath = p.join(p.join(path, e),"compatibilitytool.vdf");
      File f = File(fullPath);
      String json = await f.readAsString();

      RegExp r = RegExp(r'"compatibilitytools"\n{\s+"compat_tools"\n\s+{\n\s+"(.*)".*\n\s+{[\S\s]*"display_name"\s+"([a-zA-Z0-9-_ ]+)"');
      var match = r.firstMatch(json);

      if(match==null) throw Exception("Error reading compat tool manifest for $fullPath");

      compatTools.add(CompatTool(match.group(1)!, match.group(2)!,false));

    };

    return compatTools;
  }

  Future<List<CompatTool>> loadInternalCompatTools() async {
    BinaryVdfBuffer buffer = BinaryVdfBuffer("/home/hexdump/.local/share/Steam/appcache/appinfo.vdf");

    int pos = buffer.findStringInBuffer("compat_tools");
    if(pos==-1) return [];

    buffer.seek(pos);
    buffer.seek("compat_tools".length+1, relative: true); //+1 because of string end flag 00
    buffer.seek(1, relative: true); //Skip list 00 code

    List<CompatTool> compatTools = [];

    while(!_isEndOfCompatTools(buffer))
    {
      compatTools.add(await _loadInternalCompatToolEntry(buffer));
    }

    return compatTools;
  }

  Future<CompatTool> _loadInternalCompatToolEntry(BinaryVdfBuffer buffer) async {

    String compatToolCode = buffer.readString();
    String compatToolName = "";
    bool unlisted = false;

    bool isEndOfEntry = _isEndOfEntry(buffer);
    bool isEndOfCompatTools = _isEndOfCompatTools(buffer);

    while(!isEndOfEntry && !isEndOfCompatTools) {
      Tuple2<String, dynamic> property = buffer.readProperty();
      if(property.item1 == "display_name") {
        compatToolName = property.item2;
      }
      else if (property.item1=="unlisted") {
        unlisted = _convertIntToBool(property.item2);
      }

      isEndOfEntry = _isEndOfEntry(buffer);
      isEndOfCompatTools = _isEndOfCompatTools(buffer);
    }

    //skip end of entry mark + by
    if(isEndOfEntry) {
      buffer.seek(2,relative: true);
    }

    return CompatTool(compatToolCode, compatToolName, unlisted);
  }

  bool _isEndOfEntry(BinaryVdfBuffer buffer) {
    int val = buffer.readUint16(Endian.big);
    buffer.seek(-2,relative:true);
    return val == _kEndOfEntryMark;
  }

  bool _isEndOfCompatTools(BinaryVdfBuffer buffer) {
    int val = buffer.readUint16(Endian.big);
    buffer.seek(-2,relative:true);
    return val == _kEndOfCompToolsMark;
  }

  bool _convertIntToBool(propertyValue) {
    return propertyValue == 0 ? false:true;
  }


}