//
//  LocationManagerTests.swift
//  WakTrainerServiceLocation
//
//  Created by COMATOKI on 2026-09-22.
//

import CoreLocation
import Foundation
import Testing
import TrisLocationKit

@testable import WakTrainerServiceLocation

@MainActor
struct LocationManagerTests {

    @Test
    func requestLocationPermissionUsesLocationProvider() async {
        let provider = MockLocationProvider()

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.requestLocationPermission()

        await Task.yield()

        #expect(
            provider.requestWhenInUseAuthorizationCallCount == 1
        )
    }

    @Test
    func startTrackingStartsLocationUpdates() {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()

        #expect(manager.isTracking)

        #expect(
            provider.locationUpdatesCallCount == 1
        )
    }

    @Test
    func startTrackingDoesNotStartTwice() {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()
        manager.startTracking()

        #expect(
            provider.locationUpdatesCallCount == 1
        )
    }

    @Test
    func receivedLocationUpdatesUserLocation() async {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()

        let timestamp = Date(
            timeIntervalSince1970: 1_000
        )

        let point = LocationPoint(
            latitude: 37.5665,
            longitude: 126.9780,
            altitude: 30,
            horizontalAccuracy: 5,
            verticalAccuracy: 8,
            speed: 2.5,
            course: 180,
            timestamp: timestamp
        )

        provider.sendLocation(point)

        let didReceiveLocation = await waitUntil {
            manager.userLocation != nil
        }

        #expect(didReceiveLocation)

        #expect(
            manager.userLocation?.coordinate.latitude
                == 37.5665
        )

        #expect(
            manager.userLocation?.coordinate.longitude
                == 126.9780
        )

        #expect(
            manager.userLocation?.altitude
                == 30
        )

        #expect(
            manager.userLocation?.speed
                == 2.5
        )

        #expect(
            manager.userLocation?.timestamp
                == timestamp
        )

        #expect(
            manager.userLocation?.coordinate.longitude
                == 126.9780
        )

        #expect(
            manager.userLocation?.altitude
                == 30
        )

        #expect(
            manager.userLocation?.speed
                == 2.5
        )

        #expect(
            manager.userLocation?.timestamp
                == timestamp
        )
    }

    @Test
    func receivedLocationsAreAddedToRoute() async {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()

        let firstPoint = LocationPoint(
            latitude: 37.1,
            longitude: 127.1,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            speed: 1,
            course: 0,
            timestamp: Date(
                timeIntervalSince1970: 1_000
            )
        )

        let secondPoint = LocationPoint(
            latitude: 37.2,
            longitude: 127.2,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            speed: 1,
            course: 0,
            timestamp: Date(
                timeIntervalSince1970: 1_001
            )
        )

        provider.sendLocation(firstPoint)
        provider.sendLocation(secondPoint)

        let didReceiveLocations = await waitUntil {
            manager.routeCoordinates.count == 2
        }

        #expect(didReceiveLocations)

        #expect(
            manager.routeCoordinates.first?.latitude == 37.1
        )

        #expect(
            manager.routeCoordinates.last?.latitude == 37.2
        )
    }

    @Test
    func startTrackingClearsPreviousRoute() async {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()

        let point = LocationPoint(
            latitude: 37.1,
            longitude: 127.1,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            speed: 1,
            course: 0,
            timestamp: Date()
        )

        provider.sendLocation(point)

        let didReceiveLocation = await waitUntil {
            manager.routeCoordinates.count == 1
        }

        #expect(didReceiveLocation)

        manager.stopTracking()
        manager.startTracking()

        #expect(
            manager.routeCoordinates.isEmpty
        )

        manager.stopTracking()
        manager.startTracking()

        #expect(
            manager.routeCoordinates.isEmpty
        )
    }

    @Test
    func stopTrackingStopsLocationUpdates() {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()
        manager.stopTracking()

        #expect(!manager.isTracking)

        #expect(
            provider.stopLocationUpdatesCallCount == 1
        )
    }

    @Test
    func stopTrackingDoesNothingWhenNotTracking() {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.stopTracking()

        #expect(
            provider.stopLocationUpdatesCallCount == 0
        )
    }

    @Test
    func streamFailureStopsTracking() async {
        let provider = MockLocationProvider(
            authorizationStatus: .authorizedWhenInUse
        )

        let manager = LocationManager(
            locationProvider: provider
        )

        manager.startTracking()

        #expect(manager.isTracking)

        provider.sendFailure(
            LocationError.requestFailed
        )

        let didStopTracking = await waitUntil {
            !manager.isTracking
        }

        #expect(didStopTracking)
    }
}

private func waitUntil(
    _ condition: () -> Bool
) async -> Bool {
    for _ in 0..<100 {
        if condition() {
            return true
        }

        try? await Task.sleep(
            nanoseconds: 10_000_000
        )
    }

    return condition()
}
