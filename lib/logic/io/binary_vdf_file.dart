import 'dart:io';
import 'dart:math';

import 'package:universal_disk_space/universal_disk_space.dart';

class BinaryVdfFile {
  final String _path;
  late final File _file;
  RandomAccessFile? _raf;

  BinaryVdfFile(String path) : _path=path {
    _file = File(_path);
    if (!_file.existsSync()) {
      throw NotFoundException("Vdf file not found: $path");
    }
  }

  void open() async {
    _raf ??= await _file.open();
  }

  void close() async {
    if(_raf != null) {
      await _raf!.close();
    }
  }

  //TODO: Check extensions to see if we could add the other methods
  Future<void> writeByte(int byte) async{
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");
    RandomAccessFile raf = _raf!;

    await raf.writeByte(byte);
  }

  Future<void> writeString(String str) async{
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");
    RandomAccessFile raf = _raf!;

    await raf.writeString(str);
  }

  Future<void> writeStringProperty(String propName, String propValue, {bool addQuotes = false}) async {
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");

    RandomAccessFile raf = _raf!;

    await raf.writeByte(0x01);
    await raf.writeString(propName);
    await raf.writeByte(0);

    if(propValue.isNotEmpty && addQuotes) {
      propValue = "\"$propValue\"";
    }
    await raf.writeString(propValue);
    await raf.writeByte(0);
  }

  Future<void> writeInt32BEProperty(String propName, int value) async {
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");

    RandomAccessFile raf = _raf!;

    await raf.writeByte(0x02);

    await raf.writeString(propName);
    await raf.writeByte(0);

    await raf.writeByte((value & 0x000000FF));
    await raf.writeByte((value & 0x0000FF00) >> 8);
    await raf.writeByte((value & 0x00FF0000) >> 16);
    await raf.writeByte((value & 0xFF000000) >> 24);
  }

  Future<void> writeBoolProperty(String propName, bool value) async {
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");

    RandomAccessFile raf = _raf!;

    int intValue = value ? 1 : 0;
    await writeInt32BEProperty(propName, intValue);
  }

  Future<void> writeListProperty(String propName, List<String> tags) async {
    if(_raf == null) throw Exception("Can't write to $_path because file is not opened");

    RandomAccessFile raf = _raf!;

    await raf.writeByte(0x00);
    await raf.writeString(propName);
    await raf.writeByte(0);
    for(int i=0; i<tags.length; ++i) {
      await raf.writeByte(0x01); //more items comming?
      await raf.writeString(i.toString());
      await raf.writeByte(0);
      await raf.writeString(tags[i]);
      await raf.writeByte(0);
    }

  }
}