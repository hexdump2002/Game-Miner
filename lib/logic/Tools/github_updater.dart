import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class Release {
    String name;
    String url;
    String tagName;
    String body;
    Release(this.name, this.tagName, this.body, this.url);
}

class GithubUpdater {
    late Uri url;

    GithubUpdater(String owner, String repo) {
        url = Uri.https("api.github.com", "repos/$owner/$repo/releases");
    }

    Future<List<Release>> getReleases() async {
        List<Release> releases = [];
        final response = await http.get(url);

        if (response.statusCode == 200) {
            var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
            for(Map<String,dynamic> obj in decodedResponse) {
                if(obj['prerelease'] == false && obj['draft'] == false && (obj['assets'] as List).isNotEmpty) {
                  releases.add(Release(obj['name'], obj['tag_name'], obj['body'], obj['assets'][0]['browser_download_url']));
                }
            }
        } else {
            // If that call was not successful, throw an error.
            print('Error connectionto github to check last release');
        }

        return releases;
    }

    Future<Release?> getLastRelease() async {
        List<Release> releases =  await getReleases();
        if(releases.isNotEmpty) return releases[0];

        return null;
    }

    //Returns null if there's a new version, false otherwise
    Future<Release?> checkForUpdates() async{
        try {
            PackageInfo packageInfo = await PackageInfo.fromPlatform();
            String version = packageInfo.version;
            Release? r = await getLastRelease();
            if (r != null) {
                String githubVersion = r.tagName.substring(1);
                List<int> appVersionParts = version.split(".").map<int>((e) => int.parse(e)).toList();
                List<int> githubVersionParts = githubVersion.split(".").map<int>((e) => int.parse(e)).toList();
                if (appVersionParts[0] < githubVersionParts[0]) {
                  return r;
                }
                else if(appVersionParts[0] == githubVersionParts[0] && appVersionParts[1] < githubVersionParts[1]) {
                    return r;
                }
                else if(appVersionParts[0] == githubVersionParts[0] && appVersionParts[1] == githubVersionParts[1] && appVersionParts[2] < githubVersionParts[2]) {
                    return r;
                }
            }
        }
        catch(ex) {
            print(ex);
        }

        return null;
    }

    Future<bool> downLoadRelease(Release r, String downloadPath, void Function (double) progressCallback) async {
        /*try {
            var response = await http.get(Uri.parse(r.url));
            await io.File(downloadPath).writeAsBytes(response.bodyBytes);
            return true;
        }
        catch(ex) {
            print(ex);
        }

        return false;*/

        var received = 0;
        final client = http.Client();
        http.StreamedResponse response = await client.send(http.Request("GET", Uri.parse(r.url)));

        if(response.contentLength==null || response.contentLength==0) return false;

        int length = response.contentLength!;
        File downloadFile = File(downloadPath);
        var sink = downloadFile.openWrite();

        await response.stream.map((s) {
            received += s.length;
            double normalizedProgress = received/length;
            if(normalizedProgress>1.0) normalizedProgress = 1.0;
            progressCallback(normalizedProgress);
            return s;
        }).pipe(sink);

        return true;

    }
}

