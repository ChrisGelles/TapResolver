//
//  ARSurveyView.swift
//  TapResolver
//
//  UI for surveying a space and capturing GlobalMap
//

import SwiftUI
import ARKit

struct ARSurveyView: View {
    @EnvironmentObject var arWorldMapStore: ARWorldMapStore
    @StateObject private var coordinator: ARSurveyCoordinator
    @Environment(\.dismiss) var dismiss
    
    @State private var isSaving = false
    @State private var showSuccess = false
    
    init(arWorldMapStore: ARWorldMapStore) {
        _coordinator = StateObject(wrappedValue: ARSurveyCoordinator(arWorldMapStore: arWorldMapStore))
    }
    
    var body: some View {
        ZStack {
            // AR camera view
            ARViewContainer(coordinator: coordinator)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top: Quality indicators
                qualityCard
                    .padding()
                
                Spacer()
                
                // Bottom: Controls
                controlsCard
                    .padding()
            }
        }
        .onAppear {
            coordinator.startSurvey()
        }
        .onDisappear {
            coordinator.stopSurvey()
        }
        .alert("Map Saved", isPresented: $showSuccess) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("GlobalMap saved successfully")
        }
    }
    
    private var qualityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Survey Quality")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Label("\(coordinator.featurePointCount)", systemImage: "scope")
                        .font(.caption)
                    Text("Features")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Label("\(coordinator.planeCount)", systemImage: "square.grid.3x3")
                        .font(.caption)
                    Text("Planes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    trackingStateLabel
                        .font(.caption)
                    Text("Tracking")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if coordinator.isReadyToSave {
                Label("Ready to save", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Label("Keep walking to improve coverage", systemImage: "figure.walk")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var trackingStateLabel: some View {
        Group {
            switch coordinator.trackingState {
            case .normal:
                Label("Normal", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .limited:
                Label("Limited", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            case .notAvailable:
                Label("Not Available", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            @unknown default:
                Label("Unknown", systemImage: "questionmark.circle")
            }
        }
    }
    
    private var controlsCard: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Button {
                isSaving = true
                coordinator.captureMap { result in
                    isSaving = false
                    switch result {
                    case .success:
                        showSuccess = true
                    case .failure(let error):
                        print("❌ Save failed: \(error)")
                    }
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Save Map")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!coordinator.isReadyToSave || isSaving)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - ARView Container

private struct ARViewContainer: UIViewRepresentable {
    let coordinator: ARSurveyCoordinator
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session = coordinator.session
        arView.automaticallyUpdatesLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

extension ARSurveyCoordinator {
    var session: ARSession {
        ARSession.shared // Use shared session
    }
}

// Fix: ARSession doesn't have shared by default
extension ARSession {
    static let shared = ARSession()
}