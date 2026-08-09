import Flutter
import UIKit

/// iOS bridge for assessment capture privacy (not screenshot blocking).
///
/// - Reports UIScreen.isCaptured
/// - Notifies Flutter on capturedDidChange / userDidTakeScreenshot
/// - addFlags/clearFlags are no-ops (no public FLAG_SECURE equivalent)
public class SwiftFlutterWindowmanagerPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var monitoring = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_windowmanager",
      binaryMessenger: registrar.messenger()
    )
    let instance = SwiftFlutterWindowmanagerPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  deinit {
    stopMonitoring()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "addFlags", "clearFlags":
      // No public iOS equivalent of Android FLAG_SECURE.
      result(true)
    case "isCaptured":
      result(UIScreen.main.isCaptured)
    case "startCaptureMonitoring":
      startMonitoring()
      result(true)
    case "stopCaptureMonitoring":
      stopMonitoring()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startMonitoring() {
    if monitoring { return }
    monitoring = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onCapturedDidChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onScreenshotTaken),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
  }

  private func stopMonitoring() {
    if !monitoring { return }
    monitoring = false
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func onCapturedDidChange() {
    channel?.invokeMethod("onCaptureEvent", arguments: "capturedChanged")
  }

  @objc private func onScreenshotTaken() {
    // Detection only — screenshot already occurred; Flutter may flash overlay.
    channel?.invokeMethod("onCaptureEvent", arguments: "screenshotTaken")
  }
}
