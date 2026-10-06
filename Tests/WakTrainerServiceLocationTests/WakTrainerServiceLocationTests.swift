import Foundation
import Testing
import WakTrainerCoreModels

@testable import WakTrainerServiceLocation

struct WakTrainerServiceLocationTests {

    @Test
    func routePointsProducePaceSegments() throws {
        let start = Date(
            timeIntervalSince1970: 1_800_000_000
        )

        let routePoints = [
            WorkoutRoutePoint(
                timestamp: start,
                latitude: 37.5000,
                longitude: 127.0000,
                altitude: 20,
                speedMetersPerSecond: 2,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 90
            ),
            WorkoutRoutePoint(
                timestamp: start.addingTimeInterval(60),
                latitude: 37.5010,
                longitude: 127.0000,
                altitude: 22,
                speedMetersPerSecond: 2,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 90
            ),
            WorkoutRoutePoint(
                timestamp: start.addingTimeInterval(120),
                latitude: 37.5020,
                longitude: 127.0000,
                altitude: 24,
                speedMetersPerSecond: 2,
                horizontalAccuracy: 5,
                verticalAccuracy: 5,
                course: 90
            )
        ]

        let segments = WorkoutLocationProcessor()
            .processDynamicWorkout(
                routePoints: routePoints
            )

        #expect(segments.count == 2)

        let first = try #require(
            segments.first
        )

        #expect(
            first.startCoordinate.latitude
                == routePoints[0].latitude
        )

        #expect(
            first.endCoordinate.latitude
                == routePoints[1].latitude
        )

        #expect(first.speedMs > 0)
        #expect(first.speedCategory == .moderate)
    }

    @Test
    func fewerThanTwoRoutePointsProduceNoPaceSegments() {
        let routePoint = WorkoutRoutePoint(
            timestamp: Date(),
            latitude: 37.5,
            longitude: 127
        )

        let segments = WorkoutLocationProcessor()
            .processDynamicWorkout(
                routePoints: [routePoint]
            )

        #expect(segments.isEmpty)
    }
}
