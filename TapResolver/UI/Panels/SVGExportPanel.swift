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
    @EnvironmentObject private var surveyPointStore: SurveyPointStore
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var metricSquareStore: MetricSquareStore
    @EnvironmentObject private var surveyExportOptions: SurveyExportOptions
    @EnvironmentObject private var beaconListsStore: BeaconListsStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @EnvironmentObject private var zoneStore: ZoneStore
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore

    
    @Binding var isPresented: Bool
    
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showJSONShareSheet = false
    @State private var jsonExportURL: URL?
    @State private var showInitialsPrompt = false
    @State private var tempInitials: String = ""
    @State private var showJSONDocumentPicker = false
    
    // MARK: - Import State
    @State private var showingImportFilePicker = false
    @State private var importTrianglesEnabled = true
    @State private var importZonesEnabled = true
    @State private var importResultMessage: String? = nil
    @State private var showingImportResultAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Survey Data Export (JSON)
                Section(header: Text("Survey Data Export")) {
                    HStack {
                        Text("Survey Points")
                        Spacer()
                        Text("\(surveyPointStore.surveyPoints.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(surveyPointStore.totalSessionCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        tempInitials = surveyExportOptions.helperInitials
                        showInitialsPrompt = true
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.white)
                            Text("Export Survey Data (.mapsurvey)")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(surveyPointStore.surveyPoints.isEmpty ? Color.gray : Color.red)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(surveyPointStore.surveyPoints.isEmpty || surveyExportOptions.isExporting)
                }
                
                // MARK: - SVG Export Options
                Section(header: Text("SVG Export (Visualization)")) {
                    Toggle("Map Background", isOn: $exportOptions.includeMapBackground)
                    Toggle("Calibration Mesh", isOn: $exportOptions.includeCalibrationMesh)
                    Toggle("RSSI Heatmap", isOn: $exportOptions.includeRSSIHeatmap)
                    Toggle("Triangles", isOn: $exportOptions.includeTriangles)
                    Toggle("Zones", isOn: $exportOptions.includeZones)
                }
                
                Section(header: Text("Format Options")) {
                    Toggle("Optimize for Illustrator", isOn: $exportOptions.formatForIllustrator)
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
                    
                    if exportOptions.includeRSSIHeatmap {
                        HStack {
                            Text("Survey Points")
                            Spacer()
                            Text("\(surveyPointStore.surveyPoints.count)")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Beacons")
                            Spacer()
                            Text("\(beaconDotStore.dots.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if exportOptions.includeTriangles {
                        HStack {
                            Text("Triangles")
                            Spacer()
                            Text("\(triangleStore.triangles.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if exportOptions.includeZones {
                        HStack {
                            Text("Zones")
                            Spacer()
                            Text("\(zoneStore.zones.count)")
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
                    .buttonStyle(.plain)
                    .disabled(exportOptions.isExporting)
                }
                
                // MARK: - Import Section
                Section("Import from SVG") {
                    Toggle("Triangles", isOn: $importTrianglesEnabled)
                    Toggle("Zones", isOn: $importZonesEnabled)
                    
                    Button {
                        print("🔘 [SVGExportPanel] Import button tapped")
                        print("   Triangles: \(importTrianglesEnabled), Zones: \(importZonesEnabled)")
                        showingImportFilePicker = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.down")
                            Text("Import from SVG")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(getPixelsPerMeter() == nil || (!importTrianglesEnabled && !importZonesEnabled))
                    
                    if getPixelsPerMeter() == nil {
                        Text("MetricSquare calibration required for import")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        mapTransform.isHUDInteracting = true
                    }
                    .onEnded { _ in
                        mapTransform.isHUDInteracting = false
                    }
            )
            .navigationTitle("Export Options")
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
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.svg],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                handleUnifiedImport(from: url)
                
            case .failure(let error):
                print("❌ [SVGImport] File picker error: \(error.localizedDescription)")
                importResultMessage = "File picker error: \(error.localizedDescription)"
                showingImportResultAlert = true
            }
        }
        .alert("Import Complete", isPresented: $showingImportResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importResultMessage ?? "Import finished.")
        }
        .alert("Enter Your Initials", isPresented: $showInitialsPrompt) {
            TextField("Initials (e.g., CG)", text: $tempInitials)
                .autocapitalization(.allCharacters)
            Button("Export") {
                surveyExportOptions.helperInitials = tempInitials
                performJSONExport()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your initials will be included in the filename for tracking.")
        }
        .sheet(isPresented: $showJSONDocumentPicker) {
            if let url = jsonExportURL {
                DocumentExportPicker(fileURL: url) { success in
                    showJSONDocumentPicker = false
                    if success {
                        print("✅ [MapSurvey] Export saved successfully")
                    }
                }
            }
        }
    }
    
    // MARK: - Export Action
    
    private func performExport() {
        exportOptions.isExporting = true
        
        // Capture data on main thread before background work
        let locationID = locationManager.currentLocationID
        let points = mapPointStore.points  // Capture points array
        let surveyPoints = Array(surveyPointStore.surveyPoints.values)
        let beaconDots = beaconDotStore.dots
        let pixelsPerMeter = getPixelsPerMeter()
        let triangles = triangleStore.triangles
        let zones = zoneStore.zones
        
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
            
            // Add triangles layer (below mesh)
            if exportOptions.includeTriangles {
                self.addTrianglesLayer(to: doc, triangles: triangles, points: points)
            }
            
            // Add zones layer (below mesh)
            if exportOptions.includeZones {
                self.addZonesLayer(to: doc, zones: zones, points: points)
            }
            
            // Add export manifest layer (for round-trip editing)
            if exportOptions.includeTriangles || exportOptions.includeZones {
                let manifest = SVGManifest.build(
                    locationID: locationID,
                    mapWidth: Int(mapImage.size.width),
                    mapHeight: Int(mapImage.size.height),
                    pixelsPerMeter: pixelsPerMeter.map { Float($0) },
                    mapPoints: points,
                    triangles: exportOptions.includeTriangles ? triangles : [],
                    zones: exportOptions.includeZones ? zones : []
                )
                
                if let manifestJSON = manifest.encodeToJSON() {
                    doc.addManifestLayer(manifestJSON)
                } else {
                    print("⚠️ [SVGExport] Failed to encode manifest")
                }
            }
            
            // Phase 2: Add calibration mesh layers (mappoints on top)
            if exportOptions.includeCalibrationMesh {
                self.addCalibrationMeshLayers(to: doc, mapSize: mapImage.size, points: points, pixelsPerMeter: pixelsPerMeter)
            }
            
            // Phase 3: Add RSSI heatmap layers
            if exportOptions.includeRSSIHeatmap {
                self.addRSSIHeatmapLayers(to: doc, mapSize: mapImage.size, surveyPoints: surveyPoints, beaconDots: beaconDots, pixelsPerMeter: pixelsPerMeter)
            }
            
            // Generate SVG content
            var svgContent = doc.generateSVG()
            
            // Apply Illustrator formatting if enabled
            if exportOptions.formatForIllustrator {
                svgContent = SVGIllustratorFormatter.format(svgContent)
                print("🎨 [SVGExport] Applied Illustrator formatting")
            }
            
            // Write to temp file
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)
            
            do {
                try svgContent.write(to: fileURL, atomically: true, encoding: .utf8)
                print("📄 [SVGExport] Wrote SVG to: \(fileURL.lastPathComponent)")
                
                DispatchQueue.main.async {
                    self.exportedFileURL = fileURL
                    self.exportOptions.lastExportURL = fileURL
                    self.exportOptions.isExporting = false
                    self.showShareSheet = true
                    print("✅ [SVGExport] Export complete: \(filename)")
                }
            } catch {
                print("❌ [SVGExport] Failed to write SVG: \(error)")
                DispatchQueue.main.async {
                    self.exportOptions.isExporting = false
                }
            }
        }
    }
    
    // MARK: - JSON Survey Export

    private func performJSONExport() {
        surveyExportOptions.isExporting = true
        
        let locationID = locationManager.currentLocationID
        let surveyPoints = Array(surveyPointStore.surveyPoints.values)
        let beaconDots = beaconDotStore.dots
        let pixelsPerMeter = getPixelsPerMeter()
        let initials = surveyExportOptions.helperInitials
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Build location info
            let mapImage = LocationImportUtils.loadDisplayImage(locationID: locationID)
            let locationName: String
            let locationDir = PersistenceContext.shared.docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
            let stubURL = locationDir.appendingPathComponent("location.json")
            if let data = try? Data(contentsOf: stubURL),
               let stub = try? JSONDecoder().decode(LocationStub.self, from: data) {
                locationName = stub.name
            } else {
                locationName = locationID
            }
            
            let locationInfo = LocationInfo(
                id: locationID,
                name: locationName,
                pixelsPerMeter: pixelsPerMeter.map { Double($0) },
                mapDimensions_px: mapImage.map { [Int($0.size.width), Int($0.size.height)] }
            )
            
            // Build beacon reference (only beacons with map positions)
            let beaconReference: [BeaconReferenceInfo] = beaconDots.map { dot in
                BeaconReferenceInfo(
                    beaconID: dot.beaconID,
                    mapX_px: Double(dot.mapPoint.x),
                    mapY_px: Double(dot.mapPoint.y),
                    elevation_m: self.beaconDotStore.getElevation(for: dot.beaconID),
                    txPower_dBm: self.beaconDotStore.getTxPower(for: dot.beaconID)
                )
            }
            
            // Build export structure
            let export = MapSurveyExport(
                collector: CollectorInfo(initials: initials),
                location: locationInfo,
                beaconReference: beaconReference,
                surveyPoints: surveyPoints
            )
            
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            guard let jsonData = try? encoder.encode(export) else {
                print("❌ [MapSurvey] Failed to encode export")
                DispatchQueue.main.async {
                    surveyExportOptions.isExporting = false
                }
                return
            }
            
            // Write to temp file
            let filename = surveyExportOptions.generateFilename(initials: initials)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try jsonData.write(to: tempURL)
                print("✅ [MapSurvey] Export ready: \(filename) (\(jsonData.count) bytes)")
                
                DispatchQueue.main.async {
                    jsonExportURL = tempURL
                    surveyExportOptions.lastExportURL = tempURL
                    surveyExportOptions.isExporting = false
                    showJSONDocumentPicker = true
                }
            } catch {
                print("❌ [MapSurvey] Failed to write file: \(error)")
                DispatchQueue.main.async {
                    surveyExportOptions.isExporting = false
                }
            }
        }
    }
    
    // MARK: - Calibration Mesh Export
    
    /// Add calibration mesh layers to the SVG document
    private func addCalibrationMeshLayers(to doc: SVGDocument, mapSize: CGSize, points: [MapPointStore.MapPoint], pixelsPerMeter: CGFloat?) {
        
        // Register styles for circle fills
        doc.registerStyle(className: "mappoint-original", css: "fill: #0064ff; fill-opacity: 0.7;")
        doc.registerStyle(className: "mappoint-adjusted", css: "fill: #00c864; fill-opacity: 0.7;")
        
        // Get map parameters for coordinate conversion
        guard let pixelsPerMeter = pixelsPerMeter else {
            print("⚠️ [SVGExport] No MetricSquare available for scale conversion")
            return
        }
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
    
    // MARK: - RSSI Heatmap Export
    
    /// Add RSSI heatmap layers to the SVG document (one layer per beacon)
    private func addRSSIHeatmapLayers(to doc: SVGDocument, mapSize: CGSize, surveyPoints: [SurveyPoint], beaconDots: [BeaconDotStore.BeaconDotV2], pixelsPerMeter: CGFloat?) {
        
        // Calculate circle radius: 0.4m in pixels
        guard let pixelsPerMeter = pixelsPerMeter else {
            print("⚠️ [SVGExport] No MetricSquare available for scale conversion")
            return
        }
        let radiusPixels = 0.4 * pixelsPerMeter
        
        // Register text label style
        doc.registerStyle(className: "beaconLabels", css: "font-family: Arial, sans-serif; font-size: 12px; fill: #000000;")
        
        // Opacity values for each dBm bucket
        let dBmOpacities: [Int: String] = [
            -100: "0.05",
            -90: "0.20",
            -80: "0.35",
            -70: "0.50",
            -60: "0.65",
            -50: "0.80",
            -40: "0.95",
            -30: "1.0"
        ]
        
        // Collect all unique beacon IDs from survey data
        var beaconIDs = Set<String>()
        for surveyPoint in surveyPoints {
            for session in surveyPoint.sessions {
                for beacon in session.beacons {
                    beaconIDs.insert(beacon.beaconID)
                }
            }
        }
        
        print("📡 [SVGExport] Processing \(beaconIDs.count) beacons across \(surveyPoints.count) survey points")
        
        // Process each beacon
        for beaconID in beaconIDs.sorted() {
            // Generate beacon color from ID hash (same algorithm as BeaconDotStore)
            let hash = beaconID.hash
            let hue = Double(abs(hash % 360)) / 360.0
            let hexColor = hsbToHex(hue: hue, saturation: 0.7, brightness: 0.8)
            
            // Create sanitized class name from beacon ID (no leading numbers for CSS)
            let beaconClassName = sanitizeClassName(beaconID)
            // Element ID keeps numbers (for group IDs and dot IDs)
            let beaconElementID = sanitizeElementID(beaconID)
            
            // Register compound styles for each dBm bucket (beacon color + opacity)
            for (dBm, opacity) in dBmOpacities {
                let compoundClass = "\(beaconClassName)-dBm\(abs(dBm))"
                doc.registerStyle(className: compoundClass, css: "fill: \(hexColor); fill-opacity: \(opacity);")
            }
            
            // Register beacon dot style (color + stroke)
            let beaconDotClass = "\(beaconClassName)-beacon"
            doc.registerStyle(className: beaconDotClass, css: "fill: \(hexColor); stroke: #000000; stroke-width: 3;")
            
            // Build layer content directly
            var layerContent = ""
            
            for surveyPoint in surveyPoints {
                // Calculate weighted average median RSSI for this beacon at this point
                var totalWeightedRSSI: Double = 0
                var totalSamples: Int = 0
                
                for session in surveyPoint.sessions {
                    for beacon in session.beacons where beacon.beaconID == beaconID {
                        let sampleCount = beacon.samples.count
                        if sampleCount > 0 {
                            totalWeightedRSSI += Double(beacon.stats.median_dbm) * Double(sampleCount)
                            totalSamples += sampleCount
                        }
                    }
                }
                
                guard totalSamples > 0 else { continue }
                
                let averageRSSI = totalWeightedRSSI / Double(totalSamples)
                let dBmBucket = rssiToBucket(averageRSSI)
                let compoundClass = "\(beaconClassName)-dBm\(abs(dBmBucket))"
                
                let coordID = String(format: "%.0f-%.0f", surveyPoint.mapX, surveyPoint.mapY)
                
                layerContent += "<circle id=\"\(coordID)\" class=\"\(compoundClass)\" cx=\"\(String(format: "%.1f", surveyPoint.mapX))\" cy=\"\(String(format: "%.1f", surveyPoint.mapY))\" r=\"\(String(format: "%.1f", radiusPixels))\"/>\n"
            }
            
            // Add beacon position dot and label if we have it
            if let dot = beaconDots.first(where: { $0.beaconID == beaconID }) {
                let dotID = beaconElementID
                layerContent += "<circle id=\"\(dotID)\" class=\"\(beaconDotClass)\" cx=\"\(String(format: "%.1f", dot.mapPoint.x))\" cy=\"\(String(format: "%.1f", dot.mapPoint.y))\" r=\"10.0\"/>\n"
                
                // Calculate min/max RSSI for this beacon
                var allRSSIValues: [Double] = []
                for surveyPoint in surveyPoints {
                    for session in surveyPoint.sessions {
                        for beacon in session.beacons where beacon.beaconID == beaconID {
                            if !beacon.samples.isEmpty {
                                allRSSIValues.append(Double(beacon.stats.median_dbm))
                            }
                        }
                    }
                }
                
                // Add min/max label near beacon dot
                if let minRSSI = allRSSIValues.min(), let maxRSSI = allRSSIValues.max() {
                    let labelID = "\(beaconElementID)-minmax"
                    let labelX = dot.mapPoint.x + 15  // Offset right of beacon dot
                    let labelY = dot.mapPoint.y + 4   // Vertically centered with dot
                    let labelText = "\(beaconElementID) min \(Int(minRSSI)) max \(Int(maxRSSI))"
                    layerContent += "<text id=\"\(labelID)\" class=\"beaconLabels\" x=\"\(String(format: "%.1f", labelX))\" y=\"\(String(format: "%.1f", labelY))\">\(labelText)</text>\n"
                }
            }
            
            // Add layer for this beacon
            let layerID = "\(beaconElementID)-rssi"
            doc.addLayer(id: layerID, content: layerContent)
            
            let circleCount = layerContent.components(separatedBy: "<circle").count - 1
            print("📡 [SVGExport] Added layer '\(layerID)' with \(circleCount) circles")
        }
    }
    
    /// Convert RSSI to 10-dBm bucket
    private func rssiToBucket(_ rssi: Double) -> Int {
        let rounded = Int(round(rssi / 10.0)) * 10
        return max(-100, min(-30, rounded))
    }
    
    /// Convert HSB to hex color string
    private func hsbToHex(hue: Double, saturation: Double, brightness: Double) -> String {
        let h = hue * 6
        let c = brightness * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        
        var r: Double, g: Double, b: Double
        switch Int(h) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        
        let ri = Int((r + m) * 255)
        let gi = Int((g + m) * 255)
        let bi = Int((b + m) * 255)
        
        return String(format: "#%02x%02x%02x", ri, gi, bi)
    }
    
    /// Sanitize beacon ID for use as CSS class name (must not start with number)
    private func sanitizeClassName(_ beaconID: String) -> String {
        // Remove invalid characters, keep alphanumeric and hyphens
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        var result = beaconID.unicodeScalars
            .filter { allowed.contains($0) }
            .map { Character($0) }
            .map { String($0) }
            .joined()
        
        // CSS class names cannot start with a digit - strip leading digits and hyphens
        while let first = result.first, first.isNumber || first == "-" {
            result.removeFirst()
        }
        
        return result
    }
    
    /// Sanitize beacon ID for use as element ID (can start with number)
    private func sanitizeElementID(_ beaconID: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        return beaconID.unicodeScalars
            .filter { allowed.contains($0) }
            .map { Character($0) }
            .map { String($0) }
            .joined()
    }
    
    // MARK: - Triangle Layer
    
    private func addTrianglesLayer(to doc: SVGDocument, triangles: [TrianglePatch], points: [MapPointStore.MapPoint]) {
        guard !triangles.isEmpty else { return }
        
        // Color palette for triangles (hex colors)
        let fillColors = [
            "ff6464",  // Red
            "64ff64",  // Green
            "6464ff",  // Blue
            "ffff64",  // Yellow
            "ff64ff",  // Magenta
            "64ffff",  // Cyan
        ]
        
        // Register CSS classes for each triangle
        for (index, triangle) in triangles.enumerated() {
            let triID = String(triangle.id.uuidString.prefix(8))
            let fillHex = fillColors[index % fillColors.count]
            let css = "fill: #\(fillHex); fill-opacity: 0.30; stroke: #000000; stroke-opacity: 0.60; stroke-width: 2;"
            doc.registerStyle(className: "triangle-\(triID)", css: css)
        }
        
        var content = ""
        
        for triangle in triangles {
            // Get vertex positions
            var vertexPositions: [CGPoint] = []
            for vertexID in triangle.vertexIDs {
                if let point = points.first(where: { $0.id == vertexID }) {
                    vertexPositions.append(point.mapPoint)
                }
            }
            
            guard vertexPositions.count == 3 else { continue }
            
            let triID = String(triangle.id.uuidString.prefix(8))
            
            // Draw triangle polygon with CSS class
            let pointsStr = vertexPositions.map { "\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.y))" }.joined(separator: " ")
            content += "    <polygon id=\"tri-\(triID)\" class=\"triangle-\(triID)\" points=\"\(pointsStr)\"/>\n"
        }
        
        doc.addLayer(id: "triangles", content: content)
        print("📐 [SVGExport] Added triangles layer with \(triangles.count) triangle(s)")
    }
    
    // MARK: - Zones Layer
    
    private func addZonesLayer(to doc: SVGDocument, zones: [Zone], points: [MapPointStore.MapPoint]) {
        guard !zones.isEmpty else { return }
        
        // Collect all zone groups that have zones
        let groupIDs = Set(zones.compactMap { $0.groupID })
        let groupsWithZones = zoneGroupStore.groups.filter { groupIDs.contains($0.id) }
        
        // Also collect zones without a group
        let ungroupedZones = zones.filter { $0.groupID == nil }
        
        // Register CSS classes for each zone group (fill color + 20% opacity)
        for group in groupsWithZones {
            let className = sanitizeZoneGroupClassName(group.id)
            let css = "fill: \(group.colorHex); opacity: 0.2;"
            doc.registerStyle(className: className, css: css)
        }
        
        // Register a default class for ungrouped zones
        if !ungroupedZones.isEmpty {
            doc.registerStyle(className: "zone-ungrouped", css: "fill: #888888; opacity: 0.2;")
        }
        
        var content = ""
        
        // Export zones grouped by their ZoneGroup
        for group in groupsWithZones {
            let groupZones = zones.filter { $0.groupID == group.id }
            guard !groupZones.isEmpty else { continue }
            
            let className = sanitizeZoneGroupClassName(group.id)
            
            // Open group container
            content += "    <g id=\"\(group.id)\">\n"
            
            for zone in groupZones {
                if let polygonSVG = renderZonePolygon(zone: zone, points: points, className: className) {
                    content += "      \(polygonSVG)\n"
                }
            }
            
            // Close group container
            content += "    </g>\n"
        }
        
        // Export ungrouped zones (if any) directly under zones layer
        for zone in ungroupedZones {
            if let polygonSVG = renderZonePolygon(zone: zone, points: points, className: "zone-ungrouped") {
                content += "    \(polygonSVG)\n"
            }
        }
        
        doc.addLayer(id: "zones", content: content)
        print("🔷 [SVGExport] Added zones layer with \(zones.count) zone(s) in \(groupsWithZones.count) group(s)")
    }
    
    /// Render a single zone polygon as an SVG string
    private func renderZonePolygon(zone: Zone, points: [MapPointStore.MapPoint], className: String) -> String? {
        // Get corner positions
        var cornerPositions: [CGPoint] = []
        for cornerID in zone.cornerMapPointIDs {
            if let point = points.first(where: { $0.id.uuidString == cornerID }) {
                cornerPositions.append(point.mapPoint)
            }
        }
        
        guard cornerPositions.count == 4 else { return nil }
        
        // Use zone's display name as the polygon ID (fall back to zone.id if no displayName)
        let polygonID = zone.displayName.isEmpty ? zone.id : zone.displayName
        
        // Format points string
        let pointsStr = cornerPositions.map { "\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.y))" }.joined(separator: " ")
        
        return "<polygon id=\"\(escapeXMLAttribute(polygonID))\" class=\"\(className)\" points=\"\(pointsStr)\"/>"
    }
    
    /// Sanitize a zone group ID for use as a CSS class name
    private func sanitizeZoneGroupClassName(_ input: String) -> String {
        // Remove "-zones" suffix if present, lowercase, replace spaces with hyphens
        var result = input
        if result.hasSuffix("-zones") {
            result = String(result.dropLast(6))
        }
        return result
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }
    
    /// Escape special characters for XML attribute values
    private func escapeXMLAttribute(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    
    /// Get pixels per meter from MetricSquareStore (prefers locked squares)
    private func getPixelsPerMeter() -> CGFloat? {
        let lockedSquares = metricSquareStore.squares.filter { $0.isLocked }
        let squaresToUse = lockedSquares.isEmpty ? metricSquareStore.squares : lockedSquares
        
        guard let square = squaresToUse.first, square.meters > 0 else { return nil }
        
        let pixelsPerMeter = CGFloat(square.side) / CGFloat(square.meters)
        return pixelsPerMeter > 0 ? pixelsPerMeter : nil
    }
    
    /// Pixels per meter computed property for import
    private var pixelsPerMeter: Float? {
        guard let square = metricSquareStore.squares.first else { return nil }
        return Float(square.side) / Float(square.meters)
    }
    
    // MARK: - Import Handler
    
    // MARK: - Unified Import Handler
    
    private func handleUnifiedImport(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ [SVGImport] Failed to access security-scoped resource")
            importResultMessage = "Could not access file"
            showingImportResultAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let data = try? Data(contentsOf: url) else {
            importResultMessage = "Could not read file"
            showingImportResultAlert = true
            return
        }
        
        guard let ppm = getPixelsPerMeter() else {
            importResultMessage = "MetricSquare calibration required"
            showingImportResultAlert = true
            return
        }
        
        var resultLines: [String] = []
        
        // Triangle Import
        if importTrianglesEnabled {
            let importer = SVGImporter(
                mapPointStore: mapPointStore,
                zoneStore: zoneStore,
                zoneGroupStore: zoneGroupStore,
                pixelsPerMeter: ppm
            )
            let triResult = importer.importTriangles(
                from: data,
                triangleStore: triangleStore,
                mapPointStore: mapPointStore,
                zoneStore: zoneStore,
                pixelsPerMeter: Float(ppm)
            )
            
            if !triResult.errors.isEmpty {
                resultLines.append("⚠️ Triangle Errors:")
                resultLines.append(contentsOf: triResult.errors.prefix(3))
            } else {
                resultLines.append("✅ Triangles: \(triResult.trianglesCreated) created, \(triResult.trianglesSkipped) skipped")
                resultLines.append("   MapPoints: \(triResult.mapPointsCreated) new, \(triResult.mapPointsReused) reused")
            }
        }
        
        // Zone Import
        if importZonesEnabled {
            let importer = SVGImporter(
                mapPointStore: mapPointStore,
                zoneStore: zoneStore,
                zoneGroupStore: zoneGroupStore,
                pixelsPerMeter: ppm
            )
            let zoneResult = importer.importZones(from: url)
            
            if !zoneResult.success {
                resultLines.append("⚠️ Zone Errors:")
                resultLines.append(contentsOf: zoneResult.errors.prefix(3))
            } else {
                resultLines.append("✅ Zones: \(zoneResult.zonesCreated) created, \(zoneResult.groupsCreated) groups")
                resultLines.append("   MapPoints: \(zoneResult.mapPointsCreated) new, \(zoneResult.mapPointsReused) reused")
            }
        }
        
        importResultMessage = resultLines.joined(separator: "\n")
        showingImportResultAlert = true
    }
}

// MARK: - Preview

#Preview {
    SVGExportPanel(isPresented: .constant(true))
        .environmentObject(SVGExportOptions())
        .environmentObject(LocationManager())
        .environmentObject(MapPointStore())
}

