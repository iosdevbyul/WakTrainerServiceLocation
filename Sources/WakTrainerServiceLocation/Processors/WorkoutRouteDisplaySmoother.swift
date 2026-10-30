import CoreLocation
import MapKit
import WakTrainerCoreModels

/// Adjusts map geometry only. Recorded route points and pace metrics remain untouched.
enum WorkoutRouteDisplaySmoother {
    static func smooth(_ segments: [PaceSegment]) -> [PaceSegment] {
        guard segments.count >= 2 else { return segments }

        var coordinates = [segments[0].startCoordinate]
        coordinates.append(contentsOf: segments.map(\.endCoordinate))
        var display = coordinates

        for index in 1..<(coordinates.count - 1) {
            let previous = coordinates[index - 1]
            let current = coordinates[index]
            let next = coordinates[index + 1]

            guard CLLocationCoordinate2DIsValid(previous),
                  CLLocationCoordinate2DIsValid(current),
                  CLLocationCoordinate2DIsValid(next),
                  samePoint(segments[index - 1].endCoordinate, segments[index].startCoordinate)
            else { continue }

            let first = MKMapPoint(previous)
            let middle = MKMapPoint(current)
            let last = MKMapPoint(next)
            let firstDistance = meters(previous, current)
            let lastDistance = meters(current, next)
            let directDistance = meters(previous, next)

            // An isolated, large out-and-back GPS jump is not a real turn.
            if firstDistance > 15, lastDistance > 15,
               firstDistance < 100, lastDistance < 100,
               directDistance < 15 {
                display[index] = CLLocationCoordinate2D(
                    MKMapPoint(x: (first.x + last.x) / 2, y: (first.y + last.y) / 2)
                )
                continue
            }

            // Smooth only short, low-amplitude jitter; preserve real corners.
            let midpoint = MKMapPoint(
                x: (first.x + last.x) / 2,
                y: (first.y + last.y) / 2
            )
            let deviation = meters(current, CLLocationCoordinate2D(midpoint))
            if firstDistance <= 30, lastDistance <= 30, deviation <= 8 {
                let softened = MKMapPoint(
                    x: middle.x * 0.75 + midpoint.x * 0.25,
                    y: middle.y * 0.75 + midpoint.y * 0.25
                )
                display[index] = CLLocationCoordinate2D(softened)
            }
        }

        return segments.enumerated().map { index, segment in
            PaceSegment(
                startCoordinate: display[index],
                endCoordinate: display[index + 1],
                speedCategory: segment.speedCategory,
                speedMs: segment.speedMs
            )
        }
    }

    private static func meters(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private static func samePoint(
        _ a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D
    ) -> Bool {
        a.latitude == b.latitude && a.longitude == b.longitude
    }
}
