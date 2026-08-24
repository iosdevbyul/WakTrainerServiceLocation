import Foundation
import CoreLocation
import Combine
import WakTrainerCoreModels

public final class LocationManager: NSObject, LocationManagerProtocol, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    
    @Published public private(set) var userLocation: CLLocation?
    @Published public private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published public private(set) var isTracking: Bool = false
    
    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    public func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startTracking() {
        isTracking = true
        routeCoordinates.removeAll()
        locationManager.startUpdatingLocation()
    }
    
    public func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let location = locations.last else { return }
        userLocation = location
        routeCoordinates.append(location.coordinate)
    }
}
