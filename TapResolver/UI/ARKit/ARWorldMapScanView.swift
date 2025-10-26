//
//  ARWorldMapScanView.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/26/25.
//


//
//  ARWorldMapScanView.swift
//  TapResolver
//
//  Role: Full-screen AR interface for scanning and saving world maps
//

import SwiftUI
import ARKit

struct ARWorldMapScanView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    
    @State private var mappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    @State private var featurePointCount: Int = 0
    @State private var planeCount: Int = 0
    @State private var scanDuration: TimeInterval = 0.0
    @State private var scanStartTime: Date?
    @State private var canSave: Bool = false
    @State private var isSaving: Bool = false
    @State private var isExtending: Bool = false
    @State private var saveWindowEndTime: Date? = nil
    
    private let minFeaturePoints = 500  // Minimum for "good" quality
    
    var body: some View {
        ZStack {
            // AR Camera feed
            ARWorldMapScanViewContainer(
                mappingStatus: $mappingStatus,
                featurePointCount: $featurePointCount,
                planeCount: $planeCount,
                isExtending: isExtending,
                worldMapStore: worldMapStore
            )
            .ignoresSafeArea()
            
            // Top bar
            VStack {
                topBar
                Spacer()
            }
            
            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }
        }
        .onAppear {
            isExtending = worldMapStore.metadata.exists
            scanStartTime = Date()
            startDurationTimer()
        }
        .onChange(of: mappingStatus) { _, newStatus in
            updateSaveEligibility(newStatus)
        }
        .onChange(of: featurePointCount) { _, _ in
            updateSaveEligibility(mappingStatus)
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Close button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 60)
            .padding(.leading, 20)
            
            Spacer()
            
            // Status indicator
            statusBadge
                .padding(.top, 60)
                .padding(.trailing, 20)
        }
    }
    
    private var statusBadge: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(statusText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(statusDetail)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusColor.opacity(0.85))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 4)
    }
    
    private var statusText: String {
        switch mappingStatus {
        case .notAvailable:
            return "Initializing..."
        case .limited:
            return "Limited"
        case .extending:
            return isExtending ? "Extending Map" : "Extending"
        case .mapped:
            return "Mapped"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var statusDetail: String {
        return "\(featurePointCount) points • \(planeCount) planes"
    }
    
    private var statusColor: Color {
        switch mappingStatus {
        case .notAvailable:
            return .gray
        case .limited:
            return .red
        case .extending:
            return .yellow
        case .mapped:
            return .green
        @unknown default:
            return .gray
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Instructions
            instructionsCard
            
            // Timer
            timerDisplay
            
            // Save button
            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Scanning Instructions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Status-specific instructions
            if mappingStatus == .limited {
                Text("• Point at textured surfaces (walls, floors, furniture)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.yellow)
            } else if mappingStatus == .extending {
                Text("• Keep moving slowly - building map...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            } else if mappingStatus == .mapped {
                Text("• Map is ready! You can save or keep scanning")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Text("• Move slowly around the space")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
            Text("• Avoid smooth, featureless surfaces")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
            
            if !canSave {
                if featurePointCount < minFeaturePoints {
                    Text("Coverage: \(featurePointCount) / \(minFeaturePoints) points")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
    }
    
    private var timerDisplay: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.white)
            Text(formatDuration(scanDuration))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
    
    private var saveButton: some View {
        Button(action: {
            saveWorldMap()
        }) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: canSave ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                }
                
                Text(isSaving ? "Saving..." : (isExtending ? "Save Extension" : "Save AR Environment"))
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSave && !isSaving ? Color.green : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!canSave || isSaving)
    }
    
    // MARK: - Actions
    
    private func saveWorldMap() {
        isSaving = true
        
        // Trigger save via notification
        NotificationCenter.default.post(
            name: .saveARWorldMap,
            object: nil,
            userInfo: [
                "action": isExtending ? "extension" : "initial_scan",
                "duration_s": scanDuration,
                "areaCovered": isExtending ? "Extended area" : "Initial scan"
            ]
        )
        
        // Close after 2 seconds (gives time for save to complete)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPresented = false
        }
    }
    
    private func updateSaveEligibility(_ status: ARFrame.WorldMappingStatus) {
        let meetsThreshold = (status == .mapped || status == .extending) && featurePointCount >= minFeaturePoints
        
        // Peak detector: once threshold is met, keep button green for 5 seconds
        if meetsThreshold {
            saveWindowEndTime = Date().addingTimeInterval(5.0)
            canSave = true
        } else if let endTime = saveWindowEndTime, Date() < endTime {
            // Still within the 5-second window
            canSave = true
        } else {
            // Threshold not met and window expired
            canSave = false
            saveWindowEndTime = nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startDurationTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = scanStartTime {
                scanDuration = Date().timeIntervalSince(start)
            }
        }
    }
}

// MARK: - ARKit Container

extension Notification.Name {
    static let saveARWorldMap = Notification.Name("saveARWorldMap")
}

struct ARWorldMapScanViewContainer: UIViewRepresentable {
    @Binding var mappingStatus: ARFrame.WorldMappingStatus
    @Binding var featurePointCount: Int
    @Binding var planeCount: Int
    let isExtending: Bool
    let worldMapStore: ARWorldMapStore
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator  // ✅ CRITICAL: Enable session callbacks
        arView.scene = SCNScene()
        arView.automaticallyUpdatesLighting = true
        
        // Enable ARKit's built-in feature point visualization
        arView.debugOptions = [.showFeaturePoints]
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        // ✅ ENABLE LIDAR: Use scene reconstruction if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
            print("✅ LiDAR mesh reconstruction enabled")
        }
        
        // If extending, load existing map
        if isExtending, let worldMap = worldMapStore.loadWorldMap() {
            configuration.initialWorldMap = worldMap
            print("🔄 Loaded existing world map for extension")
        }
        
        // ✅ CRITICAL: Reset tracking on start
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        context.coordinator.arView = arView
        context.coordinator.worldMapStore = worldMapStore
        
        print("📷 AR World Map scanning started (with proper initialization)")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(mappingStatus: $mappingStatus,
                    featurePointCount: $featurePointCount,
                    planeCount: $planeCount)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var arView: ARSCNView?
        weak var worldMapStore: ARWorldMapStore?
        
        private var lastTrackingState: ARCamera.TrackingState?
        private var sessionStartTime: Date?
        private var lastUIUpdate: Date = Date()
        private var maxFeaturePointCount: Int = 0
        private var maxPlaneCount: Int = 0
        
        @Binding var mappingStatus: ARFrame.WorldMappingStatus
        @Binding var featurePointCount: Int
        @Binding var planeCount: Int
        
        private var saveObserver: NSObjectProtocol?
        
        init(mappingStatus: Binding<ARFrame.WorldMappingStatus>,
             featurePointCount: Binding<Int>,
             planeCount: Binding<Int>) {
            self._mappingStatus = mappingStatus
            self._featurePointCount = featurePointCount
            self._planeCount = planeCount
            super.init()
            
            self.sessionStartTime = Date()
            
            // Listen for save requests
            saveObserver = NotificationCenter.default.addObserver(
                forName: .saveARWorldMap,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleSaveRequest(notification)
            }
        }
        
        deinit {
            if let observer = saveObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Throttle updates to 3 times per second to prevent erratic UI
            let now = Date()
            if now.timeIntervalSince(lastUIUpdate) < 0.33 {
                return
            }
            lastUIUpdate = now
            
            // Update mapping status
            mappingStatus = frame.worldMappingStatus
            
            // Update feature point count (use running maximum to prevent decreasing numbers)
            let currentCount = frame.rawFeaturePoints?.points.count ?? 0
            if currentCount > maxFeaturePointCount {
                maxFeaturePointCount = currentCount
            }
            featurePointCount = maxFeaturePointCount
            
            // Update plane count (also use running maximum)
            let currentPlanes = session.currentFrame?.anchors.filter { $0 is ARPlaneAnchor }.count ?? 0
            if currentPlanes > maxPlaneCount {
                maxPlaneCount = currentPlanes
            }
            planeCount = maxPlaneCount
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            // Track state changes for debugging
            if lastTrackingState != camera.trackingState {
                lastTrackingState = camera.trackingState
                
                switch camera.trackingState {
                case .notAvailable:
                    print("🚫 AR Tracking: Not Available")
                case .limited(let reason):
                    let reasonText: String
                    switch reason {
                    case .excessiveMotion:
                        reasonText = "Excessive Motion - Move slower"
                    case .insufficientFeatures:
                        reasonText = "Insufficient Features - Point at textured surfaces"
                    case .initializing:
                        reasonText = "Initializing - Hold steady"
                    case .relocalizing:
                        reasonText = "Relocalizing - Look around slowly"
                    @unknown default:
                        reasonText = "Unknown"
                    }
                    print("⚠️ AR Tracking Limited: \(reasonText)")
                case .normal:
                    print("✅ AR Tracking: Normal")
                    
                    // Check if we took too long to get tracking
                    if let startTime = sessionStartTime {
                        let elapsed = Date().timeIntervalSince(startTime)
                        print("   Tracking achieved after \(String(format: "%.1f", elapsed))s")
                    }
                @unknown default:
                    print("❓ AR Tracking: Unknown state")
                }
            }
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⏸️ AR Session interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("▶️ AR Session resumed")
            
            // Restart session after interruption
            guard let arView = arView else { return }
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.environmentTexturing = .automatic
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
        private func handleSaveRequest(_ notification: Notification) {
            guard let arView = arView,
                  let userInfo = notification.userInfo,
                  let action = userInfo["action"] as? String,
                  let duration = userInfo["duration_s"] as? Double,
                  let area = userInfo["areaCovered"] as? String else {
                print("❌ Invalid save request")
                return
            }
            
            arView.session.getCurrentWorldMap { [weak self] worldMap, error in
                guard let worldMap = worldMap else {
                    print("❌ Failed to get world map: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.worldMapStore?.saveWorldMap(worldMap,
                                                  action: action,
                                                  duration_s: duration,
                                                  areaCovered: area)
            }
        }
    }
}