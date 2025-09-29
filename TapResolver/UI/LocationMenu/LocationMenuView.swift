import SwiftUI
import PhotosUI

struct LocationMenuView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @State private var locationSummaries: [LocationSummary] = []
    @State private var showingImportSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingDocumentPicker = false

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

                ScrollView {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 12) {

                        // --- Hard-coded chiclet: Home/Chris's House ---
                        AssetLocationTile(
                            title: homeTitle,
                            imageName: defaultThumbAsset
                        ) {
                            seedIfNeeded(id: homeID,
                                         title: homeTitle,
                                         mapAsset: defaultMapAsset,
                                         thumbAsset: defaultThumbAsset)
                            locationManager.setCurrentLocation(homeID)
                            locationManager.showLocationMenu = false
                        }

                        // --- Hard-coded chiclet: Museum (8192×8192 asset) ---
                        AssetLocationTile(
                            title: museumTitle,
                            imageName: museumThumbAsset
                        ) {
                            seedIfNeeded(id: museumID,
                                         title: museumTitle,
                                         mapAsset: museumMapAsset,
                                         thumbAsset: museumThumbAsset)
                            locationManager.setCurrentLocation(museumID)
                            locationManager.showLocationMenu = false
                        }

                        // --- Dynamic locations from sandbox, excluding the two hard-coded IDs ---
                        ForEach(locationSummaries.filter { $0.id != homeID && $0.id != museumID }) { summary in
                            LocationTileView(summary: summary) {
                                locationManager.setCurrentLocation(summary.id)
                                locationManager.showLocationMenu = false
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }

                        // --- Square "New Map" tile at the end of the grid ---
                        NewMapTileView()
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture { showingImportSheet = true }
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
        }
    }

    // MARK: - Seeding (idempotent)

    private func seedIfNeeded(id: String, title: String, mapAsset: String, thumbAsset: String) {
        // Uses your existing seeding util that writes into Documents/locations/<id>/...
        LocationImportUtils.seedSampleLocationIfMissing(
            assetName: mapAsset,
            thumbnailAssetName: thumbAsset,
            locationID: id,
            displayName: title,
            longEdge: 4096 // downscale 8192x8192 to a display-friendly PNG
        )
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
}

// MARK: - Hard-coded asset tile (square image + title below + white stroke)

private struct AssetLocationTile: View {
    let title: String
    let imageName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
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

#Preview {
    LocationMenuView()
        .environmentObject(LocationManager())
}
