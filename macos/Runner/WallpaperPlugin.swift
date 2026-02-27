import AppKit
import CoreGraphics
import FlutterMacOS
import Foundation

/// macOS native plugin: display enumeration (CoreGraphics) and set desktop pictures (AppleScript).
final class WallpaperPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    register(withBinaryMessenger: registrar.messenger)
  }

  /// Register the plugin with a binary messenger (e.g. from FlutterViewController.engine).
  static func register(withBinaryMessenger messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "blissful_backdrop.native/wallpaper",
      binaryMessenger: messenger
    )
    let instance = WallpaperPlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDisplays":
      handleGetDisplays(result: result)
    case "setDesktopPictures":
      guard let args = call.arguments as? [String: Any],
            let leftPath = args["leftPath"] as? String,
            let rightPath = args["rightPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "leftPath and rightPath required", details: nil))
        return
      }
      handleSetDesktopPictures(leftPath: leftPath, rightPath: rightPath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetDisplays(result: @escaping FlutterResult) {
    var displayCount: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &displayCount)
    guard displayCount > 0 else {
      result([])
      return
    }
    var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
    CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount)

    // Sort by origin x so left-to-right order is stable
    let displays = (0..<Int(displayCount)).map { i in
      (id: displayIDs[i], bounds: CGDisplayBounds(displayIDs[i]))
    }.sorted { $0.bounds.origin.x < $1.bounds.origin.x }

    let list = displays.enumerated().map { index, item -> [String: Any] in
      let bounds = item.bounds
      let width = Int(bounds.width)
      let height = Int(bounds.height)
      return [
        "id": "\(item.id)",
        "width": width,
        "height": height,
        "x": Int(bounds.origin.x),
        "y": Int(bounds.origin.y),
      ]
    }
    result(list)
  }

  private func handleSetDesktopPictures(leftPath: String, rightPath: String, result: @escaping FlutterResult) {
    let leftFile = leftPath.hasPrefix("/") ? leftPath : NSString(string: leftPath).expandingTildeInPath
    let rightFile = rightPath.hasPrefix("/") ? rightPath : NSString(string: rightPath).expandingTildeInPath

    let fm = FileManager.default
    if !fm.fileExists(atPath: leftFile) {
      result(FlutterError(code: "SET_DESKTOP_FAILED", message: "Left image file not found: \(leftFile)", details: nil))
      return
    }
    if !fm.fileExists(atPath: rightFile) {
      result(FlutterError(code: "SET_DESKTOP_FAILED", message: "Right image file not found: \(rightFile)", details: nil))
      return
    }

    // Stable left-to-right order: sort by x, then y so mapping is deterministic.
    let screens = NSScreen.screens.sorted { a, b in
      let ax = a.frame.origin.x, bx = b.frame.origin.x
      if ax != bx { return ax < bx }
      return a.frame.origin.y < b.frame.origin.y
    }
    guard screens.count >= 2 else {
      result(FlutterError(code: "SET_DESKTOP_FAILED", message: "Need at least 2 screens (found \(screens.count))", details: nil))
      return
    }

    let leftScreen = screens[0]
    let rightScreen = screens[1]
    let leftURL = URL(fileURLWithPath: leftFile)
    let rightURL = URL(fileURLWithPath: rightFile)

    // Left display ← left image, right display ← right image.
    let imageForLeftScreen = leftURL
    let imageForRightScreen = rightURL

    // Fill screen (scale to cover, allow clip) — same as "Fill" in System Preferences.
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
      .allowClipping: true,
    ]

    let workspace = NSWorkspace.shared
    do {
      try workspace.setDesktopImageURL(imageForLeftScreen, for: leftScreen, options: options)
      // Short delay so macOS applies the first screen before we set the second (avoids one update being dropped).
      Thread.sleep(forTimeInterval: 0.35)
      try workspace.setDesktopImageURL(imageForRightScreen, for: rightScreen, options: options)
      result(nil)
    } catch {
      result(FlutterError(code: "SET_DESKTOP_FAILED", message: error.localizedDescription, details: nil))
    }
  }
}
