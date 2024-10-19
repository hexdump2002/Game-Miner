

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

  static final int kAPPINFO_29 = 0x107564427;
  static final int kAPPINFO_28 = 0x107564428;

  final List<int> _supportedVersions = [kAPPINFO_28, kAPPINFO_29];

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

  // Hack to extract compat tools
  Future<List<CompatTool>> loadInternalCompatTools() async {
    List<CompatTool> compatTools = [];

    List<String> validCompToolsPrefixes = ['proton_', 'steamlinuxruntime_'];

    String path = "${SteamTools.getSteamBaseFolder()}/appcache/appinfo.vdf";
    BinaryVdfBuffer buffer = BinaryVdfBuffer(path);

    int fileVersion = buffer.readUint64(Endian.little);

    //Check if we have a valid appinfo.vdf version
    /*if(!_supportedVersions.contains(fileVersion)) {
      throw new Exception("appcache/appinfo.df version $fileVersion is not valid");
    }*/

    int pos = buffer.findStringInBuffer("compat_tools");
    if(pos==-1) return [];

    buffer.seek(pos);
    buffer.seek("compat_tools".length+1, relative: true); //+1 because of string end flag 00

    int bytesRead = 0;
    bool exit = false;

    while(bytesRead<512 || exit) {
      try {
        String protonToolCandidate = buffer.readString();

        if (validCompToolsPrefixes.any((prefix) => protonToolCandidate.startsWith(prefix))) {
          //Valid! -> split name to format it a bit and add it to the compatibility toolset
          compatTools.add(new CompatTool(protonToolCandidate, protonToolCandidate, false));
        }

        bytesRead += protonToolCandidate.length;
      }
      catch (e){
        print("There was an error reading appinfo.vdf compat tools. The error was: "+e.toString());
        exit = true;
      }
    }


    return compatTools;
  }




  //This is not working any more... steam changed the way compat_tools exist into appinfo.vdf and new format is pretty hard to swallow
  /*Future<List<CompatTool>> loadInternalCompatTools() async {
    String path = "${SteamTools.getSteamBaseFolder()}/appcache/appinfo.vdf";
    BinaryVdfBuffer buffer = BinaryVdfBuffer(path);

    int fileVersion = buffer.readUint64(Endian.little);

    //Check if we have a valid appinfo.vdf version
    if(!_supportedVersions.contains(fileVersion)) {
      throw new Exception("appcache/appinfo.df version $fileVersion is not valid");
    }

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


  //This is not working any more... steam changed the way compat_tools exist into appinfo.vdf and new format is pretty hard to swallow
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
  }*/

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