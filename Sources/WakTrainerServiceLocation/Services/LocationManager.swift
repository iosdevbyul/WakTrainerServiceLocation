import Foundation
import CoreLocation
import Combine
import TrisLocationKit
import WakTrainerCoreModels

@MainActor
public final class LocationManager: NSObject,
                                    @preconcurrency LocationManagerProtocol {

    private let locationProvider: any LocationProviding

    private var trackingTask: Task<Void, Never>?

    @Published
    public private(set) var userLocation: CLLocation?

    @Published
    public private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    @Published
    public private(set) var isTracking: Bool = false

    public override init() {
        locationProvider = CoreLocationProvider()

        super.init()
    }

    init(
        locationProvider: any LocationProviding
    ) {
        self.locationProvider = locationProvider

        super.init()
    }

    public func requestLocationPermission() {
        Task { [weak self] in
            guard let self else {
                return
            }

            _ = await locationProvider
                .requestWhenInUseAuthorization()
        }
    }

    public func startTracking() {
        guard !isTracking else {
            return
        }

        trackingTask?.cancel()

        routeCoordinates.removeAll()
        isTracking = true

        let updates = locationProvider.locationUpdates()

        trackingTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                for try await point in updates {
                    guard !Task.isCancelled else {
                        break
                    }

                    handleLocationPoint(point)
                }
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                isTracking = false
            }
        }
    }

    public func stopTracking() {
        guard isTracking else {
            return
        }

        isTracking = false

        trackingTask?.cancel()
        trackingTask = nil

        locationProvider.stopLocationUpdates()
    }
}

private extension LocationManager {

    func handleLocationPoint(
        _ point: LocationPoint
    ) {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: point.latitude,
                longitude: point.longitude
            ),
            altitude: point.altitude,
            horizontalAccuracy: point.horizontalAccuracy,
            verticalAccuracy: point.verticalAccuracy,
            course: point.course,
            speed: point.speed,
            timestamp: point.timestamp
        )

        userLocation = location
        routeCoordinates.append(
            location.coordinate
        )
    }
}
