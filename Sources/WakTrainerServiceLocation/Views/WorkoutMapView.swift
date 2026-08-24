//
//  WorkoutMapView.swift
//  WakTrainerServiceLocation
//
//  Created by COMATOKI on 2026-08-25.
//

import SwiftUI
import MapKit
import UIKit
import WakTrainerCoreModels

public struct WorkoutMapView: UIViewRepresentable {
    public let workoutType: WorkoutType
    public let staticSummary: StaticLocationSummary?
    public let paceSegments: [PaceSegment]
    
    public init(
        workoutType: WorkoutType,
        staticSummary: StaticLocationSummary? = nil,
        paceSegments: [PaceSegment] = []
    ) {
        self.workoutType = workoutType
        self.staticSummary = staticSummary
        self.paceSegments = paceSegments
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        return mapView
    }
    
    public func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        switch workoutType {
        case .staticWorkout:
            guard let staticSummary else { return }
            let annotation = MKPointAnnotation()
            annotation.coordinate = staticSummary.centerCoordinate
            annotation.title = "운동 장소"
            mapView.addAnnotation(annotation)
            
            let region = MKCoordinateRegion(
                center: staticSummary.centerCoordinate,
                latitudinalMeters: 200,
                longitudinalMeters: 200
            )
            mapView.setRegion(region, animated: true)
            
        case .dynamicWorkout:
            guard !paceSegments.isEmpty else { return }
            
            // 1. 각 PaceSegment별 MKPolyline 생성 및 추가
            for segment in paceSegments {
                var coords = [segment.startCoordinate, segment.endCoordinate]
                let polyline = ColoredPolyline(coordinates: &coords, count: 2)
                polyline.color = uiColor(for: segment.speedCategory)
                mapView.addOverlay(polyline)
            }
            
            // 2. 시작점 / 도착점 핀 추가
            if let first = paceSegments.first {
                let startPin = MKPointAnnotation()
                startPin.coordinate = first.startCoordinate
                startPin.title = "시작"
                mapView.addAnnotation(startPin)
            }
            
            if let last = paceSegments.last {
                let endPin = MKPointAnnotation()
                endPin.coordinate = last.endCoordinate
                endPin.title = "도착"
                mapView.addAnnotation(endPin)
            }
            
            // 3. 경로 전체가 보이도록 카메라 영역 자동 맞춤
            let coordinates = paceSegments.flatMap { [$0.startCoordinate, $0.endCoordinate] }
            let rect = polylineBoundingRect(for: coordinates)
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
        }
    }
    
    private func polylineBoundingRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        var rect = MKMapRect.null
        for coord in coordinates {
            let point = MKMapPoint(coord)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
            rect = rect.union(pointRect)
        }
        return rect
    }
    
    private func uiColor(for category: SpeedCategory) -> UIColor {
        switch category {
        case .verySlow:  return .systemYellow
        case .slow:      return UIColor(red: 0.9, green: 0.7, blue: 0.0, alpha: 1.0)
        case .moderate:  return .systemGreen
        case .brisk:     return UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 1.0)
        case .fast:      return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        case .veryFast:  return .systemRed
        }
    }
    
    // MARK: - Coordinator
    public class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WorkoutMapView
        
        init(_ parent: WorkoutMapView) {
            self.parent = parent
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let coloredPolyline = overlay as? ColoredPolyline {
                let renderer = MKPolylineRenderer(polyline: coloredPolyline)
                renderer.strokeColor = coloredPolyline.color
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// 개별 선분 색상 보관용 커스텀 MKPolyline
private class ColoredPolyline: MKPolyline {
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
