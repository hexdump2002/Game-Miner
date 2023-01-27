import 'dart:io';
import 'package:collection/collection.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

class TxtVdfFile {
  late final File _file;
  final int doubleQuoteChar = "\"".codeUnitAt(0);
  final int scapedCharSymbol ="\\".codeUnitAt(0);
  final int openBrace = "{".codeUnitAt(0);
  final int closingBrace = "}".codeUnitAt(0);

  final List<int> _emptyCodeUnits = [" ".codeUnitAt(0), "\t".codeUnitAt(0), "\n".codeUnitAt(0)];

  String _text="";

  int _filePos = 0;

  Future<void> open(String path, FileMode mode) async {

    _file = File(path);

    if (mode == FileMode.read && !_file.existsSync()) {
      throw NotFoundException("Vdf file not found: $path");
    }

    await _file.open(mode: mode);
  }

  Future<CanonicalizedMap<String,String,dynamic>> read() async {
    var m = CanonicalizedMap<String,String,dynamic>((key) => key.toLowerCase());
    _text= await _file.readAsString();

    if(_text.isEmpty) throw Exception("File ${_file.path} has invalid format");


    return _readObject(m);
  }

  void close() {
  }

  //Expected the point to be on '{' char
  CanonicalizedMap<String,String, dynamic> _readObjectProperties() {
    consume(char: openBrace);

    CanonicalizedMap<String,String, dynamic> object= CanonicalizedMap((key) => key.toLowerCase());

    while(!_isEndOfObject()) {
      bool isObjectProperty = _isNextObjectProperty();
      int savedFilePos = _filePos;
      String propName = _readString();
      if(isObjectProperty) {
        _filePos = savedFilePos;
        Map<String, dynamic> o = _readObject(CanonicalizedMap((key) => key.toLowerCase()));
        object[propName] = o[propName];
      }
      else {
        String value = _readString();
        object[propName] = value;
      }
    }

    return object;
  }


  CanonicalizedMap<String,String, dynamic> _readObject(CanonicalizedMap<String,String, dynamic> outputMap) {

    String key = _readString();

    int savedPos = _filePos;

    _findNextNotEmptyChar();
    peek(char: openBrace);

    CanonicalizedMap<String,String, dynamic> objProperties = _readObjectProperties();

    outputMap[key] = objProperties;

    _findNextNotEmptyChar();

    consume(char: closingBrace);

    return outputMap;
  }

  bool _isMoreDataToRead() {
    var savedPos = _filePos;
    bool moreData=  _findNextNotEmptyChar();
    _filePos = savedPos;
    return moreData;
  }

  //Is next property and object property?
  bool _isNextObjectProperty() {
    _findNextNotEmptyChar();
    int savedFilePos = _filePos;
    _readString();
    _findNextNotEmptyChar();
    bool isObjProperty =  peek()==openBrace;
    _filePos = savedFilePos;
    return isObjProperty;
  }

  bool _isEndOfObject() {
    int savedFilePos = _filePos;
    _findNextNotEmptyChar();
    bool eoo = peek() == closingBrace;
    _filePos = savedFilePos;
    return eoo;
  }

  int peek({int char=-1}) {
    if(char!=-1 && (peek()!=char)) {
      throw Exception("Character $char is not found at position $_filePos");
    }
    return _text.codeUnitAt(_filePos);
  }

  int consume( {int char=-1}) {
    if(char!=-1 && (peek()!=char)) {
      throw Exception("Character $char is not found at position $_filePos");
    }

    return _text.codeUnitAt(_filePos++);
  }

  bool isCharEmpty(int char) {
    return  !_emptyCodeUnits.contains(char);
  }

  //Returns false if EOF, true if more data comes. If false returned the _filePos pointer is undefined
  bool _findNextNotEmptyChar() {
    bool found = false;
    int char = 0;

    _filePos -=1;

    do {
      ++_filePos;
      if(_filePos >= _text.length-1) return false;
      char = peek();
    }while(!isCharEmpty(char));

    return true;
  }


  String _readString() {
    _findNextNotEmptyChar();

    String str = "";
    consume(char:doubleQuoteChar);

    bool finished = false;
    while(!finished) {
      if(peek() == scapedCharSymbol){
        //Consume both chars, the scaped flag and the char
        str+= String.fromCharCode(consume());
        str+= String.fromCharCode(consume());
      }
      else
      {
        if(peek() == doubleQuoteChar) {
          consume(char:doubleQuoteChar);
          finished = true;
        }
        else
        {
          str+=String.fromCharCode(consume());
        }
      }
    }



    return str;
  }

  Future<void> write(CanonicalizedMap<String,String, dynamic> data) async {
    StringBuffer buffer = StringBuffer();
    _buildStringToWrite(data, 0, buffer);
    String dataString = buffer.toString();
    await _file.writeAsString(dataString);
  }

  StringBuffer _buildStringToWrite(CanonicalizedMap<String,String,dynamic> data, int indentation, StringBuffer buffer) {

    for(String key in data.keys){
      if(data[key] is! Map ){
        buffer.write(getIndentationString(indentation));
        buffer.write("\"$key\"");
        buffer.write("\t\t");
        buffer.write("\"${data[key]}\"\n");
      }
      else {
        buffer.write(getIndentationString(indentation));
        buffer.write("\"$key\"\n");
        buffer.write(getIndentationString(indentation));
        buffer.write("{\n");
        buffer = _buildStringToWrite(data[key], indentation + 1, buffer);
        buffer.write(getIndentationString(indentation));
        buffer.write("}\n");
      }
    }
    return buffer;

  }

  String getIndentationString(int indentation)
  {
    StringBuffer indentationString = StringBuffer();
    for(int i=0; i<indentation; ++i) {
      indentationString.write("\t");
    }
    return indentationString.toString();
  }

}