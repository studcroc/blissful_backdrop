import 'display_info.dart';

/// Platform-specific implementation for monitor detection and spanned wallpaper.
abstract class WallpaperPlatform {
  /// Returns attached displays with geometry (width, height, x, y) in a stable order
  /// (e.g. left-to-right). Used to know how to split the source image and which
  /// display gets which wallpaper.
  Future<List<DisplayInfo>> getDisplays();

  /// Generates per-monitor wallpapers from [sourceImagePath] and applies them.
  /// [displays] should match the order from [getDisplays].
  /// [verticalOffsets] are per-display vertical nudge in pixels (positive = down).
  Future<void> generateAndApplySpannedWallpaper({
    required String sourceImagePath,
    required List<DisplayInfo> displays,
    required List<int> verticalOffsets,
  });
}
