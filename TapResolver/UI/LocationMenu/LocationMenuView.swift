import SwiftUI
import PhotosUI

struct LocationMenuView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var locationSummaries: [LocationSummary] = []
    @State private var showingImportSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingDocumentPicker = false

    // Backup/Restore state
    @State private var backupMode: BackupMode = .none
    @State private var selectedLocationIDs: Set<String> = []
    @State private var includeAssets: Bool = true
    @State private var showBackupPicker: Bool = false
    @State private var showRestorePicker: Bool = false
    @State private var showRestoreConfirmation: Bool = false
    @State private var backupURL: URL?

    enum BackupMode {
        case none, selectForBackup, selectForRestore
    }

    // Hard-coded IDs & asset names
    private let homeID = "home"
    private let homeTitle = "Chris's House"
    private let defaultMapAsset = "myFirstFloor_v03-metric"
    private let defaultThumbAsset = "myFirstFloor_v03-metric-thumb"

    private let museumID = "museum"
    private let museumTitle = "Museum Map"
    private let museumMapAsset = "MuseumMap-8k"
    private let museumThumbAsset = "MuseumMap-thumbnail"

    // Two equal-width columns with compact spacing
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main content ScrollView
                    ScrollView {
                        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {

                            // --- Hard-coded chiclet: Home/Chris's House ---
                            SelectableAssetLocationTile(
                                title: homeTitle,
                                imageName: defaultThumbAsset,
                                locationID: homeID,
                                isInSelectionMode: backupMode != .none,
                                isSelected: selectedLocationIDs.contains(homeID)
                            ) {
                                if backupMode != .none {
                                    toggleSelection(homeID)
                                } else {
                                    seedIfNeeded(id: homeID,
                                                 title: homeTitle,
                                                 mapAsset: defaultMapAsset,
                                                 thumbAsset: defaultThumbAsset)
                                    locationManager.setCurrentLocation(homeID)
                                    locationManager.showLocationMenu = false
                                }
                            }

                            // --- Hard-coded chiclet: Museum (8192×8192 asset) ---
                            SelectableAssetLocationTile(
                                title: museumTitle,
                                imageName: museumThumbAsset,
                                locationID: museumID,
                                isInSelectionMode: backupMode != .none,
                                isSelected: selectedLocationIDs.contains(museumID)
                            ) {
                                if backupMode != .none {
                                    toggleSelection(museumID)
                                } else {
                                    seedIfNeeded(id: museumID,
                                                 title: museumTitle,
                                                 mapAsset: museumMapAsset,
                                                 thumbAsset: museumThumbAsset)
                                    locationManager.setCurrentLocation(museumID)
                                    locationManager.showLocationMenu = false
                                }
                            }

                            // --- Dynamic locations from sandbox, excluding the two hard-coded IDs ---
                            ForEach(locationSummaries.filter { $0.id != homeID && $0.id != museumID }) { summary in
                                SelectableLocationTileView(
                                    summary: summary,
                                    isInSelectionMode: backupMode != .none,
                                    isSelected: selectedLocationIDs.contains(summary.id)
                                ) {
                                    if backupMode != .none {
                                        toggleSelection(summary.id)
                                    } else {
                                        locationManager.setCurrentLocation(summary.id)
                                        locationManager.showLocationMenu = false
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }

                            // --- Square "New Map" tile at the end of the grid ---
                            if backupMode == .none {
                                NewMapTileView()
                                    .aspectRatio(1, contentMode: .fit)
                                    .onTapGesture { showingImportSheet = true }
                            }
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        _ = LocationImportUtils.reconcileLocationsOnMenuOpen(
                            seedDefaultIfEmpty: false,
                            defaultAssetName: nil
                        )
                        locationSummaries = LocationImportUtils.listLocationSummaries()
                    }
                    
                    // Backup/Restore controls at bottom
                    backupRestoreControls
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back to Map") {
                        locationManager.showLocationMenu = false
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Options") {
                        // Placeholder for future sort/filter options
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                // Seed both hard-coded locations idempotently.
                seedIfNeeded(id: homeID,
                             title: homeTitle,
                             mapAsset: defaultMapAsset,
                             thumbAsset: defaultThumbAsset)
                seedIfNeeded(id: museumID,
                             title: museumTitle,
                             mapAsset: museumMapAsset,
                             thumbAsset: museumThumbAsset)
                
                // Ensure correct names are set
                try? LocationImportUtils.renameLocation(id: homeID, newName: homeTitle)
                try? LocationImportUtils.renameLocation(id: museumID, newName: museumTitle)

                loadLocationSummaries()
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportSourceSheet(
                    onPhotosSelected: { showingPhotosPicker = true },
                    onFilesSelected: { showingDocumentPicker = true }
                )
            }
            .sheet(isPresented: $showingPhotosPicker) {
                PhotosImporter { image in
                    importFromImage(image)
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentImporter { url in
                    importFromFile(url)
                }
            }
            .fileExporter(
                isPresented: $showBackupPicker,
                document: backupURL.map { ZIPDocument(url: $0) },
                contentType: .zip,
                defaultFilename: backupURL?.lastPathComponent ?? "TapResolver_Backup.zip"
            ) { result in
                if case .success(let url) = result {
                    print("✅ Backup saved to: \(url)")
                }
            }
            .fileImporter(
                isPresented: $showRestorePicker,
                allowedContentTypes: [.zip],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        showRestoreConfirmation = true
                        backupURL = url
                    }
                case .failure(let error):
                    print("❌ File selection failed: \(error)")
                }
            }
            .alert("Restore Data?", isPresented: $showRestoreConfirmation) {
                Button("Cancel", role: .cancel) {
                    backupMode = .none
                    selectedLocationIDs.removeAll()
                }
                Button("Restore", role: .destructive) {
                    if let url = backupURL {
                        performRestore(from: url)
                    }
                }
            } message: {
                Text("This will overwrite \(selectedLocationIDs.count) location(s) with data from the backup file.\n\nAll existing data for these locations will be permanently replaced.")
            }
        }
    }

    private var backupRestoreControls: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.3))
            
            if backupMode == .none {
                // Default state: Show Backup and Restore buttons
                HStack(spacing: 16) {
                    Button(action: {
                        backupMode = .selectForBackup
                        selectedLocationIDs.removeAll()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("Backup")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        backupMode = .selectForRestore
                        selectedLocationIDs.removeAll()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                            Text("Restore")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                
            } else {
                // Selection mode: Show options and action buttons
                VStack(spacing: 12) {
                    if backupMode == .selectForBackup {
                        Toggle("Include map images", isOn: $includeAssets)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            backupMode = .none
                            selectedLocationIDs.removeAll()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button(backupMode == .selectForBackup ? "Backup Selected" : "Restore Selected") {
                            if backupMode == .selectForBackup {
                                performBackup()
                            } else {
                                showRestorePicker = true
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedLocationIDs.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(selectedLocationIDs.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
            }
        }
        .background(Color.black.opacity(0.9))
    }

    // MARK: - Seeding (idempotent)

    private func seedIfNeeded(id: String, title: String, mapAsset: String, thumbAsset: String) {
        // Uses your existing seeding util that writes into Documents/locations/<id>/...
        LocationImportUtils.seedSampleLocationIfMissing(
            assetName: mapAsset,
            thumbnailAssetName: thumbAsset,
            locationID: id,
            displayName: title,
            longEdge: 8192 // PRESERVE FULL RESOLUTION - do not downscale
        )
        
        // BACKUP SUPPORT: Copy embedded assets to Documents so they can be backed up
        copyEmbeddedAssetsToDocuments(locationID: id, mapAsset: mapAsset, thumbAsset: thumbAsset)
    }
    
    // MARK: - Asset Migration for Backup Support

    private func copyEmbeddedAssetsToDocuments(locationID: String, mapAsset: String, thumbAsset: String) {
        let ctx = PersistenceContext.shared
        let assetsDir = ctx.docs.appendingPathComponent("locations/\(locationID)/assets", isDirectory: true)
        
        // Create assets directory if it doesn't exist
        try? FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        
        // Copy map image at FULL RESOLUTION (if not already there)
        let mapDestination = assetsDir.appendingPathComponent("map_display.png")
        if !FileManager.default.fileExists(atPath: mapDestination.path),
           let mapImage = UIImage(named: mapAsset) {
            // Preserve EXACT resolution - no downscaling
            if let pngData = mapImage.pngData() {
                try? pngData.write(to: mapDestination)
                let sizeMB = Double(pngData.count) / 1_048_576.0
                print("📋 Copied embedded map image for '\(locationID)' to Documents (\(String(format: "%.1f", sizeMB)) MB, \(Int(mapImage.size.width))×\(Int(mapImage.size.height)))")
            }
        }
        
        // Copy thumbnail (if not already there)
        let thumbDestination = assetsDir.appendingPathComponent("thumbnail.jpg")
        if !FileManager.default.fileExists(atPath: thumbDestination.path),
           let thumbImage = UIImage(named: thumbAsset) {
            if let jpegData = thumbImage.jpegData(compressionQuality: 0.85) {
                try? jpegData.write(to: thumbDestination)
                print("📋 Copied embedded thumbnail for '\(locationID)' to Documents")
            }
        }
    }

    // MARK: - Data

    private func loadLocationSummaries() {
        let _ = LocationImportUtils.reconcileLocationsOnMenuOpen(
            seedDefaultIfEmpty: false,
            defaultAssetName: nil
        )
        locationSummaries = LocationImportUtils.listLocationSummaries()
        print("📋 Loaded \(locationSummaries.count) location summaries for menu")
    }

    private func importFromImage(_ image: UIImage) {
        do {
            let result = try LocationImportUtils.createLocation(fromImage: image, preferredName: nil)
            locationManager.setCurrentLocation(result.id)
            locationManager.showLocationMenu = false
            loadLocationSummaries()
        } catch {
            print("❌ Failed to import from image: \(error)")
        }
    }

    private func importFromFile(_ url: URL) {
        do {
            let result = try LocationImportUtils.createLocation(fromFile: url, proposedName: nil)
            locationManager.setCurrentLocation(result.id)
            locationManager.showLocationMenu = false
            loadLocationSummaries()
        } catch {
            print("❌ Failed to import from file: \(error)")
        }
    }

    // MARK: - Backup/Restore Helpers

    private func toggleSelection(_ locationID: String) {
        if selectedLocationIDs.contains(locationID) {
            selectedLocationIDs.remove(locationID)
        } else {
            selectedLocationIDs.insert(locationID)
        }
    }

    private func performBackup() {
        do {
            let zipURL = try UserDataBackup.backupLocations(
                locationIDs: Array(selectedLocationIDs),
                includeAssets: includeAssets
            )
            backupURL = zipURL
            showBackupPicker = true
            backupMode = .none
            selectedLocationIDs.removeAll()
        } catch {
            print("❌ Backup failed: \(error)")
        }
    }

    private func performRestore(from url: URL) {
        do {
            try UserDataBackup.restoreLocations(
                from: url,
                targetLocationIDs: Array(selectedLocationIDs)
            )
            backupMode = .none
            selectedLocationIDs.removeAll()
            loadLocationSummaries()
        } catch {
            print("❌ Restore failed: \(error)")
        }
    }
}

// MARK: - Hard-coded asset tile (square image + title below + white stroke)

private struct AssetLocationTile: View {
    let title: String
    let locationID: String
    let imageName: String
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                    } else {
                        // Fallback to bundle asset while loading
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 4, y: 2)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // Try loading from Documents first (migrated assets)
        let ctx = PersistenceContext.shared
        let thumbURL = ctx.docs.appendingPathComponent("locations/\(locationID)/assets/thumbnail.jpg")
        
        if let image = UIImage(contentsOfFile: thumbURL.path) {
            thumbnailImage = image
        }
        // Otherwise, fall back to bundle asset (already in Image(imageName))
    }
}

// Existing ImportSourceSheet remains unchanged
struct ImportSourceSheet: View {
    let onPhotosSelected: () -> Void
    let onFilesSelected: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Import New Map")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)

            VStack(spacing: 12) {
                Button(action: onPhotosSelected) {
                    HStack {
                        Image(systemName: "photo.on.rectangle").font(.title3)
                        Text("From Photos").font(.headline)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onFilesSelected) {
                    HStack {
                        Image(systemName: "folder").font(.title3)
                        Text("From Files").font(.headline)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Selectable Asset Tile

private struct SelectableAssetLocationTile: View {
    let title: String
    let imageName: String
    let locationID: String
    let isInSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                    } else {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .clipped()
                    }
                    
                    if isInSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                            .foregroundColor(isSelected ? .blue : .white)
                            .background(Circle().fill(Color.black.opacity(0.5)).padding(-4))
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.blue : Color.white, lineWidth: isSelected ? 3 : 2)
                )
                .shadow(radius: 4, y: 2)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // Try loading from Documents first (migrated assets)
        let ctx = PersistenceContext.shared
        let thumbURL = ctx.docs.appendingPathComponent("locations/\(locationID)/assets/thumbnail.jpg")
        
        if let image = UIImage(contentsOfFile: thumbURL.path) {
            thumbnailImage = image
        }
        // Otherwise, fall back to bundle asset (already in Image(imageName))
    }
}

// MARK: - Selectable Location Tile

private struct SelectableLocationTileView: View {
    let summary: LocationSummary
    let isInSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    
                    if isInSelectionMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                            .foregroundColor(isSelected ? .blue : .white)
                            .background(Circle().fill(Color.black.opacity(0.5)).padding(-4))
                            .padding(8)
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Text(summary.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(summary.updatedISO))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let image = UIImage(contentsOfFile: summary.thumbnailURL.path) else {
            return
        }
        thumbnailImage = image
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "Unknown"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

// MARK: - ZIP Document Wrapper

struct ZIPDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try data.write(to: tempURL)
        self.url = tempURL
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url)
    }
}

#Preview {
    LocationMenuView()
        .environmentObject(LocationManager())
}
