
//ordered as ShortcutsValueType enum
import 'dart:ffi';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

final Uint8List shortcutsValueTypeCode = Uint8List.fromList([0,1,2]); //0 for list, 1 for string, 2 for u32
final Uint8List kEntry_End_Mark = Uint8List.fromList([00,0x74,0x61,0x67,0x73,0x00,0x08,0x08]);

class UserGameExe {
  late final bool added;
  late final bool brokenLink;
  late final String relativeExePath;
}


class NonSteamGame {
  String entryId = "";
  String appId = "";
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
  String lastPlayTime = "";
  String flatPackAppId = "";

  NonSteamGame();

  factory  NonSteamGame.fromBuffer(Uint8List buffer, int from, bool consumeData) {
    var propertyName = "";

    var nsg = NonSteamGame();
    nsg._readEntry(buffer, from, consumeData);

    return nsg;
  }

  void _assignValue(String propertyName, String propertyValue)
  {
    switch(propertyName)
    {
      case "entry_id": {entryId = propertyValue;}break;
      case "appid" : {appId = propertyValue;}break;
      case "AppName"  : {appName = propertyValue;}break;
      case "StartDir" : {startDir = propertyValue;}break;
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
      case "LastPlayTime" : {lastPlayTime = propertyValue;}break;
      case "FlatpakAppID" : {flatPackAppId = propertyValue;}break;
      default: print("$propertyName with value $propertyValue is not a known steam game property");
    }
  }
  bool _convertStrToBool(String str)
  {
    return int.parse(str) == 1;
  }

  int _readEntry(Uint8List buffer, int from, bool consumeData) {
    var finished = false;
    var movingFrom = from;

    var tuple = _readString(buffer, from, consumeData);
    var entryId = tuple.item1;
    from = tuple.item2;

    print("Entry ID = $entryId");

    while (!finished) {
      var readPropertyRetVal = _readProperty(buffer, from,consumeData);
      _assignValue(readPropertyRetVal.item1, readPropertyRetVal.item2);
      movingFrom = readPropertyRetVal.item3;

      if (_isEndOfEntry(buffer,movingFrom)) {
        movingFrom += kEntry_End_Mark.length;
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
        propertyName = readStrRetVal.item1;
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

    while(equal && index<kEntry_End_Mark.length)
    {
      //println!("{:#x} {:#x} {:#x} {:#x}", from+index, buffer[from+index], index, ENTRY_END_MARK[index]);
      if (buffer[from+index] != kEntry_End_Mark[index]) { return false; }
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


/*


//ordered as ShortcutsValueType enum
import 'dart:ffi';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

final Uint8List shortcutsValueTypeCode = Uint8List.fromList([0,1,2]); //0 for list, 1 for string, 2 for u32
final Uint8List kEntry_End_Mark = Uint8List.fromList([00,0x74,0x61,0x67,0x73,0x00,0x08,0x08]);

class UserGameExe {
  late final bool added;
  late final bool brokenLink;
  late final String relativeExePath;
}


class NonSteamGame {
  String appId = "";
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
  String lastPlayTime = "";

  NonSteamGame();

  factory  NonSteamGame.fromBuffer(Uint8List buffer, int from, bool consumeData) {
    var propertyName = "";

    var nsg = NonSteamGame();
    //nsg._readEntry(buffer, from, consumeData);

/*match property_name {
            "entry_id" => {return nsg}
            "appid" => {return nsg}
            "AppName"  => {return nsg}
            "StartDir" => {return nsg}
            "icon" => {return nsg}
            "ShortcutPath" => {return nsg}
            "LaunchOptions" => {return nsg}
            "IsHidden" => {return nsg}
            "AllowDesktopConfig" => {return nsg}
            "AllowOverlay" => {return nsg}
            "OpenVR" => {return nsg}
            "Devkit" => {return nsg}
            "DevkitGameID" => {return nsg}
            "DevkitOverrideAppID" => {return nsg}
            "LastPlayTime" => {return nsg}
            "FlatpakAppID" => {return nsg}
            _ => {return nsg} //HANDLE THIS ERROR!
        }*/

    return nsg;
  }

  void _readEntry(Uint8List buffer, int from, bool consumeData) {
    var finished = false;

    var tuple = _readString(buffer, from, consumeData);
    var entryId = tuple.item1;
    from = tuple.item2;

    print("Entry ID = $entryId");

    while (!finished) {
      var prop = _readPproperty(buffer, from,consumeData);
      properties.insert(prop.0,prop.1);

      if self._is_end_of_entry(buffer,*from) {
        *from += ENTRY_END_MARK.len();
        finished = true;
      }
    }

    println!("{:?}", self.properties);
  }



  Tuple3<String, String, int> _readProperty(Int8List buffer, int from, bool consumeData) {

    //Get 1 byte with the type of property. Little endian
    let property_type = read_uint_le::<u8>(buffer,from, consume_data);

    match property_type  {
    0x01 => {
    let property = read_string_type(buffer, from, consume_data);
    Some(property)
    },
    0x02 =>  {
    let property = read_uint_type::<u32>(buffer, from, consume_data);
    Some((property.0, property.1.to_string()))
    },
    _ => panic!("Unknown vdf value type")
    }
  }

/*
pub fn _is_end_of_entry(&mut self, buffer:&Vec<u8>, from:usize) -> bool {

let mut index = 0;
let equal = true;

while(equal && index<ENTRY_END_MARK.len())
{
//println!("{:#x} {:#x} {:#x} {:#x}", from+index, buffer[from+index], index, ENTRY_END_MARK[index]);
if buffer[from+index] != ENTRY_END_MARK[index] { return false; }
index+=1;
}

return true;

}
*/


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
 */