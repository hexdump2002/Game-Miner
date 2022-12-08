
//ordered as ShortcutsValueType enum
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

final Uint8List shortcutsValueTypeCode = Uint8List.fromList([0,1,2]); //0 for list, 1 for string, 2 for u32
final Uint8List k_entry_end_mark = Uint8List.fromList([00,0x74,0x61,0x67,0x73,0x00,0x08,0x08]);


class NonSteamGameExe {

  String entryId = "";
  int appId = 0;
  String appName = "";
  String startDir = "";
  String icon = "";
  String shortcutPath = "";
  String launchOptions = "";
  bool isHidden = false;
  bool allowDdesktopCconfig = false;
  bool allowOverlay = false;
  bool openVr = false;
  bool devkit = false;
  String devkitGameId = "";
  String devkitOverrideAppId = "";
  int lastPlayTime = 0;
  String flatPackAppId = "";
  String exePath = "";

  NonSteamGameExe();

  static Tuple2<NonSteamGameExe, int>  fromBuffer(Uint8List buffer, int from, bool consumeData) {
    var propertyName = "";

    var nsg = NonSteamGameExe();
    from = nsg._readEntry(buffer, from, consumeData);

    return Tuple2(nsg, from);
  }

  void _assignValue(String propertyName, String propertyValue)
  {
    switch(propertyName)
    {
      case "entry_id": {entryId = propertyValue;}break;
      case "appid" : {appId = _convertBEIntStringToInt(propertyValue);}break;
      case "AppName"  : {appName = propertyValue;}break;
      case "StartDir" : {startDir = _cleanPathString(propertyValue);}break;
      case "icon" : {icon = propertyValue;}break;
      case "ShortcutPath" : {shortcutPath = propertyValue;}break;
      case "LaunchOptions" : {launchOptions = propertyValue;}break;
      case "IsHidden" : {isHidden = _convertStrToBool(propertyValue);}break;
      case "AllowDesktopConfig" : {allowDdesktopCconfig = _convertStrToBool(propertyValue);}break;
      case "AllowOverlay" : {allowOverlay = _convertStrToBool(propertyValue);}break;
      case "OpenVR" : {openVr = _convertStrToBool(propertyValue);}break;
      case "Devkit" : {devkit = _convertStrToBool(propertyValue);}break;
      case "DevkitGameID" : {devkitGameId = propertyValue;}break;
      case "DevkitOverrideAppID" : {devkitOverrideAppId = propertyValue;}break;
      case "LastPlayTime" : {lastPlayTime = _convertBEIntStringToInt(propertyValue);}break;
      case "FlatpakAppID" : {flatPackAppId = propertyValue;}break;
      case "Exe" : { propertyValue = _cleanPathString(propertyValue); exePath = propertyValue;}break;
      default: throw Exception("$propertyName with value $propertyValue is not a known steam game property");
    }
  }
  
  int _convertBEIntStringToInt(String value) {
    return int.parse(value);
  }
  
  String _cleanPathString(String str)
  {
    if(str.startsWith("\"")) str=str.substring(1,str.length);
    if(str.endsWith("\"")) str=str.substring(0,str.length-1);
    return str;
  }
  
  bool _convertStrToBool(String str)
  {
    if(int.parse(str)!=1 && int.parse(str)!=0) throw  FormatException("Str does not contain a convertible bool");

    return int.parse(str) == 1;
  }

  int _readEntry(Uint8List buffer, int from, bool consumeData) {
    var finished = false;
    var movingFrom = from;

    var tuple = _readString(buffer, movingFrom, consumeData);
    var entryId = tuple.item1;
    movingFrom = tuple.item2;

    print("Entry ID = $entryId");

    while (!finished) {
      var readPropertyRetVal = _readProperty(buffer, movingFrom,consumeData);
      _assignValue(readPropertyRetVal.item1, readPropertyRetVal.item2);
      movingFrom = readPropertyRetVal.item3;

      if (_isEndOfEntry(buffer,movingFrom)) {
        movingFrom += k_entry_end_mark.length;
        finished = true;
      }
    }

    if(consumeData) from = movingFrom;

    return from;
  }



  Tuple3<String, String, int> _readProperty(Uint8List buffer, int from, bool consumeData) {

    var movingFrom = from;

    var dataView = ByteData.sublistView(buffer);

    //Get 1 byte with the type of property. Little endian
    var propertyType = dataView.getUint8(movingFrom);
    ++movingFrom;

    var readStrRetVal = _readString(buffer, movingFrom, consumeData);
    movingFrom = readStrRetVal.item2;
    var propertyName = readStrRetVal.item1;

    var propertyValue = "";

    switch (propertyType)  {
      case 0x01:
      {
        var readStrRetVal = _readString(buffer, movingFrom, consumeData);
        movingFrom = readStrRetVal.item2;
        propertyValue = readStrRetVal.item1;
      } break;
      case 0x02:
      {
        var value = dataView.getUint32(movingFrom,Endian.little);
        movingFrom += 4;
        propertyValue = value.toString();
      } break;
      default:
        assert(false, "Unknown vdf value type");
    }

    if(consumeData) from = movingFrom;

    return Tuple3(propertyName, propertyValue, movingFrom);
  }


  bool _isEndOfEntry(Uint8List buffer, int from){

    var index = 0;
    var equal = true;

    while(equal && index<k_entry_end_mark.length)
    {
      //println!("{:#x} {:#x} {:#x} {:#x}", from+index, buffer[from+index], index, ENTRY_END_MARK[index]);
      if (buffer[from+index] != k_entry_end_mark[index]) { return false; }
      index+=1;
    }

    return true;

  }



  //This function does not check if there's data available while reading
  Tuple2<String,int> _readString(Uint8List buffer, int from, bool consumeData ) {
    String str = "";

    var index = from;
    while (buffer[index]!=0 && index<buffer.length) {
      str+= String.fromCharCode(buffer[index]);
      index+=1;
    }

    //We need to consume last 0 if no end of buffer
    if (index<buffer.length)  { index+=1; }

    if (consumeData) { from = index;}

    return Tuple2(str, from);
  }
}
