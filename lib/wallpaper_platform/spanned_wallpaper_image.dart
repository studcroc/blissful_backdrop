import 'dart:io';

import 'package:image/image.dart' as img;

import 'display_info.dart';

/// Result of generating per-display wallpaper images for macOS spanned wallpaper.
class SpannedWallpaperResult {
  final String leftWallpaperPath;
  final String rightWallpaperPath;

  const SpannedWallpaperResult({
    required this.leftWallpaperPath,
    required this.rightWallpaperPath,
  });
}

/// Generates left and right per-monitor wallpaper images from a single source image.
///
/// Algorithm (matching spec):
/// - Resize source to cover combined canvas (totalW x targetH), center-crop.
/// - Left: 3840×2160 strip at (0,0) with optional vertical nudge.
/// - Right: 1920×2160 strip at (3840,0); visible content 1920×1080 center-cropped,
///   placed on 1920×2160 canvas with vertical nudge.
///
/// [verticalOffsets]: [leftNudgePixels, rightNudgePixels]. Positive = content down.
Future<SpannedWallpaperResult> generateSpannedWallpaperImages({
  required String sourceImagePath,
  required List<DisplayInfo> displays,
  required List<int> verticalOffsets,
  required String outputDirectory,
}) async {
  if (displays.length < 2) {
    throw ArgumentError('Need at least 2 displays for spanned wallpaper');
  }
  final leftDisplay = displays[0];
  final rightDisplay = displays[1];
  final leftNudge = verticalOffsets.isNotEmpty ? verticalOffsets[0] : 0;
  final rightNudge = verticalOffsets.length > 1 ? verticalOffsets[1] : 0;

  final totalW = leftDisplay.width + rightDisplay.width;
  final targetH = leftDisplay.height;

  final bytes = await File(sourceImagePath).readAsBytes();
  final src = img.decodeImage(bytes);
  if (src == null) {
    throw Exception('Failed to decode image: $sourceImagePath');
  }

  // Resize to cover totalW x targetH (preserve aspect), then center-crop
  final scale = (totalW / src.width).clamp(0.0, double.infinity) >
          (targetH / src.height)
      ? totalW / src.width
      : targetH / src.height;
  final resizedW = (src.width * scale).round();
  final resizedH = (src.height * scale).round();
  final resized = img.copyResize(
    src,
    width: resizedW,
    height: resizedH,
    interpolation: img.Interpolation.linear,
  );
  final cropX = (resized.width - totalW) ~/ 2;
  final cropY = (resized.height - targetH) ~/ 2;
  final full = img.copyCrop(
    resized,
    x: cropX,
    y: cropY,
    width: totalW,
    height: targetH,
  );

  final leftStrip =
      img.copyCrop(full, x: 0, y: 0, width: leftDisplay.width, height: targetH);

  // Right base strip 1920×2160; visible content 1920×1080 center-cropped
  final rightStrip = img.copyCrop(
    full,
    x: leftDisplay.width,
    y: 0,
    width: rightDisplay.width,
    height: full.height,
  );
  final rightVisibleH = rightDisplay.height;
  final rightVisibleW = rightDisplay.width;
  final rightStripH = rightStrip.height;
  final cropRightY = rightStripH > rightVisibleH
      ? (rightStripH - rightVisibleH) ~/ 2
      : 0;
  final rightVisible = img.copyCrop(
    rightStrip,
    x: 0,
    y: cropRightY,
    width: rightVisibleW,
    height: rightVisibleH.clamp(0, rightStrip.height),
  );

  // Left final: canvas leftDisplay.width x leftDisplay.height, content at (0, leftNudge)
  final leftCanvas = img.Image(width: leftDisplay.width, height: leftDisplay.height);
  img.fill(leftCanvas, color: img.ColorRgba8(0, 0, 0, 255));
  _compositeLeftWithNudge(
    dst: leftCanvas,
    src: leftStrip,
    nudgePixels: leftNudge,
  );

  // Right final: canvas rightDisplay.width × targetH (2160); visible 1920×1080 at (0, 540 + rightNudge)
  final rightCanvasH = targetH;
  final rightCanvas = img.Image(width: rightDisplay.width, height: rightCanvasH);
  img.fill(rightCanvas, color: img.ColorRgba8(0, 0, 0, 255));
  final rightBaseY = (rightCanvasH - rightVisibleH) ~/ 2;
  final rightContentY = rightBaseY + rightNudge;
  _compositeRightWithNudge(
    dst: rightCanvas,
    src: rightVisible,
    contentY: rightContentY,
    canvasHeight: rightCanvasH,
  );

  final dir = Directory(outputDirectory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  // Unique filenames per apply so macOS sees a new URL and actually updates (it caches by path).
  final ts = DateTime.now().millisecondsSinceEpoch;
  final leftPath = '$outputDirectory/left_$ts.jpg';
  final rightPath = '$outputDirectory/right_$ts.jpg';
  await File(leftPath).writeAsBytes(img.encodeJpg(leftCanvas, quality: 95));
  await File(rightPath).writeAsBytes(img.encodeJpg(rightCanvas, quality: 95));
  // Remove old pairs so we don't fill /tmp (keep only current).
  try {
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final name = entity.uri.pathSegments.last;
        if ((name.startsWith('left_') || name.startsWith('right_')) && name != 'left_$ts.jpg' && name != 'right_$ts.jpg') {
          await entity.delete();
        }
      }
    }
  } catch (_) {}

  return SpannedWallpaperResult(
    leftWallpaperPath: leftPath,
    rightWallpaperPath: rightPath,
  );
}

/// Composites left strip onto canvas with vertical nudge. Positive nudge = content down.
void _compositeLeftWithNudge({
  required img.Image dst,
  required img.Image src,
  required int nudgePixels,
}) {
  final h = dst.height;
  if (nudgePixels >= h) return;
  final srcY = nudgePixels <= 0 ? -nudgePixels : 0;
  final srcH = nudgePixels >= 0 ? h - nudgePixels : h + nudgePixels;
  final dstY = nudgePixels <= 0 ? 0 : nudgePixels;
  if (srcH <= 0) return;
  img.compositeImage(
    dst,
    src,
    dstX: 0,
    dstY: dstY,
    dstW: dst.width,
    dstH: srcH,
    srcX: 0,
    srcY: srcY,
    srcW: src.width,
    srcH: srcH.clamp(0, src.height),
  );
}

/// Composites right visible (1920×1080) onto canvas at contentY. Clips if out of bounds.
void _compositeRightWithNudge({
  required img.Image dst,
  required img.Image src,
  required int contentY,
  required int canvasHeight,
}) {
  if (contentY >= canvasHeight || contentY + src.height <= 0) return;
  final srcY = contentY < 0 ? -contentY : 0;
  final dstY = contentY.clamp(0, canvasHeight - 1);
  final drawH = (canvasHeight - dstY).clamp(0, src.height - srcY);
  if (drawH <= 0) return;
  img.compositeImage(
    dst,
    src,
    dstX: 0,
    dstY: dstY,
    dstW: dst.width,
    dstH: drawH,
    srcX: 0,
    srcY: srcY,
    srcW: src.width,
    srcH: drawH,
  );
}
