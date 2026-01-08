//
//  RelocalizationDebugView.swift
//  TapResolver
//
//  Debug UI for testing relocalization strategies
//

import SwiftUI
import ARKit

struct RelocalizationDebugView: View {
    @ObservedObject var coordinator: RelocalizationCoordinator
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @State private var selectedTriangleID: UUID?
    @State private var showTrianglePicker = false
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and close button
            HStack {
                Text("Relocalization Debug")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
            }
            
            // Strategy picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Strategy:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Strategy", selection: Binding(
                    get: { coordinator.selectedStrategyID ?? "" },
                    set: { coordinator.selectedStrategyID = $0 }
                )) {
                    ForEach(coordinator.availableStrategies, id: \.id) { strategy in
                        Text(strategy.displayName).tag(strategy.id)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Triangle selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Triangle:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showTrianglePicker = true
                }) {
                    HStack {
                        Text(selectedTriangleDisplayName)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            // Last result display
            if let result = coordinator.lastResult {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Result:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                        
                        Text(result.success ? "Success" : "Failed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(result.confidence * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if let notes = result.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                    }
                }
            }
            
            // Relocalize button
            Button(action: {
                attemptRelocalization()
            }) {
                HStack {
                    if coordinator.isRelocalizing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.magnifyingglass")
                    }
                    Text(coordinator.isRelocalizing ? "Relocalizing..." : "Attempt Relocalization")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(canAttemptRelocalization ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!canAttemptRelocalization || coordinator.isRelocalizing)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showTrianglePicker) {
            TrianglePickerView(
                triangles: triangleStore.triangles.filter { $0.isCalibrated },
                selectedID: $selectedTriangleID
            )
        }
    }
    
    private var selectedTriangleDisplayName: String {
        guard let triangleID = selectedTriangleID,
              let triangle = triangleStore.triangle(withID: triangleID) else {
            return "Select triangle..."
        }
        return "Triangle \(String(triangle.id.uuidString.prefix(8)))"
    }
    
    private func attemptRelocalization() {
        guard let triangleID = selectedTriangleID,
              let triangle = triangleStore.triangle(withID: triangleID),
              let arCoordinator = ARViewContainer.Coordinator.current,
              let session = arCoordinator.sceneView?.session else {
            print("⚠️ Cannot relocalize: Missing triangle or AR session")
            return
        }
        
        coordinator.attemptRelocalization(for: triangle, session: session) { result in
            print("🎯 Relocalization result: \(result.success ? "Success" : "Failed") (confidence: \(result.confidence))")
        }
    }
    
    private var canAttemptRelocalization: Bool {
        coordinator.selectedStrategy != nil && selectedTriangleID != nil
    }
}

// Triangle picker sheet
struct TrianglePickerView: View {
    let triangles: [TrianglePatch]
    @Binding var selectedID: UUID?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(triangles) { triangle in
                    Button(action: {
                        selectedID = triangle.id
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Triangle \(String(triangle.id.uuidString.prefix(8)))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Quality: \(Int(triangle.calibrationQuality * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if triangle.worldMapFilename != nil {
                                    Label("ARWorldMap saved", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedID == triangle.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Triangle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

