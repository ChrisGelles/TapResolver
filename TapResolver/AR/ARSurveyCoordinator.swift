//
//  ARSurveyCoordinator.swift
//  TapResolver
//
//  Coordinates AR session for survey mode
//

import Foundation
import ARKit
import Combine

class ARSurveyCoordinator: NSObject, ObservableObject {
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var featurePointCount: Int = 0
    @Published var planeCount: Int = 0
    @Published var isReadyToSave: Bool = false
    
    private let session = ARSession()
    private let arWorldMapStore: ARWorldMapStore
    
    init(arWorldMapStore: ARWorldMapStore) {
        self.arWorldMapStore = arWorldMapStore
        super.init()
        session.delegate = self
    }
    
    func startSurvey() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        print("🚀 Survey started")
    }
    
    func stopSurvey() {
        session.pause()
        print("⏸️ Survey stopped")
    }
    
    func captureMap(completion: @escaping (Result<Void, Error>) -> Void) {
        session.getCurrentWorldMap { [weak self] map, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to capture map: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let map = map else {
                completion(.failure(NSError(domain: "ARSurvey", code: -1, userInfo: [NSLocalizedDescriptionKey: "No map returned"])))
                return
            }
            
            do {
                try self.arWorldMapStore.saveGlobalMap(map)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension ARSurveyCoordinator: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.trackingState = frame.camera.trackingState
            
            // Count feature points
            if let pointCloud = session.currentFrame?.rawFeaturePoints {
                self.featurePointCount = pointCloud.points.count
            }
            
            // Count planes
            let planes = session.currentFrame?.anchors.compactMap { $0 as? ARPlaneAnchor } ?? []
            self.planeCount = planes.count
            
            // Determine if ready
            self.isReadyToSave = self.trackingState == .normal &&
                                 self.featurePointCount > 1000 &&
                                 self.planeCount >= 2
        }
    }
}