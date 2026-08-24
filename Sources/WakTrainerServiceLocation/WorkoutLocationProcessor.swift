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
    
    // 1. 정적 운동 (대표 위치 중심점 계산)
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
    
    // 2. 동적 운동 (Pace 구간별 선분 생성)
    public func processDynamicWorkout(locations: [CLLocation]) -> [PaceSegment] {
        guard locations.count >= 2 else { return [] }
        
        var segments: [PaceSegment] = []
        
        for i in 0..<(locations.count - 1) {
            let startLoc = locations[i]
            let endLoc = locations[i + 1]
            
            let distance = endLoc.distance(from: startLoc)
            let timeInterval = endLoc.timestamp.timeIntervalSince(startLoc.timestamp)
            
            let speed: Double = timeInterval > 0 ? (distance / timeInterval) : max(0, endLoc.speed)
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
