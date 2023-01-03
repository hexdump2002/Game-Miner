import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:game_miner/logic/io/binary_buffer_reader.dart';
import 'package:tuple/tuple.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

final Uint8List shortcutsValueTypeCode = Uint8List.fromList([0,1,2]); //0 for list, 1 for string, 2 for u32

class BinaryVdfBuffer extends BinaryBufferReader {

  BinaryVdfBuffer(String filePath) : super.fromFilePath(filePath);


  Tuple2<String, dynamic> readProperty() {

    //Get 1 byte with the type of property. Little endian
    var propertyType = readByte();

    var propertyName = readString();

    dynamic propertyValue;

    switch (propertyType)  {
      case 0x00:
        {
          propertyValue= readList();
        } break;
      case 0x01:
        {
          propertyValue = readString();
        } break;
      case 0x02:
        {
          propertyValue = readUint32(Endian.little);
        } break;
      default:
        assert(false, "Unknown vdf value type");
    }

    return Tuple2(propertyName, propertyValue);
  }


  List<String>readList() {

    bool finish = false;
    List<String> tags = [];

    while(!finish) {
      if(readByte()!=01) {
        finish=true;
        //roll back byte
        seek(-1,relative: true);
      }
      else {
        //Skip firstbyte that should be a 01 (I guess it means more data comes)
        seek(1, relative: true);

        //Read string (list index)
        String stringTuple = readString();

        //Read string (tag value for example)
        String tagValue = readString();

        tags.add(tagValue);
      }
    }

    return tags;
  }





}