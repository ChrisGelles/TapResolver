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
                    
                    if exportOptions.includeCalibrationMesh {
                        HStack {
                            Text("With Baked Position")
                            Spacer()
                            Text("\(mapPointStore.points.filter { $0.canonicalPosition != nil }.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Filename")
                        Spacer()
                        Text(exportOptions.previewFilename(locationID: locationManager.currentLocationID))
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
        
        // Capture data on main thread before background work
        let locationID = locationManager.currentLocationID
        let points = mapPointStore.points  // Capture points array
        
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
            doc.setDocumentID("\(locationID)-map")
            
            // Add background if selected
            if exportOptions.includeMapBackground {
                doc.setBackgroundImage(mapImage)
            }
            
            // Phase 2: Add calibration mesh layers
            if exportOptions.includeCalibrationMesh {
                self.addCalibrationMeshLayers(to: doc, mapSize: mapImage.size, points: points)
            }
            
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
    
    // MARK: - Calibration Mesh Export
    
    /// Add calibration mesh layers to the SVG document
    private func addCalibrationMeshLayers(to doc: SVGDocument, mapSize: CGSize, points: [MapPointStore.MapPoint]) {
        
        // Register styles for circle fills
        doc.registerStyle(className: "mappoint-original", css: "fill: #0064ff; fill-opacity: 0.7;")
        doc.registerStyle(className: "mappoint-adjusted", css: "fill: #00c864; fill-opacity: 0.7;")
        
        // Get map parameters for coordinate conversion
        // TODO: Get from location metadata. Using home map default for now.
        let metersPerPixel: CGFloat = 0.0056
        let pixelsPerMeter = 1.0 / metersPerPixel
        let originX = mapSize.width / 2
        let originY = mapSize.height / 2
        
        // Layer 1: Original MapPoint positions (blue)
        var originalCircles: [(cx: CGFloat, cy: CGFloat, r: CGFloat, elementID: String?)] = []
        
        for point in points {
            let shortID = String(point.id.uuidString.prefix(8))
            originalCircles.append((
                cx: point.mapPoint.x,
                cy: point.mapPoint.y,
                r: 6,
                elementID: shortID
            ))
        }
        
        doc.addCircleLayer(id: "mappoints-original", circles: originalCircles, styleClass: "mappoint-original")
        print("📐 [SVGExport] Added \(originalCircles.count) original MapPoint positions")
        
        // Layer 2: Adjusted/baked positions (green)
        var adjustedCircles: [(cx: CGFloat, cy: CGFloat, r: CGFloat, elementID: String?)] = []
        
        for point in points {
            // Only include points with baked canonical positions
            guard let canonical = point.canonicalPosition else { continue }
            
            // Convert canonical (meters) to pixel coordinates
            // Canonical: X = right, Z = forward (toward top of map)
            // Pixel: X = right, Y = down
            let pixelX = CGFloat(canonical.x) * pixelsPerMeter + originX
            let pixelY = CGFloat(canonical.z) * pixelsPerMeter + originY
            
            let shortID = String(point.id.uuidString.prefix(8))
            adjustedCircles.append((
                cx: pixelX,
                cy: pixelY,
                r: 6,
                elementID: shortID
            ))
        }
        
        doc.addCircleLayer(id: "mappoints-adjusted", circles: adjustedCircles, styleClass: "mappoint-adjusted")
        print("📐 [SVGExport] Added \(adjustedCircles.count) adjusted MapPoint positions")
    }
}

// MARK: - Preview

#Preview {
    SVGExportPanel(isPresented: .constant(true))
        .environmentObject(SVGExportOptions())
        .environmentObject(LocationManager())
        .environmentObject(MapPointStore())
}

