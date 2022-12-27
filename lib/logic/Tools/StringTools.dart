import 'dart:math';

double logBase(num x, num base) => log(x) / log(base);

class StringTools {
  static String bytesToStorageUnity(int byteCount, {int precision = 2})
  {
    if(byteCount == 0) return "0 KB";

    var base = logBase(byteCount, 1024);
    var suffixes = ['', 'KB', 'MB', 'GB', 'TB'];

    String number = pow(1024, base - base.floor()).toStringAsFixed(precision);
    String suffix = suffixes[base.floor()];
    return  "$number $suffix";
  }

  static String cleanPathString(String str)
  {
    if(str.startsWith("\"")) str=str.substring(1,str.length);
    if(str.endsWith("\"")) str=str.substring(0,str.length-1);
    return str;
  }

  static String removeQuotes(String str)
  {
    if(str.startsWith("\"")) str=str.substring(1,str.length);
    if(str.endsWith("\"")) str=str.substring(0,str.length-1);
    return str;
  }

}