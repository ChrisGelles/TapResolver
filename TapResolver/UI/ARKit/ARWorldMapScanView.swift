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
    let patchIDToExtend: UUID?
    let isAnchorMode: Bool  // NEW: Distinguish extend vs anchor mode
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    
    @State private var mappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    @State private var featurePointCount: Int = 0
    @State private var planeCount: Int = 0
    @State private var scanDuration: TimeInterval = 0.0
    @State private var scanStartTime: Date?
    @State private var canSave: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveWindowEndTime: Date? = nil
    @State private var showNamePrompt = false
    @State private var patchName: String = ""
    @State private var relocalizationStatus: String = ""
    @State private var relocalizationTimer: Timer?
    @State private var relocalizationStartTime: Date?
    @State private var isRelocalized: Bool = false
    @State private var showRelocalizationTimeout = false
    @State private var isMarkingAnchors = false
    @State private var showAnchorNamePrompt = false
    @State private var pendingAnchorName: String = ""
    @State private var pendingAnchorData: (anchor: ARAnchor, points: [RawFeaturePoint])? = nil
    @State private var placedAnchors: [(name: String, position: SIMD3<Float>, isLinked: Bool)] = []
    
    private let minFeaturePoints = 500  // Minimum for "good" quality
    
    private var isExtending: Bool {
        return patchIDToExtend != nil && !isAnchorMode
    }

    private var isSettingAnchors: Bool {
        return patchIDToExtend != nil && isAnchorMode
    }
    
    private var existingFeatureNames: [String] {
        return worldMapStore.existingFeatureNames()
    }

    private var filteredFeatureNames: [String] {
        let trimmed = pendingAnchorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return existingFeatureNames }
        
        return existingFeatureNames.filter { name in
            name.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    var body: some View {
        ZStack {
            // AR Camera feed
            ARWorldMapScanViewContainer(
                mappingStatus: $mappingStatus,
                featurePointCount: $featurePointCount,
                planeCount: $planeCount,
                isExtending: isExtending,
                worldMapStore: worldMapStore,
                patchIDToExtend: patchIDToExtend
            )
            .ignoresSafeArea()
            
            // Top bar
            VStack {
                topBar
                Spacer()
            }
            
            // Relocalization status overlay (when extending)
            if isExtending && !relocalizationStatus.isEmpty {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        HStack {
                            if relocalizationStatus.contains("✅") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if relocalizationStatus.contains("⚠️") {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(relocalizationStatus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Helpful tips during relocalization
                        if relocalizationStatus.contains("Matching") {
                            Text("💡 Look for distinctive features you scanned before")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        // Failed relocalization options
                        if relocalizationStatus.contains("⚠️") {
                            HStack(spacing: 12) {
                                Button(action: {
                                    retryRelocalization()
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    startFreshPatch()
                                }) {
                                    Text("Start Fresh")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    relocalizationStatus = ""
                                    isPresented = false
                                }) {
                                    Text("Exit")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .padding(.bottom, 140)
                }
            }
            
            // Crosshair for anchor marking
            if isMarkingAnchors {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // Crosshair
                            ZStack {
                                Circle()
                                    .stroke(Color.orange, lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: 20, height: 2)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: 2, height: 20)
                            }
                            
                            Text("Tap to mark anchor area")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(8)
                                .padding(.top, 12)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    Spacer() // Push to upper half
                }
            }
            
            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }
        }
        .onTapGesture {
            if isMarkingAnchors {
                handleAnchorTap()
            }
        }
        .onAppear {
            scanStartTime = Date()
            startDurationTimer()
            
            if isExtending {
                relocalizationStatus = "Matching to saved map... (30s)"
                startRelocalizationTimer()
            }
            
            // Listen for relocalization success
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ARRelocalizationSuccess"),
                object: nil,
                queue: .main
            ) { _ in
                if !isRelocalized {
                    isRelocalized = true
                    print("✅ Relocalization successful")
                    
                    // Show existing anchor disks from this patch
                    if let patchID = patchIDToExtend {
                        // Load and display existing anchors
                        let instances = worldMapStore.anchorAreas(forPatch: patchID)
                        for instance in instances {
                            guard let featureName = worldMapStore.featureName(for: instance.id) else { continue }
                            
                            // Check if linked
                            let feature = worldMapStore.anchorFeatures.first { $0.id == instance.featureID }
                            let isLinked = (feature?.instanceIDs.count ?? 0) > 1
                            
                            // Notify coordinator to render disk
                            NotificationCenter.default.post(
                                name: NSNotification.Name("RenderExistingAnchor"),
                                object: nil,
                                userInfo: [
                                    "instance": instance,
                                    "name": featureName,
                                    "isLinked": isLinked
                                ]
                            )
                        }
                        
                        print("🎯 Loaded \(instances.count) existing anchor(s) for this patch")
                    }
                }
            }
            
            // Listen for anchor data captured
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AnchorDataCaptured"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let anchor = userInfo["anchor"] as? ARAnchor,
                   let rawPoints = userInfo["rawPoints"] as? [RawFeaturePoint] {
                    
                    pendingAnchorData = (anchor, rawPoints)
                    pauseARSession()
                    showAnchorNamePrompt = true
                }
            }
        }
        .onDisappear {
            relocalizationTimer?.invalidate()
        }
        .onChange(of: mappingStatus) { _, newStatus in
            updateSaveEligibility(newStatus)
        }
        .onChange(of: featurePointCount) { _, _ in
            updateSaveEligibility(mappingStatus)
        }
        .sheet(isPresented: $showNamePrompt) {
            PatchNamePromptView(
                patchName: $patchName,
                onSave: {
                    saveAsPatch()
                },
                onCancel: {
                    showNamePrompt = false
                    resumeARSession()  // Resume camera when cancelled
                }
            )
            .presentationDetents([.height(280)])
            .onDisappear {
                // Resume camera when sheet dismissed (if not saving)
                if !isSaving {
                    resumeARSession()
                }
            }
        }
        .sheet(isPresented: $showAnchorNamePrompt) {
            AnchorFeatureNamePromptView(
                featureName: $pendingAnchorName,
                existingNames: filteredFeatureNames,
                patchID: patchIDToExtend ?? UUID(), // Use current patch
                worldMapStore: worldMapStore,
                onSave: {
                    saveAnchorArea()
                },
                onCancel: {
                    showAnchorNamePrompt = false
                    pendingAnchorName = ""
                    pendingAnchorData = nil
                    resumeARSession()
                }
            )
            .presentationDetents([.height(400)])
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
            if isAnchorMode {
                Text("🎯 Set Anchors Mode")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
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
            // Instructions (hide when extending - relocalization status shows instead)
            if !isExtending {
                instructionsCard
            }
            
            // Timer
            timerDisplay
            
            // Control buttons row
            HStack(spacing: 12) {
                // Mark Anchor toggle - ONLY in anchor mode
                if isAnchorMode {
                    Button(action: {
                        isMarkingAnchors.toggle()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: isMarkingAnchors ? "paintbrush.fill" : "paintbrush")
                                .font(.system(size: 20))
                            Text("Mark Anchor")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(width: 90)
                        .padding(.vertical, 10)
                        .background(isMarkingAnchors ? Color.orange : Color.white.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                
                // Save button
                saveButton
            }
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
            if isExtending {
                // When extending, save directly without prompting for name
                saveExtension()
            } else {
                // When creating new patch, pause camera and prompt for name
                pauseARSession()
                showNamePrompt = true
            }
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
                
                Text(isSaving ? "Saving..." : (isAnchorMode ? "Save Features" : (isExtending ? "Save Extension" : "Save Patch")))
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
    
    private func saveExtension() {
        // In anchor mode, don't save spatial data
        if isAnchorMode {
            print("🎯 Anchor mode - features saved, spatial data unchanged")
            isPresented = false
            return
        }
        
        guard let patchID = patchIDToExtend,
              let patch = worldMapStore.patches.first(where: { $0.id == patchID }) else {
            print("❌ Cannot extend: Patch not found")
            return
        }
        
        guard !isSaving else { return }
        isSaving = true
        
        print("💾 Saving extension to '\(patch.name)'...")
        
        NotificationCenter.default.post(
            name: .saveARWorldMap,
            object: nil,
            userInfo: [
                "isPatch": true,
                "patchID": patchID,
                "duration": scanDuration,
                "areaCovered": "Extended area"
            ]
        )
        
        // Close after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            isPresented = false
        }
    }
    
    private func saveAsPatch() {
        guard !isSaving else { return }
        
        // Validate patch name
        let trimmedName = patchName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            print("❌ Cannot save patch with empty name")
            return
        }
        
        isSaving = true
        
        NotificationCenter.default.post(
            name: .saveARWorldMap,
            object: nil,
            userInfo: [
                "isPatch": true,
                "patchName": trimmedName,
                "action": "initial_scan",
                "duration": scanDuration,
                "areaCovered": "Scanned area"
            ]
        )
        
        // Close after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            showNamePrompt = false
            patchName = "" // Reset for next time
            isPresented = false
        }
    }
    
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
        if isExtending {
            // When extending, must be relocalized first
            canSave = isRelocalized && scanDuration >= 3.0
        } else {
            // When creating new patch, just need minimum duration
            canSave = scanDuration >= 3.0
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
    
    private func retryRelocalization() {
        relocalizationStatus = ""
        isRelocalized = false
        
        // Restart AR session
        NotificationCenter.default.post(
            name: NSNotification.Name("RestartARSession"),
            object: nil,
            userInfo: ["patchID": patchIDToExtend as Any]
        )
        
        startRelocalizationTimer()
    }

    private func startFreshPatch() {
        // Clear extension mode and start as new patch
        relocalizationStatus = ""
        isPresented = false
        
        // Re-open without patch ID (will create new)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = true
        }
    }
    
    private func pauseARSession() {
        NotificationCenter.default.post(
            name: NSNotification.Name("PauseARSession"),
            object: nil
        )
    }

    private func resumeARSession() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ResumeARSession"),
            object: nil
        )
    }

    private func startRelocalizationTimer() {
        relocalizationStartTime = Date()
        relocalizationTimer?.invalidate()
        
        relocalizationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let startTime = relocalizationStartTime else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            if isRelocalized {
                relocalizationTimer?.invalidate()
                relocalizationStatus = "✅ Matched! You can now extend this patch."
            } else if elapsed >= 30.0 {
                relocalizationTimer?.invalidate()
                relocalizationStatus = "⚠️ Couldn't match camera view to saved map"
                showRelocalizationTimeout = true
            } else {
                let remaining = Int(30.0 - elapsed)
                relocalizationStatus = "Matching to saved map... (\(remaining)s)"
            }
        }
    }
    
    private func handleAnchorTap() {
        // Request anchor placement from coordinator
        NotificationCenter.default.post(
            name: NSNotification.Name("PlaceAnchorArea"),
            object: nil
        )
    }

    private func saveAnchorArea() {
        guard let data = pendingAnchorData,
              !pendingAnchorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Cannot save anchor: missing data")
            return
        }
        
        let trimmedName = pendingAnchorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentPatchID = patchIDToExtend ?? UUID() // This should be the actual current patch
        
        // Check if name already exists in this patch
        if worldMapStore.featureExists(named: trimmedName, inPatch: currentPatchID) {
            print("❌ Feature '\(trimmedName)' already exists in this patch")
            // Show error to user
            return
        }
        
        // Check if this name exists in OTHER patches (for linking)
        let isLinked = worldMapStore.existingFeatureNames().contains(trimmedName)
        
        // Add to store
        worldMapStore.addAnchorArea(
            featureName: trimmedName,
            patchID: currentPatchID,
            arAnchorID: data.anchor.identifier,
            localPosition: SIMD3<Float>(data.anchor.transform.columns.3.x,
                                        data.anchor.transform.columns.3.y,
                                        data.anchor.transform.columns.3.z),
            rawFeaturePoints: data.points
        )
        
        // Add to visual display
        placedAnchors.append((
            name: trimmedName,
            position: SIMD3<Float>(data.anchor.transform.columns.3.x,
                                  data.anchor.transform.columns.3.y,
                                  data.anchor.transform.columns.3.z),
            isLinked: isLinked
        ))
        
        // Notify coordinator to add visual disk
        NotificationCenter.default.post(
            name: NSNotification.Name("AnchorPlaced"),
            object: nil,
            userInfo: [
                "name": trimmedName,
                "anchor": data.anchor,
                "isLinked": isLinked
            ]
        )
        
        // Clean up
        showAnchorNamePrompt = false
        pendingAnchorName = ""
        pendingAnchorData = nil
        
        resumeARSession()
        
        print("✅ Placed anchor area: '\(trimmedName)' (\(isLinked ? "linked" : "new"))")
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
    let patchIDToExtend: UUID?
    
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
        
        // Load existing world map if extending
        if let patchID = patchIDToExtend,
           let worldMap = worldMapStore.loadPatch(patchID) {
            print("📍 Loading patch for extension: \(patchID)")
            configuration.initialWorldMap = worldMap
            
            // Don't reset tracking when extending - preserve loaded map
            arView.session.run(configuration, options: [])
        } else {
            // New patch - reset tracking
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
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
                    planeCount: $planeCount,
                    worldMapStore: worldMapStore,
                    patchIDToExtend: patchIDToExtend)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var arView: ARSCNView?
        weak var worldMapStore: ARWorldMapStore?
        private var patchIDToExtend: UUID?
        
        private var lastTrackingState: ARCamera.TrackingState?
        private var sessionStartTime: Date?
        private var lastUIUpdate: Date = Date()
        private var maxFeaturePointCount: Int = 0
        private var maxPlaneCount: Int = 0
        private var placedAnchorDisks: [UUID: SCNNode] = [:]
        
        @Binding var mappingStatus: ARFrame.WorldMappingStatus
        @Binding var featurePointCount: Int
        @Binding var planeCount: Int
        
        private var saveObserver: NSObjectProtocol?
        
        init(mappingStatus: Binding<ARFrame.WorldMappingStatus>,
             featurePointCount: Binding<Int>,
             planeCount: Binding<Int>,
             worldMapStore: ARWorldMapStore?,
             patchIDToExtend: UUID?) {
            self._mappingStatus = mappingStatus
            self._featurePointCount = featurePointCount
            self._planeCount = planeCount
            self.worldMapStore = worldMapStore
            self.patchIDToExtend = patchIDToExtend
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
            
            // Listen for pause/resume
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePauseSession),
                name: NSNotification.Name("PauseARSession"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleResumeSession),
                name: NSNotification.Name("ResumeARSession"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePlaceAnchor),
                name: NSNotification.Name("PlaceAnchorArea"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAnchorPlaced),
                name: NSNotification.Name("AnchorPlaced"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRenderExistingAnchor),
                name: NSNotification.Name("RenderExistingAnchor"),
                object: nil
            )
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
            
            // Monitor relocalization status when extending
            if patchIDToExtend != nil {
                let status = frame.worldMappingStatus
                
                DispatchQueue.main.async { [weak self] in
                    switch status {
                    case .mapped, .extending:
                        // Successfully relocalized
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ARRelocalizationSuccess"),
                            object: nil
                        )
                    case .limited, .notAvailable:
                        // Still trying to relocalize
                        break
                    @unknown default:
                        break
                    }
                }
            }
            
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
            guard let arView = arView else {
                print("❌ Cannot save: No AR view")
                return
            }
            
            print("💾 Capturing world map...")
            
            arView.session.getCurrentWorldMap { worldMap, error in
                if let error = error {
                    print("❌ Failed to get world map: \(error)")
                    return
                }
                
                guard let worldMap = worldMap else {
                    print("❌ World map is nil")
                    return
                }
                
                guard let userInfo = notification.userInfo else {
                    print("❌ No userInfo in save notification")
                    return
                }
                
                // Check if this is a patch save
                if let isPatch = userInfo["isPatch"] as? Bool, isPatch {
                    // Check if extending existing patch
                    if let patchID = userInfo["patchID"] as? UUID {
                        // Update existing patch
                        let duration = userInfo["duration"] as? Double ?? 0.0
                        let areaCovered = userInfo["areaCovered"] as? String ?? "Extended area"
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.worldMapStore?.updatePatch(
                                patchID,
                                with: worldMap,
                                duration_s: duration,
                                areaCovered: areaCovered
                            )
                        }
                    } else {
                        // Create new patch
                        guard let patchName = userInfo["patchName"] as? String else {
                            print("❌ No patch name provided")
                            return
                        }
                        
                        let action = userInfo["action"] as? String ?? "initial_scan"
                        let duration = userInfo["duration"] as? Double ?? 0.0
                        let areaCovered = userInfo["areaCovered"] as? String ?? "Unknown area"
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.worldMapStore?.savePatch(
                                worldMap,
                                patchName: patchName,
                                action: action,
                                duration_s: duration,
                                areaCovered: areaCovered
                            )
                        }
                    }
                } else {
                    // Legacy save (backward compatibility)
                    let action = userInfo["action"] as? String ?? "initial_scan"
                    let duration = userInfo["duration_s"] as? Double ?? 0.0
                    let areaCovered = userInfo["areaCovered"] as? String ?? "Unknown area"
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.worldMapStore?.saveWorldMap(
                            worldMap,
                            action: action,
                            duration_s: duration,
                            areaCovered: areaCovered
                        )
                    }
                }
            }
        }
        
        @objc private func handlePauseSession(_ notification: Notification) {
            guard let arView = arView else { return }
            arView.session.pause()
            print("⏸️ AR session paused")
        }

        @objc private func handleResumeSession(_ notification: Notification) {
            guard let arView = arView else { return }
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.sceneReconstruction = .mesh
            
            // Resume with current state (don't reset)
            arView.session.run(configuration, options: [])
            print("▶️ AR session resumed")
        }
        
        @objc private func handlePlaceAnchor(_ notification: Notification) {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else {
                print("❌ Cannot place anchor: no AR frame")
                return
            }
            
            // Get camera transform
            let cameraTransform = frame.camera.transform
            
            // Cast ray from center of screen
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let hitResults = arView.hitTest(screenCenter, types: [.existingPlaneUsingExtent, .featurePoint])
            
            guard let hit = hitResults.first else {
                print("❌ No surface found at tap location")
                return
            }
            
            // Create anchor at hit location
            let anchorTransform = hit.worldTransform
            let anchor = ARAnchor(transform: anchorTransform)
            arView.session.add(anchor: anchor)
            
            // Capture raw feature points within 0.5m radius
            let rawPoints = captureRawFeatures(around: anchorTransform, radius: 0.5, frame: frame)
            
            print("📍 Placed anchor at \(anchorTransform.columns.3)")
            print("   Captured \(rawPoints.count) raw feature points")
            
            // Notify SwiftUI to show name prompt
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("AnchorDataCaptured"),
                    object: nil,
                    userInfo: [
                        "anchor": anchor,
                        "rawPoints": rawPoints
                    ]
                )
            }
        }

        @objc private func handleAnchorPlaced(_ notification: Notification) {
            guard let arView = arView,
                  let userInfo = notification.userInfo,
                  let name = userInfo["name"] as? String,
                  let anchor = userInfo["anchor"] as? ARAnchor,
                  let isLinked = userInfo["isLinked"] as? Bool else {
                return
            }
            
            // Add visual disk at anchor location
            addVisualDisk(at: anchor, name: name, isLinked: isLinked, to: arView)
        }

        @objc private func handleRenderExistingAnchor(_ notification: Notification) {
            guard let arView = arView,
                  let userInfo = notification.userInfo,
                  let instance = userInfo["instance"] as? AnchorAreaInstance,
                  let name = userInfo["name"] as? String,
                  let isLinked = userInfo["isLinked"] as? Bool else {
                return
            }
            
            // Create anchor from stored position
            let transform = simd_float4x4(
                SIMD4<Float>(1, 0, 0, 0),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(instance.centerPosition.x, instance.centerPosition.y, instance.centerPosition.z, 1)
            )
            let anchor = ARAnchor(transform: transform)
            
            // Add visual disk
            addVisualDisk(at: anchor, name: name, isLinked: isLinked, to: arView)
        }

        private func captureRawFeatures(around transform: simd_float4x4,
                                        radius: Float,
                                        frame: ARFrame) -> [RawFeaturePoint] {
            
            let anchorPosition = SIMD3<Float>(transform.columns.3.x,
                                              transform.columns.3.y,
                                              transform.columns.3.z)
            
            guard let rawPoints = frame.rawFeaturePoints else {
                return []
            }
            
            var captured: [RawFeaturePoint] = []
            
            for i in 0..<rawPoints.points.count {
                let point = rawPoints.points[i]
                let distance = simd_distance(point, anchorPosition)
                
                if distance <= radius {
                    captured.append(RawFeaturePoint(
                        position: point,
                        timestamp: Date(),
                        observationCount: 1
                    ))
                }
            }
            
            print("   Filtered \(captured.count) of \(rawPoints.points.count) points within \(radius)m")
            
            return captured
        }

        private func addVisualDisk(at anchor: ARAnchor,
                                  name: String,
                                  isLinked: Bool,
                                  to arView: ARSCNView) {
            
            // Create disk geometry (flat cylinder, not sphere)
            let disk = SCNCylinder(radius: 0.15, height: 0.002)
            disk.firstMaterial?.diffuse.contents = isLinked ? UIColor.green.withAlphaComponent(0.7) : UIColor.yellow.withAlphaComponent(0.7)
            
            // Create parent node at anchor position
            let parentNode = SCNNode()
            let transform = anchor.transform
            parentNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create disk node (child of parent)
            let diskNode = SCNNode(geometry: disk)
            //diskNode.eulerAngles.x = .pi / 2  // Rotate to lay flat
            parentNode.addChildNode(diskNode)
            
            // Add text label
            let text = SCNText(string: name, extrusionDepth: 0.5)
            text.font = UIFont.boldSystemFont(ofSize: 8)
            text.flatness = 0.1
            text.firstMaterial?.diffuse.contents = UIColor.white
            
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.002, 0.002, 0.002)
            
            // Center text above disk
            let (min, max) = textNode.boundingBox
            let width = CGFloat(max.x - min.x)
            textNode.position = SCNVector3(-Float(width) * 0.001, 0.2, 0)  // 20cm above disk
            
            // Billboard constraint (text always faces camera)
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = [.Y]
            textNode.constraints = [billboardConstraint]
            
            parentNode.addChildNode(textNode)
            
            // Add directly to scene root (don't wait for ARKit anchor node)
            arView.scene.rootNode.addChildNode(parentNode)
            placedAnchorDisks[anchor.identifier] = parentNode
            
            print("✅ Added visual disk for '\(name)' (\(isLinked ? "🟢 linked" : "🟡 new"))")
        }
    }
}