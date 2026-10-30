import CoreLocation
import XCTest
import WakTrainerCoreModels
@testable import WakTrainerServiceLocation

final class WorkoutRouteDisplaySmootherTests: XCTestCase {
    func testRemovesIsolatedGPSJumpWithoutMutatingPace() {
        let start = CLLocationCoordinate2D(latitude: 37.500000, longitude: 127.000000)
        let spike = CLLocationCoordinate2D(latitude: 37.500450, longitude: 127.000000)
        let end = CLLocationCoordinate2D(latitude: 37.500025, longitude: 127.000000)
        let original = [
            segment(start, spike, speed: 1.2),
            segment(spike, end, speed: 1.5)
        ]

        let result = WorkoutRouteDisplaySmoother.smooth(original)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].speedMs, original[0].speedMs)
        XCTAssertEqual(result[1].speedMs, original[1].speedMs)
        XCTAssertEqual(result[0].startCoordinate.latitude, start.latitude)
        XCTAssertEqual(result[1].endCoordinate.latitude, end.latitude)
        XCTAssertEqual(result[0].endCoordinate.latitude, result[1].startCoordinate.latitude)
        XCTAssertLessThan(abs(result[0].endCoordinate.latitude - start.latitude), 0.00003)
        XCTAssertEqual(original[0].endCoordinate.latitude, spike.latitude)
    }

    func testPreservesSignificantRealCorner() {
        let a = CLLocationCoordinate2D(latitude: 37.500000, longitude: 127.000000)
        let b = CLLocationCoordinate2D(latitude: 37.500270, longitude: 127.000000)
        let c = CLLocationCoordinate2D(latitude: 37.500270, longitude: 127.000340)
        let result = WorkoutRouteDisplaySmoother.smooth([
            segment(a, b, speed: 1),
            segment(b, c, speed: 1)
        ])

        XCTAssertEqual(result[0].endCoordinate.latitude, b.latitude)
        XCTAssertEqual(result[0].endCoordinate.longitude, b.longitude)
    }

    func testDoesNotJoinDisconnectedSegments() {
        let a = CLLocationCoordinate2D(latitude: 37.500000, longitude: 127.000000)
        let b = CLLocationCoordinate2D(latitude: 37.500020, longitude: 127.000000)
        let c = CLLocationCoordinate2D(latitude: 37.501000, longitude: 127.001000)
        let d = CLLocationCoordinate2D(latitude: 37.501020, longitude: 127.001000)
        let result = WorkoutRouteDisplaySmoother.smooth([
            segment(a, b, speed: 1),
            segment(c, d, speed: 1)
        ])

        XCTAssertEqual(result[0].endCoordinate.latitude, b.latitude)
        XCTAssertEqual(result[1].startCoordinate.latitude, c.latitude)
    }

    private func segment(
        _ start: CLLocationCoordinate2D,
        _ end: CLLocationCoordinate2D,
        speed: Double
    ) -> PaceSegment {
        PaceSegment(
            startCoordinate: start,
            endCoordinate: end,
            speedCategory: .moderate,
            speedMs: speed
        )
    }
}
