//
//  WorkoutLocationProcessor.swift
//  WakTrainerServiceLocation
//
//  Created by COMATOKI on 2026-08-25.
//

import Foundation
import CoreLocation
import WakTrainerCoreModels

public final class WorkoutLocationProcessor: Sendable {
    
    public init() {}
    
    // MARK: - 1. 정적 운동 대표 위치 산출 (중심 지점)
    public func processStaticWorkout(locations: [CLLocation]) -> StaticLocationSummary? {
        guard !locations.isEmpty else { return nil }
        
        var totalLat: Double = 0
        var totalLon: Double = 0
        
        for loc in locations {
            totalLat += loc.coordinate.latitude
            totalLon += loc.coordinate.longitude
        }
        
        let centerCoordinate = CLLocationCoordinate2D(
            latitude: totalLat / Double(locations.count),
            longitude: totalLon / Double(locations.count)
        )
        
        return StaticLocationSummary(
            centerCoordinate: centerCoordinate,
            sampleCount: locations.count
        )
    }
    
    // MARK: - 2. 동적 운동 Pace 분석 (속도별 그라데이션 세그먼트 생성)
    public func processDynamicWorkout(locations: [CLLocation]) -> [PaceSegment] {
        guard locations.count >= 2 else { return [] }
        
        var segments: [PaceSegment] = []
        
        for i in 0..<(locations.count - 1) {
            let startLoc = locations[i]
            let endLoc = locations[i + 1]
            
            // 두 좌표 간 거리(m) 및 시간 차이(s)로 속도(m/s) 계산
            let distance = endLoc.distance(from: startLoc)
            let timeInterval = endLoc.timestamp.timeIntervalSince(startLoc.timestamp)
            
            let speed: Double
            if timeInterval > 0 {
                speed = distance / timeInterval
            } else {
                speed = max(0, endLoc.speed)
            }
            
            let category = SpeedCategory.category(forSpeed: speed)
            
            let segment = PaceSegment(
                startCoordinate: startLoc.coordinate,
                endCoordinate: endLoc.coordinate,
                speedCategory: category,
                speedMs: speed
            )
            segments.append(segment)
        }
        
        return segments
    }
}
