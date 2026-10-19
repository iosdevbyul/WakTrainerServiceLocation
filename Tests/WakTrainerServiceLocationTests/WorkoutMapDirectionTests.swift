import CoreLocation
import Testing
@testable import WakTrainerServiceLocation

@Suite("Workout map direction")
struct WorkoutMapDirectionTests {
    @Test("eastbound points rotate the heading east")
    func eastbound() {
        let direction = WorkoutMapView.Coordinator.bearing(
            from: CLLocationCoordinate2D(latitude: 37.56, longitude: 126.97),
            to: CLLocationCoordinate2D(latitude: 37.56, longitude: 126.98)
        )
        #expect(direction > 80 && direction < 100)
    }

    @Test("northbound points rotate the heading north")
    func northbound() {
        let direction = WorkoutMapView.Coordinator.bearing(
            from: CLLocationCoordinate2D(latitude: 37.56, longitude: 126.97),
            to: CLLocationCoordinate2D(latitude: 37.57, longitude: 126.97)
        )
        #expect(direction < 1 || direction > 359)
    }
}
