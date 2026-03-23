import Foundation
import CoreLocation
import Combine

/// Service for location-based features (reminders, journal entries).
@MainActor
final class LocationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = LocationService()

    // MARK: - Published State

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var currentPlacemark: CLPlacemark?
    @Published private(set) var isAuthorized: Bool = false

    // MARK: - Dependencies

    private let locationManager: CLLocationManager
    private let geocoder: CLGeocoder

    // MARK: - Callbacks

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Initialization

    private override init() {
        locationManager = CLLocationManager()
        geocoder = CLGeocoder()

        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Requests location authorization
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Requests always authorization (for background location reminders)
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Location

    /// Gets the current location
    func getCurrentLocation() async throws -> CLLocation {
        guard isAuthorized else {
            throw LocationError.notAuthorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    /// Gets the current location with placemark
    func getCurrentLocationWithPlacemark() async throws -> (CLLocation, CLPlacemark?) {
        let location = try await getCurrentLocation()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            currentPlacemark = placemark
            return (location, placemark)
        } catch {
            return (location, nil)
        }
    }

    // MARK: - Region Monitoring

    /// Starts monitoring a region for location reminders
    func startMonitoring(region: CLCircularRegion) throws {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            throw LocationError.regionMonitoringUnavailable
        }

        guard authorizationStatus == .authorizedAlways else {
            throw LocationError.alwaysAuthorizationRequired
        }

        locationManager.startMonitoring(for: region)
    }

    /// Stops monitoring a region
    func stopMonitoring(region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
    }

    /// Stops monitoring all regions
    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    /// Gets currently monitored regions
    var monitoredRegions: Set<CLRegion> {
        locationManager.monitoredRegions
    }

    // MARK: - Geocoding

    /// Geocodes an address to coordinates
    func geocode(address: String) async throws -> CLLocation {
        let placemarks = try await geocoder.geocodeAddressString(address)

        guard let location = placemarks.first?.location else {
            throw LocationError.geocodingFailed
        }

        return location
    }

    /// Reverse geocodes coordinates to an address
    func reverseGeocode(location: CLLocation) async throws -> CLPlacemark {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed
        }

        return placemark
    }

    // MARK: - Private Methods

    private func updateAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        isAuthorized = authorizationStatus == .authorizedWhenInUse ||
                      authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            currentLocation = location
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        // Handle region entry - trigger notification
        NotificationCenter.default.post(
            name: .didEnterLocationRegion,
            object: nil,
            userInfo: ["regionId": region.identifier]
        )
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        // Handle region exit - trigger notification
        NotificationCenter.default.post(
            name: .didExitLocationRegion,
            object: nil,
            userInfo: ["regionId": region.identifier]
        )
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case notAuthorized
    case alwaysAuthorizationRequired
    case regionMonitoringUnavailable
    case geocodingFailed
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "error.location.notAuthorized")
        case .alwaysAuthorizationRequired:
            return String(localized: "error.location.alwaysRequired")
        case .regionMonitoringUnavailable:
            return String(localized: "error.location.regionUnavailable")
        case .geocodingFailed:
            return String(localized: "error.location.geocodingFailed")
        case .locationUnavailable:
            return String(localized: "error.location.unavailable")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didEnterLocationRegion = Notification.Name("didEnterLocationRegion")
    static let didExitLocationRegion = Notification.Name("didExitLocationRegion")
}
