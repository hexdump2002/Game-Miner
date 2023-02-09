

import 'dart:io';
import 'dart:typed_data';

import 'package:game_miner/data/models/compat_tool.dart';
import 'package:game_miner/logic/Tools/steam_tools.dart';
import 'package:game_miner/logic/io/text_vdf_file.dart';
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

    String path = "${SteamTools.getSteamBaseFolder()}/compatibilitytools.d";
    var compatToolFolders =  await FileTools.getFolderFilesAsync(path, retrieveRelativePaths: true, recursive: false, onlyFolders: true);

    List<CompatTool> compatTools = [];

    if(compatToolFolders != null) {
      //Read manifests
      for (int i = 0; i < compatToolFolders.length; ++i) {
        var e = compatToolFolders[i];
        var fullPath = p.join(p.join(path, e), "compatibilitytool.vdf");
        TxtVdfFile file = TxtVdfFile();
        await file.open(fullPath, FileMode.read);
        Map<String, dynamic> data = await file.read();
        String compatToolCode = data['compatibilitytools']['compat_tools'].keys.first;
        String compatToolDisplayName = data['compatibilitytools']['compat_tools'][compatToolCode]['display_name'];

        if (compatToolCode.isEmpty || compatToolDisplayName.isEmpty) throw Exception("Error reading compat tool manifest for $fullPath");

        compatTools.add(CompatTool(compatToolCode, compatToolDisplayName, false));
      };
    }

    return compatTools;
  }

  Future<List<CompatTool>> loadInternalCompatTools() async {
    String path = "${SteamTools.getSteamBaseFolder()}/appcache/appinfo.vdf";
    BinaryVdfBuffer buffer = BinaryVdfBuffer(path);

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