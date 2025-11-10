import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import ZIPFoundation

// MARK: - Import Types

enum ConflictType {
    case none           // New location, no conflict
    case exactMatch     // originalID matches existing location
    case probableMatch  // Same name + dimensions, but no originalID match
}

struct ImportConflict {
    let locationID: String          // From import file
    let locationName: String
    let originalID: String
    let conflictType: ConflictType
    let existingLocation: LocationStub?
}

enum ImportAction {
    case skip
    case importAsNew
    case replace
}

struct ImportDecision {
    let conflict: ImportConflict
    var action: ImportAction
    var newName: String?
    var createBackup: Bool
    
    var finalLocationID: String {
        switch action {
        case .skip:
            return conflict.locationID
        case .importAsNew:
            return UUID().uuidString
        case .replace:
            return conflict.existingLocation?.id ?? conflict.locationID
        }
    }
}

enum ImportWizardState {
    case analyzing(URL)
    case reviewingConflict(ImportConflict, Archive, BackupMetadata)
    case namingNewLocation(ImportConflict, Archive, BackupMetadata)
    case confirmReplace(ImportConflict, Archive, BackupMetadata)
    case importing([ImportDecision], Archive)
    case complete([ImportResult])
}

struct ImportResult {
    let locationName: String
    let action: ImportAction
    let success: Bool
    let error: String?
    let backupPath: String?
}

struct WizardContext {
    let archive: Archive
    let metadata: BackupMetadata
    let conflicts: [ImportConflict]
    var currentIndex: Int
    var decisions: [ImportDecision]

    var currentConflict: ImportConflict? {
        guard currentIndex < conflicts.count else { return nil }
        return conflicts[currentIndex]
    }

    var progressText: String {
        return "Location \(currentIndex + 1) of \(conflicts.count)"
    }
}

struct LocationMenuView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    @EnvironmentObject private var mapPointStore: MapPointStore
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
    
    // Import state
    @State private var showingImportPicker = false
    @State private var importWizardState: ImportWizardState?
    @State private var importError: String?
    @State private var wizardContext: WizardContext?
    
    // Delete confirmation state
    @State private var locationToDelete: String?
    @State private var showDeleteConfirmation = false
    
    // Rename state
    @State private var locationToRename: String?
    @State private var showRenameDialog = false
    @State private var renameText = ""
    
    // AR Settings navigation
    @State private var selectedLocationForAR: String?

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
        NavigationStack {
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
                                isSelected: selectedLocationIDs.contains(homeID),
                                onTap: {
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
                                },
                                onGearTap: {
                                    // Set location context and show AR settings
                                    PersistenceContext.shared.locationID = homeID
                                    selectedLocationForAR = homeID
                                }
                        )

                        // --- Hard-coded chiclet: Museum (8192×8192 asset) ---
                            SelectableAssetLocationTile(
                            title: museumTitle,
                                imageName: museumThumbAsset,
                                locationID: museumID,
                                isInSelectionMode: backupMode != .none,
                                isSelected: selectedLocationIDs.contains(museumID),
                                onTap: {
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
                                },
                                onGearTap: {
                                    // Set location context and show AR settings
                                    PersistenceContext.shared.locationID = museumID
                                    selectedLocationForAR = museumID
                                }
                        )

                        // --- Dynamic locations from sandbox, excluding the two hard-coded IDs ---
                        ForEach(locationSummaries.filter { $0.id != homeID && $0.id != museumID }) { summary in
                                SelectableLocationTileView(
                                    summary: summary,
                                    isInSelectionMode: backupMode != .none,
                                    isSelected: selectedLocationIDs.contains(summary.id),
                                    onTap: {
                                    if backupMode != .none {
                                        toggleSelection(summary.id)
                                    } else {
                                        locationManager.setCurrentLocation(summary.id)
                                        locationManager.showLocationMenu = false
                                    }
                                    },
                                    onGearTap: {
                                        // Set location context and show AR settings
                                        PersistenceContext.shared.locationID = summary.id
                                        selectedLocationForAR = summary.id
                                    }
                                )
                                //.aspectRatio(1, contentMode: .fit)
                                .contextMenu {
                                    if backupMode == .none {
                                        Button {
                                            if let location = locationSummaries.first(where: { $0.id == summary.id }) {
                                                locationToRename = summary.id
                                                renameText = location.name
                                                showRenameDialog = true
                                            }
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            locationToDelete = summary.id
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }

                        // --- Square "New Map" tile at the end of the grid ---
                            if backupMode == .none {
                        NewMapTileView()
                                    //.aspectRatio(1, contentMode: .fit)
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
                    .navigationDestination(isPresented: Binding(
                        get: { selectedLocationForAR != nil },
                        set: { if !$0 { selectedLocationForAR = nil } }
                    )) {
                        if let locationID = selectedLocationForAR {
                            ARSurveyPlaceholderView(locationID: locationID)
                        }
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
                    onPhotosSelected: {
                        showingImportSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingPhotosPicker = true
                        }
                    },
                    onFilesSelected: {
                        showingImportSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingDocumentPicker = true
                        }
                    }
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
                contentType: UTType(filenameExtension: "tapmap") ?? .zip,
                defaultFilename: backupURL?.lastPathComponent ?? "TapResolver_Backup.tapmap"
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
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [UTType(filenameExtension: "tapmap") ?? .zip],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        handleImportFile(url)
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                    print("❌ Import file selection failed: \(error)")
                }
            }
            .sheet(isPresented: Binding(
                get: { importWizardState != nil },
                set: { if !$0 {
                    importWizardState = nil
                    wizardContext = nil
                }}
            )) {
                if let state = importWizardState, let context = wizardContext {
                    ImportWizardSheet(
                        state: state,
                        context: context,
                        onActionChoice: { action in
                            handleActionChoice(action)
                        },
                        onDecision: { decision in
                            recordDecisionAndAdvance(decision)
                        },
                        onExecute: { decisions, archive in
                            executeImport(decisions: decisions, archive: archive)
                        },
                        onCancel: {
                            importWizardState = nil
                            wizardContext = nil
                        }
                    )
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
            .alert("Delete Location?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    locationToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let locationID = locationToDelete {
                        deleteLocation(locationID)
                    }
                    locationToDelete = nil
                }
            } message: {
                if let locationID = locationToDelete,
                   let location = locationSummaries.first(where: { $0.id == locationID }) {
                    Text("Are you sure you want to delete '\(location.name)'? This action cannot be undone.")
                }
            }
            .alert("Rename Location", isPresented: $showRenameDialog) {
                TextField("Location Name", text: $renameText)
                
                Button("Cancel", role: .cancel) {
                    locationToRename = nil
                    renameText = ""
                }
                
                Button("Save") {
                    if let locationID = locationToRename, !renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        renameLocation(locationID, newName: renameText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    locationToRename = nil
                    renameText = ""
                }
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
                        showingImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import")
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
           let mapImage = UIImage(named: mapAsset),
           let pngData = mapImage.pngData() {
            try? pngData.write(to: mapDestination)
        }
        
        // Copy thumbnail (if not already there)
        let thumbDestination = assetsDir.appendingPathComponent("thumbnail.jpg")
        if !FileManager.default.fileExists(atPath: thumbDestination.path),
           let thumbImage = UIImage(named: thumbAsset),
           let jpegData = thumbImage.jpegData(compressionQuality: 0.85) {
            try? jpegData.write(to: thumbDestination)
        }
    }

    // MARK: - Data

    private func loadLocationSummaries() {
        let _ = LocationImportUtils.reconcileLocationsOnMenuOpen(
            seedDefaultIfEmpty: false,
            defaultAssetName: nil
        )
        locationSummaries = LocationImportUtils.listLocationSummaries()
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
    
    // MARK: - Import Functions
    
    private func handleImportFile(_ url: URL) {
        // Request access to security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Permission denied to access file"
            print("❌ Could not access security-scoped resource: \(url)")
            return
        }
        
        // Ensure we stop accessing when done
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            // 1. Copy to temporary location
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.copyItem(at: url, to: tempURL)
            
            print("📦 Importing from: \(tempURL.lastPathComponent)")
            
            // 2. Open as ZIP archive
            guard let archive = Archive(url: tempURL, accessMode: .read) else {
                throw NSError(domain: "ImportError", code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Invalid archive"])
            }
            
            // 3. Extract metadata.json
            guard let metadataEntry = archive["metadata.json"] else {
                throw NSError(domain: "ImportError", code: 2,
                             userInfo: [NSLocalizedDescriptionKey: "Missing metadata.json"])
            }
            
            var metadataData = Data()
            _ = try archive.extract(metadataEntry) { data in
                metadataData.append(data)
            }
            
            let metadata = try JSONDecoder().decode(BackupMetadata.self, from: metadataData)
            
            // 4. Validate format
            guard metadata.format == "tapresolver.backup.v1" else {
                throw NSError(domain: "ImportError", code: 3,
                             userInfo: [NSLocalizedDescriptionKey: "Unsupported format: \(metadata.format)"])
            }
            
            print("✅ Archive valid: \(metadata.locations.count) locations")
            
            // 5. Detect conflicts
            let conflicts = detectConflicts(metadata: metadata)
            
            // 6. Print analysis (keep for debugging)
            for conflict in conflicts {
                let icon = conflict.conflictType == .none ? "🆕" :
                          conflict.conflictType == .exactMatch ? "🔄" : "❓"
                print("\(icon) \(conflict.locationName) - \(conflict.conflictType)")
                
                if let existing = conflict.existingLocation,
                   let importMeta = metadata.locations.first(where: { $0.id == conflict.locationID }) {
                    let rec = recommendAction(for: conflict,
                                             importMetadata: importMeta,
                                             backupMetadata: metadata,
                                             existingStub: existing)
                    print("   Recommendation: \(rec.0) - \(rec.1)")
                }
            }
            
            // 7. Start wizard
            wizardContext = WizardContext(
                archive: archive,
                metadata: metadata,
                conflicts: conflicts,
                currentIndex: 0,
                decisions: []
            )
            
            // Show first conflict
            if let firstConflict = conflicts.first {
                importWizardState = .reviewingConflict(firstConflict, archive, metadata)
            }
            
        } catch {
            importError = error.localizedDescription
            print("❌ Import failed: \(error)")
        }
    }
    
    private func detectConflicts(metadata: BackupMetadata) -> [ImportConflict] {
        var conflicts: [ImportConflict] = []
        
        // Get all existing locations
        let existingLocationIDs = LocationImportUtils.listSandboxLocationIDs()
        let existingStubs = existingLocationIDs.compactMap { locationID -> LocationStub? in
            let ctx = PersistenceContext.shared
            let stubURL = ctx.docs.appendingPathComponent("locations/\(locationID)/location.json")
            guard let data = try? Data(contentsOf: stubURL),
                  let stub = try? JSONDecoder().decode(LocationStub.self, from: data) else {
                return nil
            }
            return stub
        }
        
        // Check each location in import for conflicts
        for importedLocation in metadata.locations {
            // Strategy 1: Check originalID (definitive)
            if let existing = existingStubs.first(where: { $0.originalID == importedLocation.originalID }) {
                conflicts.append(ImportConflict(
                    locationID: importedLocation.id,
                    locationName: importedLocation.name,
                    originalID: importedLocation.originalID,
                    conflictType: .exactMatch,
                    existingLocation: existing
                ))
            }
            // Strategy 2: Check name + dimensions (heuristic)
            else if let existing = existingStubs.first(where: {
                $0.name == importedLocation.name &&
                $0.displayWidth == importedLocation.mapDimensions[0] &&
                $0.displayHeight == importedLocation.mapDimensions[1]
            }) {
                conflicts.append(ImportConflict(
                    locationID: importedLocation.id,
                    locationName: importedLocation.name,
                    originalID: importedLocation.originalID,
                    conflictType: .probableMatch,
                    existingLocation: existing
                ))
            }
            // No conflict
            else {
                conflicts.append(ImportConflict(
                    locationID: importedLocation.id,
                    locationName: importedLocation.name,
                    originalID: importedLocation.originalID,
                    conflictType: .none,
                    existingLocation: nil
                ))
            }
        }
        
        return conflicts
    }
    
    private func recommendAction(for conflict: ImportConflict,
                                importMetadata: BackupMetadata.LocationSummary,
                                backupMetadata: BackupMetadata,
                                existingStub: LocationStub?) -> (ImportAction, String) {
        guard let existing = existingStub else {
            return (.importAsNew, "New location - safe to import")
        }
        
        let formatter = ISO8601DateFormatter()
        let importDate = formatter.date(from: backupMetadata.exportDate) ?? Date.distantPast
        let localDate = formatter.date(from: existing.updatedISO) ?? Date.distantPast
        
        if importDate > localDate {
            if importMetadata.sessionCount > existing.sessionCount {
                return (.replace, "⚠️ Import is newer with MORE data (\(importMetadata.sessionCount) vs \(existing.sessionCount) sessions)")
            } else {
                return (.skip, "Import is newer but has LESS data. Keep your version?")
            }
        } else {
            if existing.sessionCount > importMetadata.sessionCount {
                return (.skip, "✅ Your version is newer with MORE data (\(existing.sessionCount) vs \(importMetadata.sessionCount) sessions) [Recommended]")
            } else {
                return (.importAsNew, "Your version is newer but import has more data. Import both to compare?")
            }
        }
    }
    
    private func handleActionChoice(_ action: ImportAction) {
        guard let context = wizardContext,
              let conflict = context.currentConflict else { return }

        switch action {
        case .skip:
            let decision = ImportDecision(
                conflict: conflict,
                action: .skip,
                newName: nil,
                createBackup: false
            )
            recordDecisionAndAdvance(decision)

        case .importAsNew:
            importWizardState = .namingNewLocation(conflict, context.archive, context.metadata)

        case .replace:
            importWizardState = .confirmReplace(conflict, context.archive, context.metadata)
        }
    }

    private func recordDecisionAndAdvance(_ decision: ImportDecision) {
        guard var context = wizardContext else { return }

        print("📝 Decision: \(decision.action) for \(decision.conflict.locationName)")

        context.decisions.append(decision)
        context.currentIndex += 1
        wizardContext = context

        if let nextConflict = context.currentConflict {
            importWizardState = .reviewingConflict(nextConflict, context.archive, context.metadata)
        } else {
            importWizardState = .importing(context.decisions, context.archive)
        }
    }
    
    // MARK: - Import Execution
    
    private func executeImport(decisions: [ImportDecision], archive: Archive) {
        print("\n" + String(repeating: "=", count: 80))
        print("🚀 EXECUTING IMPORT")
        print(String(repeating: "=", count: 80))
        
        var results: [ImportResult] = []
        
        for decision in decisions {
            let result: ImportResult
            
            switch decision.action {
            case .skip:
                result = ImportResult(
                    locationName: decision.conflict.locationName,
                    action: .skip,
                    success: true,
                    error: nil,
                    backupPath: nil
                )
                print("⏭️  Skipped: \(decision.conflict.locationName)")
                
            case .importAsNew:
                result = executeImportAsNew(decision: decision, archive: archive)
                
            case .replace:
                result = executeReplace(decision: decision, archive: archive)
            }
            
            results.append(result)
        }
        
        print("\n✅ IMPORT COMPLETE")
        print("   Success: \(results.filter { $0.success }.count)/\(results.count)")
        print(String(repeating: "=", count: 80) + "\n")
        
        // Show completion screen
        importWizardState = .complete(results)
        
        // Reload location list
        loadLocationSummaries()
    }

    private func executeImportAsNew(decision: ImportDecision, archive: Archive) -> ImportResult {
        do {
            let newLocationID = UUID().uuidString
            let newName = decision.newName ?? (decision.conflict.locationName + " (Imported)")
            
            print("📦 Importing as new: \(newName) (ID: \(newLocationID))")
            
            // Extract location from archive
            try extractLocationFromArchive(
                archive: archive,
                sourceLocationID: decision.conflict.locationID,
                targetLocationID: newLocationID
            )
            
            // Update location stub with new name and ID
            try updateLocationStub(
                locationID: newLocationID,
                newName: newName,
                originalID: decision.conflict.originalID
            )
            
            print("✅ Import successful: \(newName)")
            
            return ImportResult(
                locationName: newName,
                action: .importAsNew,
                success: true,
                error: nil,
                backupPath: nil
            )
        } catch {
            print("❌ Import failed: \(decision.conflict.locationName) - \(error)")
            return ImportResult(
                locationName: decision.conflict.locationName,
                action: .importAsNew,
                success: false,
                error: error.localizedDescription,
                backupPath: nil
            )
        }
    }

    private func executeReplace(decision: ImportDecision, archive: Archive) -> ImportResult {
        guard let existingLocation = decision.conflict.existingLocation else {
            return ImportResult(
                locationName: decision.conflict.locationName,
                action: .replace,
                success: false,
                error: "No existing location found",
                backupPath: nil
            )
        }
        
        do {
            var backupPath: String? = nil
            
            // Create backup if requested
            if decision.createBackup {
                print("💾 Creating backup before replace...")
                let backupID = "\(existingLocation.id)_backup_\(Int(Date().timeIntervalSince1970))"
                try createLocationBackup(
                    sourceLocationID: existingLocation.id,
                    backupLocationID: backupID
                )
                backupPath = backupID
                print("✅ Backup created: \(backupID)")
            }
            
            print("🔄 Replacing: \(existingLocation.name)")
            
            // Delete existing location data
            try deleteLocationData(locationID: existingLocation.id)
            
            // Extract from archive to existing ID
            try extractLocationFromArchive(
                archive: archive,
                sourceLocationID: decision.conflict.locationID,
                targetLocationID: existingLocation.id
            )
            
            // Preserve the name (don't rename on replace)
            try updateLocationStub(
                locationID: existingLocation.id,
                newName: existingLocation.name,
                originalID: decision.conflict.originalID
            )
            
            print("✅ Replace successful: \(existingLocation.name)")
            
            return ImportResult(
                locationName: existingLocation.name,
                action: .replace,
                success: true,
                error: nil,
                backupPath: backupPath
            )
        } catch {
            print("❌ Replace failed: \(decision.conflict.locationName) - \(error)")
            return ImportResult(
                locationName: decision.conflict.locationName,
                action: .replace,
                success: false,
                error: error.localizedDescription,
                backupPath: nil
            )
        }
    }
    
    private func extractLocationFromArchive(archive: Archive, sourceLocationID: String, targetLocationID: String) throws {
        let ctx = PersistenceContext.shared
        let targetDir = ctx.docs.appendingPathComponent("locations/\(targetLocationID)", isDirectory: true)
        
        // Create target directory
        try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        
        print("   📂 Extracting to: \(targetLocationID)")
        
        // Extract all files for this location
        for entry in archive {
            let entryPath = entry.path
            
            // Check if this entry belongs to the source location
            if entryPath.hasPrefix("\(sourceLocationID)/") {
                // Calculate relative path and target path
                let relativePath = String(entryPath.dropFirst("\(sourceLocationID)/".count))
                let targetPath = targetDir.appendingPathComponent(relativePath)
                
                // Create parent directory if needed
                let parentDir = targetPath.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                
                // Extract file
                if entry.type == .file {
                    _ = try archive.extract(entry, to: targetPath)
                    print("      ✓ \(relativePath)")
                }
            }
        }
        
        // Restore UserDefaults data
        let userDefaultsFile = targetDir.appendingPathComponent("userdefaults.json")
        if FileManager.default.fileExists(atPath: userDefaultsFile.path) {
            let data = try Data(contentsOf: userDefaultsFile)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            let ud = UserDefaults.standard
            let prefix = "locations.\(targetLocationID)."
            
            for (key, value) in dict {
                // Convert Base64 strings back to Data objects
                if let dataDict = value as? [String: String],
                   let base64String = dataDict["__data_base64"],
                   let restoredData = Data(base64Encoded: base64String) {
                    ud.set(restoredData, forKey: prefix + key)
                } else {
                    ud.set(value, forKey: prefix + key)
                }
            }
            
            print("      ✓ Restored UserDefaults (\(dict.count) keys)")
        }
    }

    private func updateLocationStub(locationID: String, newName: String, originalID: String) throws {
        let ctx = PersistenceContext.shared
        let stubURL = ctx.docs.appendingPathComponent("locations/\(locationID)/location.json")
        
        // Read existing stub
        let data = try Data(contentsOf: stubURL)
        var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Update ID and name
        dict["id"] = locationID
        dict["name"] = newName
        // Keep originalID from import (this preserves the lineage)
        
        // Write back
        let updatedData = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try updatedData.write(to: stubURL)
        
        print("      ✓ Updated stub: \(newName)")
    }

    private func deleteLocationData(locationID: String) throws {
        let ctx = PersistenceContext.shared
        let locationDir = ctx.docs.appendingPathComponent("locations/\(locationID)")
        
        // Delete directory
        try FileManager.default.removeItem(at: locationDir)
        
        // Clear UserDefaults keys
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let locationKeys = allKeys.filter { $0.contains("locations.\(locationID).") }
        
        for key in locationKeys {
            defaults.removeObject(forKey: key)
        }
        
        print("      ✓ Deleted existing data")
    }

    private func createLocationBackup(sourceLocationID: String, backupLocationID: String) throws {
        let ctx = PersistenceContext.shared
        let sourceDir = ctx.docs.appendingPathComponent("locations/\(sourceLocationID)")
        let backupDir = ctx.docs.appendingPathComponent("locations/\(backupLocationID)")
        
        // Copy entire directory
        try FileManager.default.copyItem(at: sourceDir, to: backupDir)
        
        // Update stub with backup ID and name
        let stubURL = backupDir.appendingPathComponent("location.json")
        let data = try Data(contentsOf: stubURL)
        var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        dict["id"] = backupLocationID
        if let currentName = dict["name"] as? String {
            dict["name"] = currentName + " (Backup)"
        }
        
        let updatedData = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
        try updatedData.write(to: stubURL)
        
        // Copy UserDefaults keys
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let locationKeys = allKeys.filter { $0.contains("locations.\(sourceLocationID).") }
        
        for key in locationKeys {
            if let value = defaults.object(forKey: key) {
                let backupKey = key.replacingOccurrences(of: "locations.\(sourceLocationID).", with: "locations.\(backupLocationID).")
                defaults.set(value, forKey: backupKey)
            }
        }
    }
    
    private func deleteLocation(_ locationID: String) {
        print("\n🗑️ Deleting location: \(locationID)")
        
        do {
            let ctx = PersistenceContext.shared
            let locationDir = ctx.docs.appendingPathComponent("locations/\(locationID)")
            
            // 1. Delete directory
            if FileManager.default.fileExists(atPath: locationDir.path) {
                try FileManager.default.removeItem(at: locationDir)
                print("   ✓ Deleted directory")
            }
            
            // 2. Clear UserDefaults keys
            let defaults = UserDefaults.standard
            let allKeys = defaults.dictionaryRepresentation().keys
            let locationKeys = allKeys.filter { $0.contains("locations.\(locationID).") }
            
            for key in locationKeys {
                defaults.removeObject(forKey: key)
            }
            print("   ✓ Cleared \(locationKeys.count) UserDefaults keys")
            
            // 3. Reload location list
            loadLocationSummaries()
            
            print("✅ Location deleted successfully\n")
            
        } catch {
            print("❌ Delete failed: \(error)\n")
        }
    }
    
    private func renameLocation(_ locationID: String, newName: String) {
        print("\n✏️ Renaming location: \(locationID) to '\(newName)'")
        
        do {
            try LocationImportUtils.renameLocation(id: locationID, newName: newName)
            print("✅ Location renamed successfully\n")
            
            // Reload location list
            loadLocationSummaries()
            
        } catch {
            print("❌ Rename failed: \(error)\n")
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
    let onGearTap: () -> Void
    
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
                    
                    // Gear icon overlay (top-right corner)
                    if !isInSelectionMode {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    onGearTap()
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                }
                                .buttonStyle(.plain)
                                .padding(8)
                            }
                            Spacer()
                        }
                    } else if isInSelectionMode {
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
    let onGearTap: () -> Void
    
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
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                    
                    // Gear icon overlay (top-right corner)
                    if !isInSelectionMode {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    onGearTap()
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                }
                                .buttonStyle(.plain)
                                .padding(8)
                            }
                            Spacer()
                        }
                    } else if isInSelectionMode {
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

                Text(summary.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                /*Text(formatDate(summary.updatedISO))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))*/
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

// MARK: - Import Wizard Views

struct ImportWizardSheet: View {
    let state: ImportWizardState
    let context: WizardContext
    let onActionChoice: (ImportAction) -> Void
    let onDecision: (ImportDecision) -> Void
    let onExecute: ([ImportDecision], Archive) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            switch state {
            case .reviewingConflict(let conflict, _, let metadata):
                ReviewConflictView(
                    conflict: conflict,
                    metadata: metadata,
                    context: context,
                    onActionChoice: onActionChoice,
                    onCancel: onCancel
                )

            case .namingNewLocation(let conflict, _, let metadata):
                NameNewLocationView(
                    conflict: conflict,
                    metadata: metadata,
                    onDecision: onDecision,
                    onCancel: onCancel
                )

            case .confirmReplace(let conflict, _, let metadata):
                ConfirmReplaceView(
                    conflict: conflict,
                    metadata: metadata,
                    onDecision: onDecision,
                    onCancel: onCancel
                )

            case .importing(let decisions, let archive):
                ImportSummaryView(
                    decisions: decisions,
                    archive: archive,
                    onExecute: {
                        onExecute(decisions, archive)
                    },
                    onCancel: onCancel
                )

            case .complete(let results):
                ImportCompleteView(
                    results: results,
                    onDismiss: onCancel
                )

            case .analyzing:
                ProgressView("Analyzing backup...")
                    .foregroundColor(.white)
            }
        }
    }
}

struct ReviewConflictView: View {
    let conflict: ImportConflict
    let metadata: BackupMetadata
    let context: WizardContext
    let onActionChoice: (ImportAction) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(context.progressText)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            Text(conflict.locationName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            conflictIndicator

            if let existing = conflict.existingLocation,
               let importMeta = metadata.locations.first(where: { $0.id == conflict.locationID }) {
                recommendationText(conflict: conflict, importMeta: importMeta, existing: existing, metadata: metadata)
            }

            VStack(spacing: 12) {
                actionButton(title: "Skip", color: .gray, action: .skip)
                actionButton(title: "Import as New", color: .blue, action: .importAsNew)

                if conflict.existingLocation != nil {
                    actionButton(title: "Replace Existing", color: .red, action: .replace)
                }
            }
            .padding(.top, 8)

            Button("Cancel Import") {
                onCancel()
            }
            .foregroundColor(.white.opacity(0.5))
            .padding(.top)
        }
        .padding(32)
    }

    private var conflictIndicator: some View {
        HStack {
            Image(systemName: conflictIcon)
                .font(.largeTitle)
            Text(conflictText)
                .font(.headline)
        }
        .foregroundColor(conflictColor)
        .padding()
        .background(conflictColor.opacity(0.2))
        .cornerRadius(12)
    }

    private var conflictIcon: String {
        switch conflict.conflictType {
        case .none: return "plus.circle"
        case .exactMatch: return "arrow.triangle.2.circlepath"
        case .probableMatch: return "questionmark.circle"
        }
    }

    private var conflictText: String {
        switch conflict.conflictType {
        case .none: return "New Location"
        case .exactMatch: return "Exact Match Found"
        case .probableMatch: return "Possible Match Found"
        }
    }

    private var conflictColor: Color {
        switch conflict.conflictType {
        case .none: return .green
        case .exactMatch: return .orange
        case .probableMatch: return .yellow
        }
    }

    private func recommendationText(conflict: ImportConflict, importMeta: BackupMetadata.LocationSummary, existing: LocationStub, metadata: BackupMetadata) -> some View {
        let formatter = ISO8601DateFormatter()
        let importDate = formatter.date(from: metadata.exportDate) ?? Date.distantPast
        let localDate = formatter.date(from: existing.updatedISO) ?? Date.distantPast
        
        // Format dates for display
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd 'at' h:mma"
        
        let importDateStr = dateFormatter.string(from: importDate)
        let localDateStr = dateFormatter.string(from: localDate)
        
        // Build comparison text
        let comparisonText = """
        📦 Import version:
        Last updated: \(importDateStr)
        Data: \(importMeta.beaconCount) beacons, \(importMeta.sessionCount) sessions
        
        📱 Current version:
        Last updated: \(localDateStr)
        Data: \(existing.beaconCount) beacons, \(existing.sessionCount) sessions
        """
        
        // Add recommendation
        let recommendation: String
        if importDate > localDate && importMeta.sessionCount > existing.sessionCount {
            recommendation = "\n\n💡 Recommendation: Import version is newer with more data. Consider replacing."
        } else if localDate > importDate && existing.sessionCount > importMeta.sessionCount {
            recommendation = "\n\n💡 Recommendation: Current version is newer with more data. Consider skipping."
        } else if importMeta.sessionCount > existing.sessionCount {
            recommendation = "\n\n💡 Recommendation: Import has more data. Consider importing as new to compare."
        } else {
            recommendation = "\n\n💡 Recommendation: Current version has equal or more data. Consider skipping."
        }
        
        return Text(comparisonText + recommendation)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .multilineTextAlignment(.leading)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
    }

    private func actionButton(title: String, color: Color, action: ImportAction) -> some View {
        Button(action: {
            onActionChoice(action)
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(12)
        }
    }
}

struct NameNewLocationView: View {
    let conflict: ImportConflict
    let metadata: BackupMetadata
    let onDecision: (ImportDecision) -> Void
    let onCancel: () -> Void

    @State private var newName: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Import as New Location")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Enter a name for the imported location:")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))

            TextField("Location Name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onAppear {
                    newName = conflict.locationName + " (Imported)"
                    isTextFieldFocused = true
                }

            HStack(spacing: 12) {
                Button("Back") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Continue") {
                    let decision = ImportDecision(
                        conflict: conflict,
                        action: .importAsNew,
                        newName: newName,
                        createBackup: false
                    )
                    onDecision(decision)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(32)
    }
}

struct ConfirmReplaceView: View {
    let conflict: ImportConflict
    let metadata: BackupMetadata
    let onDecision: (ImportDecision) -> Void
    let onCancel: () -> Void

    @State private var createBackup: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Replace Existing Location?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("This will overwrite '\(conflict.locationName)' with imported data.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            if let existing = conflict.existingLocation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current location has:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("• \(existing.beaconCount) beacons")
                        .foregroundColor(.white)
                    Text("• \(existing.sessionCount) scan sessions")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.red.opacity(0.2))
                .cornerRadius(8)
            }

            Toggle("Create backup before replacing", isOn: $createBackup)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Replace") {
                    let decision = ImportDecision(
                        conflict: conflict,
                        action: .replace,
                        newName: nil,
                        createBackup: createBackup
                    )
                    onDecision(decision)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(32)
    }
}

struct ImportSummaryView: View {
    let decisions: [ImportDecision]
    let archive: Archive
    let onExecute: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Review Import Plan")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(decisions.count) location(s) to process")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(decisions.enumerated()), id: \.offset) { index, decision in
                        DecisionRowView(decision: decision)
                    }
                }
            }
            .frame(maxHeight: 400)

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Confirm") {
                    onExecute()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(32)
    }
}

struct DecisionRowView: View {
    let decision: ImportDecision

    var body: some View {
        HStack {
            Image(systemName: actionIcon)
                .foregroundColor(actionColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(decision.conflict.locationName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(actionText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                if let newName = decision.newName {
                    Text("New name: \(newName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                if decision.createBackup {
                    Text("✓ Will create backup first")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }

    private var actionIcon: String {
        switch decision.action {
        case .skip: return "xmark.circle"
        case .importAsNew: return "plus.circle"
        case .replace: return "arrow.triangle.2.circlepath"
        }
    }

    private var actionColor: Color {
        switch decision.action {
        case .skip: return .gray
        case .importAsNew: return .green
        case .replace: return .orange
        }
    }

    private var actionText: String {
        switch decision.action {
        case .skip: return "Skip (will not import)"
        case .importAsNew: return "Import as new location"
        case .replace: return "Replace existing location"
        }
    }
}

struct ImportCompleteView: View {
    let results: [ImportResult]
    let onDismiss: () -> Void

    var successCount: Int {
        results.filter { $0.success }.count
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: successCount == results.count ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(successCount == results.count ? .green : .orange)

            Text("Import Complete")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(successCount) of \(results.count) location(s) imported successfully")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        ResultRowView(result: result)
                    }
                }
            }
            .frame(maxHeight: 400)

            Button("Done") {
                onDismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(32)
    }
}

struct ResultRowView: View {
    let result: ImportResult

    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.locationName)
                    .font(.headline)
                    .foregroundColor(.white)

                if result.success {
                    Text(successText)
                        .font(.caption)
                        .foregroundColor(.green)
                } else if let error = result.error {
                    Text("Failed: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if let backupPath = result.backupPath {
                    Text("Backup: \(backupPath)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }

    private var successText: String {
        switch result.action {
        case .skip: return "Skipped"
        case .importAsNew: return "Imported as new"
        case .replace: return "Replaced existing"
        }
    }
}

private struct ARSurveyPlaceholderView: View {
    let locationID: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arkit")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("AR survey tools coming soon")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Location ID: \(locationID)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    LocationMenuView()
        .environmentObject(LocationManager())
}
