import SwiftUI
import MapKit
import UIKit
import WakTrainerCoreModels

public struct WorkoutMapView: UIViewRepresentable {
    public let workoutType: WorkoutType
    public let staticSummary: StaticLocationSummary?
    public let paceSegments: [PaceSegment]
    /// Follow a live workout instead of repeatedly fitting the whole recorded route.
    public let followsCurrentPosition: Bool
    /// Optional Zone 1–5 classifications for each route segment. Nil retains speed coloring.
    public let routeZoneLevels: [Int?]?

    public init(
        workoutType: WorkoutType,
        staticSummary: StaticLocationSummary? = nil,
        paceSegments: [PaceSegment] = [],
        followsCurrentPosition: Bool = false
    ) {
        self.workoutType = workoutType
        self.staticSummary = staticSummary
        self.paceSegments = paceSegments
        self.followsCurrentPosition = followsCurrentPosition
        self.routeZoneLevels = nil
    }

    public init(routePoints: [WorkoutRoutePoint], zoneLevels: [Int?]? = nil) {
        self.workoutType = .dynamicWorkout
        self.staticSummary = nil
        self.paceSegments = WorkoutLocationProcessor()
            .processDynamicWorkout(routePoints: routePoints)
        self.followsCurrentPosition = false
        self.routeZoneLevels = zoneLevels
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        return mapView
    }

    public func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self

        switch workoutType {
        case .staticWorkout:
            coordinator.updateStatic(summary: staticSummary, on: mapView)
        case .dynamicWorkout:
            coordinator.updateRoute(
                segments: WorkoutRouteDisplaySmoother.smooth(paceSegments),
                zoneLevels: routeZoneLevels,
                followsPosition: followsCurrentPosition,
                on: mapView
            )
        }
    }

    private func uiColor(for category: SpeedCategory) -> UIColor {
        switch category {
        case .verySlow:  return .systemYellow
        case .slow:      return UIColor(red: 0.9, green: 0.7, blue: 0.0, alpha: 1)
        case .moderate:  return .systemGreen
        case .brisk:     return UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1)
        case .fast:      return UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 1)
        case .veryFast:  return .systemRed
        }
    }

    private func zoneColor(for level: Int?) -> UIColor {
        switch level {
        case 1: return .systemBlue
        case 2: return .systemGreen
        case 3: return .systemYellow
        case 4: return .systemOrange
        case 5: return .systemRed
        default: return .systemGray
        }
    }

    public final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WorkoutMapView
        private var renderedSegments: [PaceSegment] = []
        private var renderedZoneLevels: [Int?]?
        private let startPin = MKPointAnnotation()
        private let headingPin = HeadingAnnotation()
        private var hasStartPin = false
        private var hasHeadingPin = false
        private var hasSetInitialCamera = false
        private var trackingEnabled = true
        private var lastCameraPoint: CLLocationCoordinate2D?
        private var lastStaticCoordinate: CLLocationCoordinate2D?

        init(_ parent: WorkoutMapView) {
            self.parent = parent
            super.init()
            startPin.title = "Start"
        }

        func updateStatic(summary: StaticLocationSummary?, on mapView: MKMapView) {
            guard let summary else { return }
            let coordinate = summary.centerCoordinate
            if hasHeadingPin {
                mapView.removeAnnotation(headingPin)
                hasHeadingPin = false
            }
            if !renderedSegments.isEmpty {
                mapView.removeOverlays(mapView.overlays)
                renderedSegments = []
            }
            if !hasStartPin {
                mapView.addAnnotation(startPin)
                hasStartPin = true
            }
            startPin.coordinate = coordinate
            guard lastStaticCoordinate == nil ||
                  CLLocation(latitude: lastStaticCoordinate!.latitude, longitude: lastStaticCoordinate!.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > 5 else { return }
            lastStaticCoordinate = coordinate
            mapView.setRegion(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200),
                animated: false
            )
        }

        func updateRoute(
            segments: [PaceSegment],
            zoneLevels: [Int?]?,
            followsPosition: Bool,
            on mapView: MKMapView
        ) {
            guard !segments.isEmpty else { return }

            // Preserve existing overlays when the route only grows.
            let prefixUnchanged = segments.count >= renderedSegments.count
                && zip(segments, renderedSegments).allSatisfy { new, old in
                    new.startCoordinate.latitude == old.startCoordinate.latitude
                        && new.startCoordinate.longitude == old.startCoordinate.longitude
                        && new.endCoordinate.latitude == old.endCoordinate.latitude
                        && new.endCoordinate.longitude == old.endCoordinate.longitude
                        && new.speedCategory == old.speedCategory
                }
            // Repaint when the selected metric changes, without resetting the map camera.
            let colorsChanged = renderedZoneLevels != zoneLevels
            if !prefixUnchanged || colorsChanged {
                mapView.removeOverlays(mapView.overlays)
                renderedSegments = []
                if !prefixUnchanged {
                    hasSetInitialCamera = false
                    lastCameraPoint = nil
                }
            }
            if segments.count > renderedSegments.count {
                for (offset, segment) in segments.dropFirst(renderedSegments.count).enumerated() {
                    let index = renderedSegments.count + offset
                    var coordinates = [segment.startCoordinate, segment.endCoordinate]
                    let polyline = ColoredPolyline(coordinates: &coordinates, count: 2)
                    polyline.color = zoneLevels == nil
                        ? parent.uiColor(for: segment.speedCategory)
                        : parent.zoneColor(for: zoneLevels?.indices.contains(index) == true ? zoneLevels?[index] : nil)
                    mapView.addOverlay(polyline)
                }
                renderedSegments = segments
                renderedZoneLevels = zoneLevels
            }

            if !hasStartPin {
                startPin.coordinate = segments[0].startCoordinate
                mapView.addAnnotation(startPin)
                hasStartPin = true
            } else {
                startPin.coordinate = segments[0].startCoordinate
            }

            let last = segments[segments.count - 1]
            let coordinate = last.endCoordinate
            headingPin.coordinate = coordinate
            headingPin.heading = Self.bearing(from: last.startCoordinate, to: last.endCoordinate)
            if !hasHeadingPin {
                mapView.addAnnotation(headingPin)
                hasHeadingPin = true
            }
            if let view = mapView.view(for: headingPin) as? HeadingAnnotationView {
                view.updateHeading(headingPin.heading)
            }

            if followsPosition {
                if !hasSetInitialCamera {
                    trackingEnabled = true
                    moveCamera(to: coordinate, on: mapView, animated: false)
                    hasSetInitialCamera = true
                } else if trackingEnabled, shouldMoveCamera(to: coordinate) {
                    moveCamera(to: coordinate, on: mapView, animated: true)
                }
            } else if !hasSetInitialCamera || !prefixUnchanged {
                let points = segments.flatMap { [$0.startCoordinate, $0.endCoordinate] }
                var rect = MKMapRect.null
                for coordinate in points {
                    let p = MKMapPoint(coordinate)
                    rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 1, height: 1))
                }
                mapView.setVisibleMapRect(
                    rect, edgePadding: UIEdgeInsets(top: 70, left: 40, bottom: 70, right: 40),
                    animated: false
                )
                hasSetInitialCamera = true
            }
        }

        private func shouldMoveCamera(to coordinate: CLLocationCoordinate2D) -> Bool {
            guard let previous = lastCameraPoint else { return true }
            return CLLocation(latitude: previous.latitude, longitude: previous.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) >= 12
        }

        private func moveCamera(to coordinate: CLLocationCoordinate2D, on mapView: MKMapView, animated: Bool) {
            lastCameraPoint = coordinate
            mapView.setRegion(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 350, longitudinalMeters: 350),
                animated: animated
            )
        }

        /// MapKit can signal user-driven panning/zooming via active gesture recognizers.
        public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            let recognizers = mapView.subviews.flatMap { $0.gestureRecognizers ?? [] }
                + (mapView.gestureRecognizers ?? [])
            if recognizers.contains(where: { $0.state == .began || $0.state == .changed }) {
                trackingEnabled = false
            }
        }

        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is HeadingAnnotation else { return nil }
            let identifier = "workout-heading"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? HeadingAnnotationView
                ?? HeadingAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.updateHeading(headingPin.heading)
            return view
        }

        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? ColoredPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = polyline.color
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        static func bearing(from first: CLLocationCoordinate2D, to second: CLLocationCoordinate2D) -> CLLocationDirection {
            let a = first.latitude * .pi / 180
            let b = second.latitude * .pi / 180
            let delta = (second.longitude - first.longitude) * .pi / 180
            let y = sin(delta) * cos(b)
            let x = cos(a) * sin(b) - sin(a) * cos(b) * cos(delta)
            return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        }
    }
}

private final class HeadingAnnotation: MKPointAnnotation {
    var heading: CLLocationDirection = 0
}

private final class HeadingAnnotationView: MKAnnotationView {
    private let arrow = UIImageView(image: UIImage(systemName: "location.north.fill"))

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backgroundColor = .systemGreen
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        arrow.tintColor = .white
        arrow.contentMode = .scaleAspectFit
        arrow.frame = bounds.insetBy(dx: 10, dy: 10)
        addSubview(arrow)
        canShowCallout = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func updateHeading(_ heading: CLLocationDirection) {
        arrow.transform = CGAffineTransform(rotationAngle: heading * .pi / 180)
    }
}

private final class ColoredPolyline: MKPolyline {
    var color: UIColor = .systemBlue
}

// MARK: - SwiftUI Previews (Xcode Canvas 시각적 테스트용)
struct WorkoutMapView_Previews: PreviewProvider {
    
    // 1. 정적 운동 (클라이밍, 트레드밀 등) 더미 데이터
    static var staticSummaryMock: StaticLocationSummary {
        StaticLocationSummary(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780), // 서울시청
            sampleCount: 150
        )
    }
    
    // 2. 동적 운동 (달리기 경로 및 속도별 Pace) 더미 데이터
    static var paceSegmentsMock: [PaceSegment] {
        let baseLat = 37.5665
        let baseLon = 126.9780
        
        return [
            // 구간 1: 느림 (노란색)
            PaceSegment(
                startCoordinate: CLLocationCoordinate2D(latitude: baseLat, longitude: baseLon),
                endCoordinate: CLLocationCoordinate2D(latitude: baseLat + 0.001, longitude: baseLon + 0.001),
                speedCategory: .slow,
                speedMs: 1.5
            ),
            // 구간 2: 보통 (초록색)
            PaceSegment(
                startCoordinate: CLLocationCoordinate2D(latitude: baseLat + 0.001, longitude: baseLon + 0.001),
                endCoordinate: CLLocationCoordinate2D(latitude: baseLat + 0.002, longitude: baseLon + 0.003),
                speedCategory: .moderate,
                speedMs: 2.2
            ),
            // 구간 3: 빠름 (진한 초록 / 빨간색)
            PaceSegment(
                startCoordinate: CLLocationCoordinate2D(latitude: baseLat + 0.002, longitude: baseLon + 0.003),
                endCoordinate: CLLocationCoordinate2D(latitude: baseLat + 0.004, longitude: baseLon + 0.004),
                speedCategory: .veryFast,
                speedMs: 4.5
            )
        ]
    }
    
    static var previews: some View {
        Group {
            // 정적 운동 지도 렌더링
            WorkoutMapView(
                workoutType: .staticWorkout,
                staticSummary: staticSummaryMock
            )
            .previewDisplayName("정적 운동 (클라이밍)")
            
            // 동적 운동 지도 렌더링 (Pace 그라데이션)
            WorkoutMapView(
                workoutType: .dynamicWorkout,
                paceSegments: paceSegmentsMock
            )
            .previewDisplayName("동적 운동 (러닝 Pace)")
        }
    }
}
