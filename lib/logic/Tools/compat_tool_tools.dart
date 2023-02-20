import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/models/compat_tool.dart';

class CompatToolTools {
  static List<String> getAvailableCompatToolDisplayNames(List<CompatTool> compatTools) {
    List<String> ctn = compatTools.map<String>((e) => e.displayName).toList();
    ctn.insert(0, tr("no_use"));
    ctn.insert(0, tr("not_assigned"));

    return ctn;
  }

  static String getCompatToolDisplayNameFromCode(String code, List<CompatTool> compatTools) {
    if (code.isEmpty || code == "not_assigned") return tr("not_assigned");
    if (code =="no_use") return tr("no_use");
    CompatTool? ct = compatTools.firstWhereOrNull((element) => element.code == code);
    if (ct == null) return tr("not_assigned");

    return ct.displayName;
  }

  static String getCompatToolCodeFromDisplayName(String displayName, List<CompatTool> compatTools) {
    if (displayName == tr("not_assigned")) return "not_assigned";
    if (displayName == tr("no_use")) return "no_use";

    CompatTool? ct = compatTools.firstWhereOrNull((element) => element.displayName == displayName);
    if (ct == null) return "not_assigned";

    return ct.code;
  }
}