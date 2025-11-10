//
//  ARSurveyCoordinator.swift
//  TapResolver
//
//  Coordinates AR session for survey mode
//

import Foundation
import ARKit
import Combine
import UIKit

class ARSurveyCoordinator: NSObject, ObservableObject {
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var featurePointCount: Int = 0
    @Published var planeCount: Int = 0
    @Published var isReadyToSave: Bool = false
    
    let session: ARSession  // ✅ Public instance, not shared static
    private let arWorldMapStore: ARWorldMapStore
    
    init(arWorldMapStore: ARWorldMapStore) {
        self.session = ARSession()  // Each coordinator gets its own session
        self.arWorldMapStore = arWorldMapStore
        super.init()
        // Set session delegate for frame updates
        session.delegate = self
        print("🔧 ARSurveyCoordinator initialized - session delegate set")
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
    
    func captureMap(center2D: CGPoint? = nil,
                    patchName: String? = nil,
                    completion: @escaping (Result<Void, Error>) -> Void) {
        session.getCurrentWorldMap { [weak self] map, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to capture map: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let map = map else {
                let err = NSError(domain: "ARSurvey", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No map returned"])
                completion(.failure(err))
                return
            }
            
            do {
                if let center = center2D {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    let featureCount = map.rawFeaturePoints.points.count
                    let meta = WorldMapPatchMeta(
                        name: patchName ?? "Patch \(Date().timeIntervalSince1970)",
                        featureCount: featureCount,
                        byteSize: data.count,
                        center2D: center,
                        radiusM: 15.0
                    )
                    try self.arWorldMapStore.savePatch(map, meta: meta)
                } else {
                    try self.arWorldMapStore.saveGlobalMap(map)
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension ARSurveyCoordinator: ARSCNViewDelegate, ARSessionDelegate {
    // Visualize detected planes
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let plane = SCNPlane(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: CGFloat(planeAnchor.planeExtent.height)
        )

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
        material.isDoubleSided = true
        plane.materials = [material]

        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)
    }

    // Update plane visualization as it grows
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane else { return }

        plane.width = CGFloat(planeAnchor.planeExtent.width)
        plane.height = CGFloat(planeAnchor.planeExtent.height)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Extract values immediately without retaining frame
        let points = frame.rawFeaturePoints?.points.count ?? 0
        let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }.count
        let state = frame.camera.trackingState

        // Log periodically to confirm delegate firing
        let frameTimestamp = frame.timestamp
        if Int(frameTimestamp * 60) % 30 == 0 {
            print("📊 Frame update - Features: \(points), Planes: \(planes), State: \(state)")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.trackingState = state
            self.featurePointCount = points
            self.planeCount = planes
            
            let wasReady = self.isReadyToSave
            // ✅ Lowered thresholds for testing
            self.isReadyToSave = (self.trackingState == .normal &&
                                  self.featurePointCount > 100 &&
                                  self.planeCount >= 1)
            
            // Log when first ready
            if !wasReady && self.isReadyToSave {
                print("✅ Survey READY - Features: \(points), Planes: \(planes)")
            }
        }
    }
}