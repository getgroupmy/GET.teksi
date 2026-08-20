import CoreLocation
import Flutter

/// Device location on iOS, answering the same channel as the Android side.
///
/// CoreLocation is asynchronous twice over — first the authorization decision,
/// then the fix — and both arrive on delegate callbacks rather than as returns.
/// The Flutter result has to survive across both, and must be called exactly
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

    let timeoutTask = DispatchWorkItem { [weak self] in self?.finish(nil) }
    self.timeoutTask = timeoutTask
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout, execute: timeoutTask)

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
