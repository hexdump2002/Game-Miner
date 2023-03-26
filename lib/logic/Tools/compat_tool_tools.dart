import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/models/compat_tool.dart';

class CompatToolTools {
  static const String notInUseCode = "no_use";
  static const String notAssigned = "not_assigned";

  static List<String> getAvailableCompatToolDisplayNames(List<CompatTool> compatTools) {
    List<String> ctn = compatTools.map<String>((e) => e.displayName).toList();
    ctn.insert(0, tr(notInUseCode));
    ctn.insert(0, tr(notAssigned));

    return ctn;
  }

  static String getCompatToolDisplayNameFromCode(String code, List<CompatTool> compatTools) {
    if (code.isEmpty || code == notAssigned) return tr(notAssigned);
    if (code == notInUseCode) return tr(notInUseCode);
    CompatTool? ct = compatTools.firstWhereOrNull((element) => element.code == code);
    if (ct == null) return tr(notAssigned);

    return ct.displayName;
  }

  static String getCompatToolCodeFromDisplayName(String displayName, List<CompatTool> compatTools) {
    if (displayName == tr(notAssigned)) return notAssigned;
    if (displayName == tr(notInUseCode)) return notInUseCode;

    CompatTool? ct = compatTools.firstWhereOrNull((element) => element.displayName == displayName);
    if (ct == null) return notInUseCode;

    return ct.code;
  }
}