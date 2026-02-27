import 'dart:io';

import 'package:flutter/services.dart';

import 'display_info.dart';
import 'wallpaper_platform.dart';

/// Windows implementation: uses COM IDesktopWallpaper (single image, span mode).
/// Per-monitor wallpaper is not used; one image is set system-wide with fit mode Span.
class WindowsWallpaperPlatform implements WallpaperPlatform {
  WindowsWallpaperPlatform() {
    if (!Platform.isWindows) {
      throw UnsupportedError('WindowsWallpaperPlatform is only supported on Windows');
    }
  }

  static const _channel = MethodChannel('blissful_backdrop.native/wallpaper');

  @override
  Future<List<DisplayInfo>> getDisplays() async {
    // Windows currently uses a single spanned image; we don't need per-display
    // geometry for the existing behavior. Can be extended later with Win32 enum.
    return [];
  }

  @override
  Future<void> generateAndApplySpannedWallpaper({
    required String sourceImagePath,
    required List<DisplayInfo> displays,
    required List<int> verticalOffsets,
  }) async {
    // Current Windows behavior: set one image with fit mode 5 (Span).
    // Ignores displays/verticalOffsets; OS spans the image across monitors.
    try {
      await _channel.invokeMethod<bool>('setDesktopWallpaper', {
        'filePath': sourceImagePath,
        'fitMode': 5,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to set wallpaper: ${e.message}');
    }
  }
}
