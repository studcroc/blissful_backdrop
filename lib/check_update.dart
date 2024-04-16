import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:version/version.dart';
import 'package:path/path.dart' as path;

var latestAppVersionStr = '';

Future<void> checkForAppUpdate(BuildContext context) async {
  if (await appUpdateAvailable()) {
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => const AppUpdater(),
    );
  }
}

Future<bool> appUpdateAvailable() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String currentAppVersionStr = packageInfo.version;

  Version currentAppVersion = Version.parse(currentAppVersionStr);

  http.Response response = await http.get(Uri.parse(
      "https://api.github.com/repos/hvg2416/blissful_backdrop/releases"));

  latestAppVersionStr = jsonDecode(response.body)[0]['tag_name'];

  Version latestAppVersion = Version.parse(latestAppVersionStr.substring(1));

  int compareRes = currentAppVersion.compareTo(latestAppVersion);

  return compareRes < 0;
}

Future<String> downloadAppUpdate() async {
// Download the latest executable
  final response = await http.get(Uri.parse(
      "https://github.com/hvg2416/blissful_backdrop/releases/download/$latestAppVersionStr/blissful_backdrop.exe"));
  final bytes = response.bodyBytes;
  final appDir = await getTemporaryDirectory();
  final filePath = '${appDir.path}/blissful_backdrop.exe';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  return filePath;
}

class AppUpdater extends StatefulWidget {
  const AppUpdater({super.key});

  @override
  State<AppUpdater> createState() => _AppUpdaterState();
}

class _AppUpdaterState extends State<AppUpdater> {
  bool isUpdatingApp = false;

  Future<void> updateApp() async {
    setState(() {
      isUpdatingApp = true;
    });

    String executablePath = await downloadAppUpdate();
    String updateBatFilePath = path.join("bin", "update.bat");

    if (kReleaseMode) {
      final scriptDir = path.dirname(Platform.script.toFilePath());
      updateBatFilePath =
          path.join(scriptDir, 'data', 'flutter_assets', 'bin', 'update.bat');
    }

    // Run the downloaded executable
    var res = Process.runSync(updateBatFilePath, [executablePath]);

    // Check the installation success
    if (res.exitCode != 0) {
      log('User dismissed the installer.');
    }

    setState(() {
      isUpdatingApp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Version Available'),
      content: Text(
          'A new version $latestAppVersionStr is available. Please update to enjoy the latest features.'),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await updateApp();
                Navigator.of(context).pop();
              },
              child: const Text('Update Now'),
            )
          ],
        ),
        if (isUpdatingApp)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: LinearProgressIndicator(),
          )
      ],
    );
  }
}
