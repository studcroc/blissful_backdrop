import 'dart:io';

import 'macos_wallpaper_platform.dart';
import 'wallpaper_platform.dart';
import 'windows_wallpaper_platform.dart';

/// Returns the appropriate [WallpaperPlatform] for the current platform.
WallpaperPlatform createWallpaperPlatform() {
  if (Platform.isWindows) {
    return WindowsWallpaperPlatform();
  }
  if (Platform.isMacOS) {
    return MacOSWallpaperPlatform();
  }
  throw UnsupportedError(
    'Wallpaper platform is only supported on Windows and macOS.',
  );
}
