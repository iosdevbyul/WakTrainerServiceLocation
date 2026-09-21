//
//  MockLocationProvider.swift
//  WakTrainerServiceLocation
//
//  Created by COMATOKI on 2026-09-22.
//

import Foundation
import TrisLocationKit

@MainActor
final class MockLocationProvider: LocationProviding {

    var authorizationStatus: LocationAuthorizationStatus

    var authorizationResult: LocationAuthorizationStatus

    private(set) var requestWhenInUseAuthorizationCallCount = 0
    private(set) var requestAlwaysAuthorizationCallCount = 0
    private(set) var requestCurrentLocationCallCount = 0
    private(set) var locationUpdatesCallCount = 0
    private(set) var stopLocationUpdatesCallCount = 0

    private var locationContinuation:
        AsyncThrowingStream<LocationPoint, Error>.Continuation?

    init(
        authorizationStatus: LocationAuthorizationStatus = .notDetermined,
        authorizationResult: LocationAuthorizationStatus = .authorizedWhenInUse
    ) {
        self.authorizationStatus = authorizationStatus
        self.authorizationResult = authorizationResult
    }

    func requestWhenInUseAuthorization() async -> LocationAuthorizationStatus {
        requestWhenInUseAuthorizationCallCount += 1

        authorizationStatus = authorizationResult

        return authorizationResult
    }

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCallCount += 1
    }

    func requestCurrentLocation() async throws -> LocationPoint {
        requestCurrentLocationCallCount += 1

        throw LocationError.locationUnavailable
    }

    func locationUpdates() -> AsyncThrowingStream<LocationPoint, Error> {
        locationUpdatesCallCount += 1

        return AsyncThrowingStream { continuation in
            locationContinuation = continuation
        }
    }

    func stopLocationUpdates() {
        stopLocationUpdatesCallCount += 1

        locationContinuation?.finish()
        locationContinuation = nil
    }

    func sendLocation(
        _ point: LocationPoint
    ) {
        locationContinuation?.yield(point)
    }

    func sendFailure(
        _ error: any Error
    ) {
        locationContinuation?.finish(
            throwing: error
        )

        locationContinuation = nil
    }
}
