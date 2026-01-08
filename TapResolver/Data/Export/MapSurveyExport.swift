//
//  MapSurveyExport.swift
//  TapResolver
//
//  Data structures for .mapsurvey JSON export format.
//

import Foundation
import UIKit

/// Root structure for .mapsurvey export file
struct MapSurveyExport: Codable {
    let schema: String
    let exportedAt: String
    let collector: CollectorInfo
    let location: LocationInfo
    let beaconReference: [BeaconReferenceInfo]
    let surveyPoints: [SurveyPoint]
    
    init(
        collector: CollectorInfo,
        location: LocationInfo,
        beaconReference: [BeaconReferenceInfo],
        surveyPoints: [SurveyPoint]
    ) {
        self.schema = "tapresolver.mapsurvey.v1"
        self.exportedAt = ISO8601DateFormatter().string(from: Date())
        self.collector = collector
        self.location = location
        self.beaconReference = beaconReference
        self.surveyPoints = surveyPoints
    }
}

struct CollectorInfo: Codable {
    let initials: String
    let device: String
    let app: String
    
    init(initials: String) {
        self.initials = initials
        self.device = UIDevice.current.model
        self.app = "TapResolver iOS \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
    }
}

struct LocationInfo: Codable {
    let id: String
    let name: String
    let pixelsPerMeter: Double?
    let mapDimensions_px: [Int]?
}

struct BeaconReferenceInfo: Codable {
    let beaconID: String
    let mapX_px: Double
    let mapY_px: Double
    let elevation_m: Double?
    let txPower_dBm: Int?
}

