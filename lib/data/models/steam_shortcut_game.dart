import 'dart:typed_data';

import '../../logic/io/binary_vdf_buffer.dart';


class SteamShortcut {
  final Uint8List k_entry_end_mark = Uint8List.fromList([0x08,0x08]);


  String entryId = "";
  int appId = 0;
  String appName = "";
  String startDir = "";
  String icon = "";
  String shortcutPath = "";
  String launchOptions = "";
  bool isHidden = false;
  bool allowDesktopConfig = false;
  bool allowOverlay = false;
  bool openVr = false;
  bool devkit = false;
  String devkitGameId = "";
  int devkitOverrideAppId = 0;
  int lastPlayTime = 0;
  String flatPackAppId = "";
  String exePath = "";
  List<String> tags = [];

  static SteamShortcut  fromBinaryVdfEntry(BinaryVdfBuffer file) {
    var propertyName = "";

    var nsg = SteamShortcut();
    nsg._readEntry(file);

    return nsg;
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
      case "AllowDesktopConfig" :case "allowdesktopconfig": {allowDesktopConfig = _convertIntToBool(propertyValue);}break;
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

  void _readEntry(BinaryVdfBuffer file) {
    var finished = false;

    var entryId = file.readString();

    while (!finished) {
      var readPropertyRetVal = file.readProperty();
      _assignValue(readPropertyRetVal.item1, readPropertyRetVal.item2);

      if (_isShortcutsEndOfEntry(file)) {
        file.seek(k_entry_end_mark.length, relative: true);
        finished = true;
      }
    }
  }

  bool _isShortcutsEndOfEntry(BinaryVdfBuffer file){

    var currentFilePos = file.getCurrentPointerPos();
    var index = 0;
    var equal = true;

    while(equal && index<k_entry_end_mark.length)
    {
      //println!("{:#x} {:#x} {:#x} {:#x}", from+index, buffer[from+index], index, ENTRY_END_MARK[index]);
      if (file.readByte() != k_entry_end_mark[index]) {
        //Get back to the beginning
        file.seek(currentFilePos);
        return false;
      }
      index+=1;
    }

    //Get back to the beginning
    file.seek(currentFilePos);

    return true;

  }

  bool _convertIntToBool(propertyValue) {
    return propertyValue == 0 ? false:true;
  }

}