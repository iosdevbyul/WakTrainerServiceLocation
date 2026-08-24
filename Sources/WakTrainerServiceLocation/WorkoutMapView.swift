//
//  WorkoutMapView.swift
//  WakTrainerServiceLocation
//
//  Created by COMATOKI on 2026-08-25.
//

import SwiftUI
import MapKit
import WakTrainerCoreModels

public struct WorkoutMapView: View {
    public let workoutType: WorkoutType
    public let staticSummary: StaticLocationSummary?
    public let paceSegments: [PaceSegment]
    
    @State private var cameraPosition: MapCameraPosition
    
    public init(
        workoutType: WorkoutType,
        staticSummary: StaticLocationSummary? = nil,
        paceSegments: [PaceSegment] = []
    ) {
        self.workoutType = workoutType
        self.staticSummary = staticSummary
        self.paceSegments = paceSegments
        
        // initial camera center coordinate
        let initialCoordinate: CLLocationCoordinate2D
        if workoutType == .staticWorkout, let staticSummary {
            initialCoordinate = staticSummary.centerCoordinate
        } else if let firstSegment = paceSegments.first {
            initialCoordinate = firstSegment.startCoordinate
        } else {
            initialCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        }
        
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    public var body: some View {
        Map(position: $cameraPosition) {
            switch workoutType {
            case .staticWorkout:
                // 정적 운동: 한 공간 단일 핀
                if let staticSummary {
                    Annotation("운동 장소", coordinate: staticSummary.centerCoordinate) {
                        Image(systemName: "figure.climbing")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                
            case .dynamicWorkout:
                // 동적 운동: Pace별 선분 다중 렌더링
                ForEach(paceSegments) { segment in
                    MapPolyline(coordinates: [segment.startCoordinate, segment.endCoordinate])
                        .stroke(color(for: segment.speedCategory), lineWidth: 5)
                }
                
                // 시작점 / 종료점 표시
                if let start = paceSegments.first?.startCoordinate {
                    Annotation("시작", coordinate: start) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                            .background(Circle().fill(.white))
                    }
                }
                
                if let end = paceSegments.last?.endCoordinate {
                    Annotation("도착", coordinate: end) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .foregroundColor(.red)
                            .background(Circle().fill(.white))
                    }
                }
            }
        }
    }
    
    // Pace 구간별 선 색상 매핑
    private func color(for category: SpeedCategory) -> Color {
        switch category {
        case .verySlow:  return .yellow
        case .slow:      return Color(red: 0.9, green: 0.7, blue: 0.0)
        case .moderate:  return .green
        case .brisk:     return Color(red: 0.0, green: 0.6, blue: 0.2)
        case .fast:      return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .veryFast:  return .red
        }
    }
}
