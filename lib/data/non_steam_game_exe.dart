
//ordered as ShortcutsValueType enum
import 'dart:convert';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

final Uint8List shortcutsValueTypeCode = Uint8List.fromList([0,1,2]); //0 for list, 1 for string, 2 for u32
final Uint8List k_entry_end_mark = Uint8List.fromList([0x08,0x08]);


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
  int devkitOverrideAppId = 0;
  int lastPlayTime = 0;
  String flatPackAppId = "";
  String exePath = "";
  List<String> tags = [];

  NonSteamGameExe();

  static Tuple2<NonSteamGameExe, int>  fromBuffer(Uint8List buffer, int from, bool consumeData) {
    var propertyName = "";

    var nsg = NonSteamGameExe();
    from = nsg._readEntry(buffer, from, consumeData);

    return Tuple2(nsg, from);
  }

  void _assignValue(String propertyName, dynamic propertyValue)
  {
    switch(propertyName)
    {
      case "entry_id": {entryId = propertyValue;}break;
      case "appid" :case "AppId": {appId = propertyValue;}break;
      case "AppName":case "appname": {appName = propertyValue;}break;
      case "StartDir" :case "startdir": {startDir = /*_cleanPathString(*/propertyValue/*)*/;}break;
      case "Icon": case "icon" : {icon = /*_removeQuotes(*/propertyValue/*)*/;}break;
      case "shortcutpath": case "ShortcutPath" : {shortcutPath = propertyValue;}break;
      case "launchoptions": case "LaunchOptions" : {launchOptions = /*_removeQuotes(*/propertyValue/*)*/;}break;
      case "ishidden": case "IsHidden" : {isHidden = _convertIntToBool(propertyValue);}break;
      case "AllowDesktopConfig" :case "allowdesktopconfig": {allowDdesktopCconfig = _convertIntToBool(propertyValue);}break;
      case "AllowOverlay" :case "allowoverlay": {allowOverlay = _convertIntToBool(propertyValue);}break;
      case "OpenVR" :case "openvr": {openVr = _convertIntToBool(propertyValue);}break;
      case "Devkit" :case "devkit": {devkit = _convertIntToBool(propertyValue);}break;
      case "DevkitGameID" :case "devkitgameid": {devkitGameId = propertyValue;}break;
      case "DevkitOverrideAppID" : case "devkitoverrideappid": {devkitOverrideAppId = propertyValue;}break;
      case "LastPlayTime" :case "lastplaytime": {lastPlayTime = propertyValue;}break;
      case "FlatpakAppID" :case "flatpakappid": {flatPackAppId = propertyValue;}break;
      case "Exe" : case "exe": { propertyValue = /*_cleanPathString(propertyValue);*/ exePath = propertyValue;}break;
      case "tags": {tags = propertyValue; } break;
      default: throw Exception("$propertyName with value $propertyValue is not a known steam game property");
    }
  }

  int _convertBEIntStringToInt(String value) {
    return int.parse(value);
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



  Tuple3<String, dynamic, int> _readProperty(Uint8List buffer, int from, bool consumeData) {

    var movingFrom = from;

    var dataView = ByteData.sublistView(buffer);

    //Get 1 byte with the type of property. Little endian
    var propertyType = dataView.getUint8(movingFrom);
    ++movingFrom;

    var readStrRetVal = _readString(buffer, movingFrom, consumeData);
    movingFrom = readStrRetVal.item2;
    var propertyName = readStrRetVal.item1;

    dynamic propertyValue;

    switch (propertyType)  {
      case 0x00:
      {
        Tuple2<List<String>,int> readListVal = _readList(buffer,movingFrom, consumeData);
        movingFrom = readListVal.item2;
        propertyValue = readListVal.item1;
      } break;
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
        propertyValue = value;
      } break;
      default:
        assert(false, "Unknown vdf value type");
    }

    if(consumeData) from = movingFrom;

    return Tuple3(propertyName, propertyValue, from);
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
    //Search end of string
    var endOfString = index;
    while (buffer[endOfString]!=0) {
      if(endOfString>=buffer.length) throw Exception("EOF while reading a string");
      ++endOfString;
    }

    //str= utf8.decode(String.fromCharCodes(buffer,index,endOfString).runes.toList());
    Uint8List subView = Uint8List.sublistView(buffer,index,endOfString);
    str = utf8.decode(subView);

    index=endOfString;

    //We need to consume last 0 if no end of buffer
    if (index<buffer.length)  { index+=1; }

    if (consumeData) { from = index;}

    return Tuple2(str, from);
  }

  Tuple2<List<String>,int> _readList(Uint8List buffer, int movingFrom, bool consumeData) {
    var index = movingFrom;


    bool finish = false;
    List<String> tags = [];

    while(!finish) {
      if(buffer[index]!=01) {
        finish=true;
      }
      else {
        //Skip firstbyte that should be a 01 (I guess it means more data comes)
        ++index;

        //Read string (list index)
        Tuple2<String, int> stringTuple = _readString(buffer, index, consumeData);
        index = stringTuple.item2;
        String indexValue = stringTuple.item1;

        //Read string (tag value)
        stringTuple = _readString(buffer, index, consumeData);
        index = stringTuple.item2;
        String tagValue = stringTuple.item1;

        tags.add(tagValue);
      }
    }

    if (consumeData) { movingFrom = index;}

    return Tuple2(tags, movingFrom);
  }

  bool _convertIntToBool(propertyValue) {
    return propertyValue == 0 ? false:true;
  }
}
