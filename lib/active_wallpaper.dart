import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveWallpaper extends StatefulWidget {
  const ActiveWallpaper({super.key});

  @override
  State<ActiveWallpaper> createState() => _ActiveWallpaperState();
}

class _ActiveWallpaperState extends State<ActiveWallpaper> {
  String? activeWallpaper;
  bool isImageFitTypeContain = false;

  @override
  void initState() {
    super.initState();

    getActiveWallpaper();
  }

  @override
  Widget build(BuildContext context) {
    if (activeWallpaper != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Currently Active Wallpaper',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: activeWallpaper!,
                    fit: isImageFitTypeContain ? BoxFit.contain : BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    child: SelectableText(
                      '$activeWallpaper',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isImageFitTypeContain = !isImageFitTypeContain;
                        });
                      },
                      mini: true,
                      tooltip: isImageFitTypeContain
                          ? 'Fit image to cover screen'
                          : 'Fit image within screen',
                      child: isImageFitTypeContain
                          ? const Icon(Icons.fullscreen_outlined)
                          : const Icon(Icons.fullscreen_exit_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("lib/assets/unhappy_cute_illustration.png"),
        const Text(
            "Please first set a wallpaper using this application and come back here to see more.")
      ],
    );
  }

  Future<void> getActiveWallpaper() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      activeWallpaper = prefs.getString("active_wallpaper");
    });
  }
}
