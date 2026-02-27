import 'dart:io';

import 'package:flutter/services.dart';

import 'display_info.dart';
import 'spanned_wallpaper_image.dart';
import 'wallpaper_platform.dart';

/// macOS implementation: native display list + image processing + AppleScript set desktop.
class MacOSWallpaperPlatform implements WallpaperPlatform {
  MacOSWallpaperPlatform() {
    if (!Platform.isMacOS) {
      throw UnsupportedError(
          'MacOSWallpaperPlatform is only supported on macOS');
    }
  }

  static const _channel = MethodChannel('blissful_backdrop.native/wallpaper');

  /// Output directory for generated wallpapers. Must be readable by System Events
  /// (which runs outside the app sandbox), so we use /tmp instead of the app container.
  static const _outputDir = '/tmp/blissful_backdrop_wallpaper';

  @override
  Future<List<DisplayInfo>> getDisplays() async {
    final result = await _channel.invokeMethod<List<Object?>>('getDisplays');
    if (result == null || result.isEmpty) {
      return [];
    }
    return result.map((e) {
      final m = (e as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k!.toString(), v),
      );
      return DisplayInfo.fromJson(Map<String, dynamic>.from(m));
    }).toList();
  }

  @override
  Future<void> generateAndApplySpannedWallpaper({
    required String sourceImagePath,
    required List<DisplayInfo> displays,
    required List<int> verticalOffsets,
  }) async {
    if (displays.length < 2) {
      throw ArgumentError(
          'Spanned wallpaper requires at least 2 displays (got ${displays.length})');
    }

    final outputDir = _outputDir;

    final result = await generateSpannedWallpaperImages(
      sourceImagePath: sourceImagePath,
      displays: displays,
      verticalOffsets: verticalOffsets,
      outputDirectory: outputDir,
    );

    await _channel.invokeMethod<void>('setDesktopPictures', {
      'leftPath': result.leftWallpaperPath,
      'rightPath': result.rightWallpaperPath,
    });
  }
}
