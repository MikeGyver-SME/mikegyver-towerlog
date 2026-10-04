import Foundation
import CoreLocation
import Combine

/// One-shot GPS fix acquisition for the "Log Tower" flow.
///
/// Unlike a walk tracker, a tower log needs exactly one good fix, taken while
/// the app is open — so this requests When-In-Use authorization only, delivers
/// the first accepted fix (<= 50 m accuracy, not stale), then stops. There is
/// no background mode and no "Always" prompt.
@MainActor
final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var fix: CLLocation?
    /// Human-readable status for the capture screen.
    @Published var status: String = ""

    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorization = manager.authorizationStatus
    }

    func requestWhenInUseIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    var isAuthorized: Bool {
        switch authorization {
        case .authorizedWhenInUse, .authorizedAlways: return true
        default: return false
        }
    }

    /// Start (or restart) fix acquisition. The first accepted fix wins; a
    /// 30 s watchdog posts a hint if the sky is being uncooperative.
    func acquireFix() {
        guard isAuthorized || authorization == .notDetermined else {
            status = "Location is off — enable it in Settings to log towers."
            return
        }
        fix = nil
        status = "Acquiring GPS…"
        manager.startUpdatingLocation()
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self, self.fix == nil else { return }
            self.status = "Still waiting — step into the open, away from buildings."
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let next = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = next
            // The user may have just granted access from the prompt: start up.
            if self.fix == nil, next == .authorizedWhenInUse || next == .authorizedAlways {
                self.acquireFix()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        // Drop invalid, coarse, or stale fixes.
        guard latest.horizontalAccuracy >= 0, latest.horizontalAccuracy <= 50 else { return }
        guard abs(latest.timestamp.timeIntervalSinceNow) < 10 else { return }
        Task { @MainActor in
            // Keep the best fix seen this session, then stop the radio.
            if let current = self.fix {
                if latest.horizontalAccuracy < current.horizontalAccuracy {
                    self.fix = latest
                }
            } else {
                self.fix = latest
            }
            if let f = self.fix {
                self.status = String(format: "Fix acquired (±%.0f m)", f.horizontalAccuracy)
                self.stop()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        // Transient GPS gaps are normal; the timeout hint covers the user.
    }
}
