//
//  PhotoManagementView.swift
//  TapResolver
//
//  Photo management interface for MapPoint location photos
//

import SwiftUI

struct PhotoManagementView: View {
    @Binding var isPresented: Bool
    let locationID: String
    
    @State private var photos: [PhotoItem] = []
    @State private var selectedPhoto: PhotoItem? = nil
    @State private var processedCount = 0
    
    struct PhotoItem: Identifiable {
        let id: String
        let index: Int
        let image: UIImage
        let originalSizeKB: Double
        let locationID: String
        var action: PhotoAction = .keep
        var processedImage: UIImage?
        var processedSizeKB: Double?
        
        var targetPath: String {
            "/Documents/locations/\(locationID)/map-points/\(String(id.prefix(8))).jpg"
        }
    }
    
    enum PhotoAction {
        case keep
        case delete
        case resize(maxDimension: Int)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("MapPoint Photos: '\(locationID)'")
                        .font(.headline)
                    Text("\(photos.count) photos • \(String(format: "%.2f MB", totalOriginalSize)) total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if processedCount > 0 {
                        Text("Processed: \(processedCount)/\(photos.count)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Photo Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(photos) { photo in
                            PhotoCard(
                                photo: photo,
                                onTap: { selectedPhoto = photo },
                                onActionChange: { action in
                                    if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                                        photos[index].action = action
                                        processPhoto(at: index)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Action Bar
                HStack(spacing: 16) {
                    Button("Process All") {
                        processAllPhotos()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text("Will save: \(String(format: "%.2f MB", totalProcessedSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Save to Disk") {
                        savePhotosToDisk()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(processedCount != photos.count)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo, isPresented: .constant(true))
            }
        }
        .onAppear {
            loadPhotos()
        }
    }
    
    private var totalOriginalSize: Double {
        photos.reduce(0) { $0 + $1.originalSizeKB } / 1024
    }
    
    private var totalProcessedSize: Double {
        photos.reduce(0) { sum, photo in
            sum + (photo.processedSizeKB ?? photo.originalSizeKB)
        } / 1024
    }
    
    private func loadPhotos() {
        let extracted = UserDefaultsDiagnostics.extractPhotos(locationID: locationID)
        
        photos = extracted.compactMap { item in
            // Decode base64 to image
            guard let imageData = Data(base64Encoded: item.base64),
                  let image = UIImage(data: imageData) else {
                return nil
            }
            
            return PhotoItem(
                id: item.id,
                index: item.index,
                image: image,
                originalSizeKB: item.sizeKB,
                locationID: locationID
            )
        }
    }
    
    private func processPhoto(at index: Int) {
        guard index < photos.count else { return }
        let photo = photos[index]
        
        switch photo.action {
        case .keep:
            photos[index].processedImage = photo.image
            photos[index].processedSizeKB = photo.originalSizeKB
            processedCount += 1
            
        case .delete:
            photos[index].processedImage = nil
            photos[index].processedSizeKB = 0
            processedCount += 1
            
        case .resize(let maxDimension):
            if let resized = resizeImage(photo.image, maxDimension: maxDimension) {
                photos[index].processedImage = resized
                if let jpegData = resized.jpegData(compressionQuality: 0.8) {
                    photos[index].processedSizeKB = Double(jpegData.count) / 1024
                }
                processedCount += 1
            }
        }
    }
    
    private func processAllPhotos() {
        processedCount = 0
        for index in photos.indices {
            processPhoto(at: index)
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: Int) -> UIImage? {
        let size = image.size
        let maxOriginal = max(size.width, size.height)
        
        guard maxOriginal > CGFloat(maxDimension) else {
            return image // Already small enough
        }
        
        let scale = CGFloat(maxDimension) / maxOriginal
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized
    }
    
    private func savePhotosToDisk() {
        print("\n🗂️ SAVING PHOTOS TO DISK:")
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let locationDir = documentsURL.appendingPathComponent("locations/\(locationID)/map-points")
        
        // Create directory
        try? fileManager.createDirectory(at: locationDir, withIntermediateDirectories: true)
        
        var savedFiles: [String] = []
        
        for photo in photos {
            // Skip photos marked for deletion
            if case .delete = photo.action {
                print("  ⏭️ Skipping \(String(photo.id.prefix(8))) (marked for deletion)")
                continue
            }
            
            guard let image = photo.processedImage else {
                print("  ⏭️ Skipping \(String(photo.id.prefix(8))) (no processed image)")
                continue
            }
            
            let idShort = String(photo.id.prefix(8))
            let filename = "\(idShort).jpg"
            let fileURL = locationDir.appendingPathComponent(filename)
            
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try jpegData.write(to: fileURL)
                    let sizeKB = Double(jpegData.count) / 1024
                    print("  ✅ Saved \(filename): \(String(format: "%.2f KB", sizeKB))")
                    savedFiles.append(idShort)
                } catch {
                    print("  ❌ Failed to save \(filename): \(error)")
                }
            }
        }
        
        print("💾 Photo save complete!\n")
        
        // Now purge from UserDefaults
        if !savedFiles.isEmpty {
            UserDefaultsDiagnostics.purgePhotosFromUserDefaults(
                locationID: locationID,
                confirmedFilesSaved: savedFiles
            )
        }
        
        // Close view
        isPresented = false
    }
}

// MARK: - Photo Card

struct PhotoCard: View {
    let photo: PhotoManagementView.PhotoItem
    let onTap: () -> Void
    let onActionChange: (PhotoManagementView.PhotoAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image preview
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)
                .onTapGesture {
                    onTap()
                }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Index: \(photo.index)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(photo.id.prefix(8)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(photo.image.size.width))×\(Int(photo.image.size.height))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.0f KB", photo.originalSizeKB))
                    .font(.caption)
                    .foregroundColor(photo.originalSizeKB > 500 ? .red : .green)
            }
            
            // Action picker
            Picker("Action", selection: Binding(
                get: { actionToIndex(photo.action) },
                set: { onActionChange(indexToAction($0)) }
            )) {
                Text("Keep").tag(0)
                Text("Delete").tag(1)
                Text("512px").tag(2)
                Text("768px").tag(3)
                Text("1024px").tag(4)
            }
            .pickerStyle(.menu)
            .font(.caption)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func actionToIndex(_ action: PhotoManagementView.PhotoAction) -> Int {
        switch action {
        case .keep: return 0
        case .delete: return 1
        case .resize(let dim):
            if dim == 512 { return 2 }
            if dim == 768 { return 3 }
            if dim == 1024 { return 4 }
            return 0
        }
    }
    
    private func indexToAction(_ index: Int) -> PhotoManagementView.PhotoAction {
        switch index {
        case 0: return .keep
        case 1: return .delete
        case 2: return .resize(maxDimension: 512)
        case 3: return .resize(maxDimension: 768)
        case 4: return .resize(maxDimension: 1024)
        default: return .keep
        }
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: PhotoManagementView.PhotoItem
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(label: "Index", value: "\(photo.index)")
                        DetailRow(label: "ID", value: photo.id)
                        DetailRow(label: "Size", value: "\(Int(photo.image.size.width))×\(Int(photo.image.size.height))")
                        DetailRow(label: "Original", value: String(format: "%.2f KB", photo.originalSizeKB))
                        
                        if let processedSize = photo.processedSizeKB {
                            DetailRow(label: "Processed", value: String(format: "%.2f KB", processedSize))
                        }
                        
                        Text("Target Path")
                            .font(.headline)
                            .padding(.top)
                        
                        Text(photo.targetPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}

