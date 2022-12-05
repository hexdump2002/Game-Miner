import 'file_tools.dart';

class SteamTools {

  static Future<List<String>> loadManuallyInstalledProtons() async {
    late final List<String> protons;

    String homeFolder = FileTools.getHomeFolder();
    String shortcutsFilePath = "$homeFolder/.local/share/Steam/compatibilitytools.d";
    protons =
    await FileTools.getFolderFilesAsync(shortcutsFilePath, retrieveRelativePaths: true, recursive: false);

    protons.sort();

    return protons;

  }

  static Future<List<String>> loadProtons() async {
    List<String>  builtInProtons = ["Proton Experimental", "Pronto 6.2", "Proton 5.1"];
    List<String> protons = await loadManuallyInstalledProtons();
    protons.addAll(builtInProtons);

    protons.sort();

    return protons;
  }

}