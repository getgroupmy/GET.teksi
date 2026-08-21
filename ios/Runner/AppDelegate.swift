import CoreLocation
import Flutter
import UIKit
import UserNotifications

/// Device location on iOS, answering the same channel as the Android side.
///
/// This lives in AppDelegate.swift rather than its own file on purpose. A new
/// .swift file under ios/Runner/ is not part of the build until it is also
/// registered in Runner.xcodeproj/project.pbxproj — dropping one in compiles
/// locally in an editor and fails in CI with "cannot find in scope", which is
/// exactly what happened. Hand-editing a generated project file to add ninety
/// lines of glue is the more fragile of the two options, so the glue goes where
/// the target already looks.
///
/// CoreLocation is asynchronous twice over — first the authorization decision,
/// then the fix — and both arrive on delegate callbacks rather than as returns.
/// The Flutter result has to survive across both and must be called exactly
/// once, so it is held here and cleared by whichever callback gets there first.
final class LocationBridge: NSObject, CLLocationManagerDelegate {

  static let channelName = "get.teksi/location"

  /// A first fix outdoors is seconds; indoors it can be never. The app works
  /// without one, so waiting longer buys nothing.
  private static let timeout: TimeInterval = 9

  private let manager = CLLocationManager()
  private var pending: FlutterResult?
  private var timeoutTask: DispatchWorkItem?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "current" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.requestFix(result)
    }
  }

  private func requestFix(_ result: @escaping FlutterResult) {
    // One request at a time. A second while the first is outstanding gets nil
    // rather than displacing a result that someone is awaiting.
    guard pending == nil else {
      result(nil)
      return
    }
    pending = result

    let task = DispatchWorkItem { [weak self] in self?.finish(nil) }
    timeoutTask = task
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout, execute: task)

    switch manager.authorizationStatus {
    case .notDetermined:
      // The decision arrives at locationManagerDidChangeAuthorization, which
      // asks for the fix if it was granted.
      manager.requestWhenInUseAuthorization()
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    default:
      finish(nil)
    }
  }

  /// Replies once and tears down, whichever path got here.
  private func finish(_ location: CLLocation?) {
    guard let result = pending else { return }
    pending = nil
    timeoutTask?.cancel()
    timeoutTask = nil

    guard let coordinate = location?.coordinate else {
      result(nil)
      return
    }
    result(["lat": coordinate.latitude, "lng": coordinate.longitude])
  }

  // MARK: - CLLocationManagerDelegate

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // Fires on the rider's answer to the prompt, and again if they change it
    // in Settings. Only meaningful here while a request is outstanding.
    guard pending != nil else { return }
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      manager.requestLocation()
    case .notDetermined:
      break  // Still deciding.
    default:
      finish(nil)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    finish(locations.last)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Location off, airplane mode, no fix. All the same to the caller.
    finish(nil)
  }
}

/// The app's own settings page, which is where the notification permission
/// actually lives once iOS has stopped offering the prompt.
///
/// iOS asks for notification permission exactly once. After a refusal the
/// request call returns immediately and silently, so a Notifications row in
/// the app with nothing behind it would be a control that is not one.
enum AppBridge {

  static let channelName = "get.teksi/app"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "openNotificationSettings" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let url = URL(string: UIApplication.openSettingsURLString),
        UIApplication.shared.canOpenURL(url)
      else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Held for the process lifetime: it owns the CLLocationManager and the
  /// pending Flutter result, and a delegate deallocated between the permission
  /// prompt and the fix answers nothing at all.
  private let location = LocationBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Without this, iOS delivers a notification raised while the app is in the
    // foreground to nobody: no banner, no sound, and no error either. That is
    // most of what this app raises — the driver arrives while the passenger is
    // looking at the trip screen — so the seam that would look most broken is
    // exactly the one this line fixes. The optional cast is the plugin's own
    // recommendation; FlutterAppDelegate already declares the conformance.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // applicationRegistrar is the application-level counterpart to a plugin's
    // registrar; its messenger is the engine's.
    let messenger = engineBridge.applicationRegistrar.messenger()
    location.register(with: messenger)
    AppBridge.register(with: messenger)
  }
}
