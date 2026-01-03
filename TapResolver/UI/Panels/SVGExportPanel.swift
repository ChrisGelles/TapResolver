//
//  SVGExportPanel.swift
//  TapResolver
//
//  Panel for configuring and triggering SVG exports.
//

import SwiftUI

struct SVGExportPanel: View {
    @EnvironmentObject private var exportOptions: SVGExportOptions
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    @Binding var isPresented: Bool
    
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Layer Options
                Section(header: Text("Layers to Include")) {
                    Toggle("Map Background", isOn: $exportOptions.includeMapBackground)
                    
                    Toggle("Calibration Mesh", isOn: $exportOptions.includeCalibrationMesh)
                        .disabled(true)  // Phase 2 - not yet implemented
                    
                    Toggle("RSSI Heatmap", isOn: $exportOptions.includeRSSIHeatmap)
                        .disabled(true)  // Phase 3 - not yet implemented
                }
                
                // MARK: - Preview Info
                Section(header: Text("Export Info")) {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(locationManager.currentLocationID)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Map Points")
                        Spacer()
                        Text("\(mapPointStore.points.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Filename")
                        Spacer()
                        Text(exportOptions.generateFilename(locationID: locationManager.currentLocationID))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // MARK: - Export Button
                Section {
                    Button(action: performExport) {
                        HStack {
                            Spacer()
                            if exportOptions.isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Exporting...")
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export SVG")
                            }
                            Spacer()
                        }
                    }
                    .disabled(exportOptions.isExporting)
                }
            }
            .navigationTitle("SVG Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Export Action
    
    private func performExport() {
        exportOptions.isExporting = true
        
        // Capture locationID on main thread before background work
        let locationID = locationManager.currentLocationID
        
        // Run export on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let filename = exportOptions.generateFilename(locationID: locationID)
            
            // Get map size from the map image
            guard let mapImage = LocationImportUtils.loadDisplayImage(locationID: locationID) else {
                print("❌ [SVGExport] Failed to load map image")
                DispatchQueue.main.async {
                    exportOptions.isExporting = false
                }
                return
            }
            
            let doc = SVGDocument(width: mapImage.size.width, height: mapImage.size.height)
            
            // Add background if selected
            if exportOptions.includeMapBackground {
                doc.setBackgroundImage(mapImage)
            }
            
            // Phase 2: Add calibration mesh layers here
            // if exportOptions.includeCalibrationMesh { ... }
            
            // Phase 3: Add RSSI heatmap layers here
            // if exportOptions.includeRSSIHeatmap { ... }
            
            // Write to file
            if let url = doc.writeToTempFile(filename: filename) {
                DispatchQueue.main.async {
                    exportedFileURL = url
                    exportOptions.lastExportURL = url
                    exportOptions.isExporting = false
                    showShareSheet = true
                    print("✅ [SVGExport] Export complete: \(filename)")
                }
            } else {
                DispatchQueue.main.async {
                    exportOptions.isExporting = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SVGExportPanel(isPresented: .constant(true))
        .environmentObject(SVGExportOptions())
        .environmentObject(LocationManager())
        .environmentObject(MapPointStore())
}

