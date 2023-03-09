import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

class BinaryBufferReader {
  @protected
  late final Uint8List _buffer;
  @protected
  int _pointerPos = 0;

  BinaryBufferReader(Uint8List buffer) {
    _buffer = buffer;
  }

  //TODO: All sync? and... how to close file? I guess it will be closed when it gets out of scope
  BinaryBufferReader.fromFilePath(String path) {
    File file = File(path); //TODO: How to close file
    if (!file.existsSync()) {
      throw NotFoundException("Vdf file not found: $path");
    }

    _buffer = file.readAsBytesSync();
  }

  int getSize() {
    return _buffer.length;
  }

  void seek(int pos, {bool relative = false}) {
    if (relative) {
      if (_pointerPos + pos >= getSize() || _pointerPos + pos < 0) {
        throw IndexError(pos, _buffer);
      }
      _pointerPos += pos;
    } else {
      if (pos >= getSize()) {
        throw IndexError(pos, _buffer);
      }
      _pointerPos = pos;
    }
  }

  //IF not found pointer doesn't move
  bool seekToString(String s) {
    var pos = findStringInBuffer(s);
    if(pos>=0) {
      _pointerPos = pos;
      return true;
    }
    else {
      return false;
    }
  }

  int getCurrentPointerPos() {
    return _pointerPos;
  }

  int findStringInBuffer(String s) {
    var bytes = Uint8List.fromList(utf8.encode(s));
    return findBytesInBuffer(bytes);
  }

  //Returns -1 if no hit. Doesn't move the file pointer
  int findBytesInBuffer(Uint8List bytes) {
    var currentFilePos = getCurrentPointerPos();
    var found = false;

    while (!found && getCurrentPointerPos() < getSize()) {
      found = compareBytesWithBuffer(bytes);

      if (!found) seek(1, relative: true);
    }

    //Rollback position
    var finalPos = _pointerPos;
    _pointerPos = currentFilePos;

    return found ? finalPos : -1;
  }

  //Doesn't move file pointer
  bool compareBytesWithBuffer(Uint8List bytes) {
    var currentFilePos = getCurrentPointerPos();
    var index = 0;
    var equal = true;

    //Not enough bytes to compare so it is not equal
    if (currentFilePos + bytes.length >= getSize()) return false;

    while (equal && index < bytes.length) {
      if (readByte() != bytes[index]) {
        equal = false;
      } else {
        index += 1;
      }
    }

    //Rollback pointer
    seek(currentFilePos);

    return equal;
  }

  int peekByte() {
    return _buffer[_pointerPos];
  }

  List<int> peekXBytes(int bytesToPeek) {
    List<int> bytes = [];

    var counter = _pointerPos;
    var i=0;

    if(counter+bytesToPeek>_buffer.length) {
      bytesToPeek = _buffer.length-counter;
    }

    bytes.addAll(_buffer.getRange(counter, counter+bytesToPeek));

    return bytes;
  }

  int readByte() {
    return _buffer[_pointerPos++];
  }

  //This function does not check if there's data available while reading
  String readString() {
    String str = "";

    //Search end of string
    var endOfString = _pointerPos;
    while (_buffer[endOfString] != 0) {
      if (endOfString >= _buffer.length) throw Exception("EOF while reading a string");
      ++endOfString;
    }

    //str= utf8.decode(String.fromCharCodes(buffer,index,endOfString).runes.toList());
    Uint8List subView = Uint8List.sublistView(_buffer, _pointerPos, endOfString);
    str = utf8.decode(subView);

    _pointerPos = endOfString;

    //We need to consume last 0 if no end of buffer
    if (_pointerPos < _buffer.length) {
      _pointerPos += 1;
    }

    return str;
  }

  int readUint32(Endian endian) {
    int byte0 = readByte();
    int byte1 = readByte();
    int byte2 = readByte();
    int byte3 = readByte();

    return endian == Endian.little ? byte0 | byte1 << 8 | byte2 << 16 | byte3 << 24 : byte0 << 24 | byte1 << 16 | byte2 << 8 | byte3;
  }

  int readUint16(Endian endian) {
    int byte0 = readByte();
    int byte1 = readByte();

    return endian == Endian.little ? byte0 | byte1 << 8 : byte0 << 8 | byte1;
  }
}
