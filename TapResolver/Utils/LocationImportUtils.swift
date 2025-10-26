//
//  LocationImportUtils.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/27/25.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import CoreGraphics
import ImageIO
import MobileCoreServices

// MARK: - Sandbox Paths (Authoritative)

enum SandboxPaths {
    static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var locationsRoot: URL {
        documents.appendingPathComponent("locations", isDirectory: true)
    }
    static func locationDir(_ id: String) -> URL {
        locationsRoot.appendingPathComponent(id, isDirectory: true)
    }
    static func assetsDir(_ id: String) -> URL {
        locationDir(id).appendingPathComponent("assets", isDirectory: true)
    }
    static func displayURL(_ id: String) -> URL {
        assetsDir(id).appendingPathComponent("map_display.png", isDirectory: false)
    }
    static func thumbnailURL(_ id: String) -> URL {
        assetsDir(id).appendingPathComponent("thumbnail.jpg", isDirectory: false)
    }
    static func stubURL(_ id: String) -> URL {
        locationDir(id).appendingPathComponent("location.json", isDirectory: false)
    }
}

/// Minimal model written to `location.json` inside each location folder.
/// This is intentionally small; we can extend it later without breaking older files.
struct LocationStub: Codable {
    var id: String
    var name: String
    let originalID: String  // NEW: Unique identifier that persists across renames
    var createdISO: String
    let createdBy: String  // NEW: Author who created this location
    var updatedISO: String
    var lastModifiedBy: String  // NEW: Author who last modified this location
    // Relative (to the location folder) asset paths
    let mapOriginalRel: String
    let mapDisplayRel: String
    let thumbnailRel: String
    // Pixel dimensions of the display image (what the app should render)
    let displayWidth: Int
    let displayHeight: Int
    var beaconCount: Int  // NEW: Number of beacons (from dots.json)
    var sessionCount: Int  // NEW: Number of scan sessions (from UserDefaults)
}

/// Returned to the caller after a successful import.
struct LocationCreationResult {
    let id: String
    let name: String
    let locationDir: URL
    let mapOriginalURL: URL
    let mapDisplayURL: URL
    let thumbnailURL: URL
    let displaySize: CGSize
}

/// A lightweight summary for the Location Menu.
struct LocationSummary: Identifiable, Codable {
    let id: String
    let name: String
    let updatedISO: String
    let thumbnailURL: URL
    let displaySize: CGSize
}

enum LocationImportError: Error, LocalizedError {
    case unsupportedType
    case imageDecodeFailed
    case writeFailed(String)
    case fileExistsConflict
    case invalidDestination
    case imageTooLarge(Int) // megapixels

    var errorDescription: String? {
        switch self {
        case .unsupportedType: return "Unsupported file type."
        case .imageDecodeFailed: return "Could not decode the image."
        case .writeFailed(let msg): return "Write failed: \(msg)"
        case .fileExistsConflict: return "Location folder already exists."
        case .invalidDestination: return "Invalid destination path."
        case .imageTooLarge(let mp): return "Image too large (\(mp) megapixels). Maximum allowed: 120 megapixels."
        }
    }
}

// MARK: - Sandbox Operations (Read/Write from Documents only)
/// Load the map image from the sandbox
func loadDisplayImageFromSandbox(locationID: String) -> UIImage? {
    let path = SandboxPaths.displayURL(locationID).path
    return UIImage(contentsOfFile: path)
}

/// Seed the default location from the bundle asset (one-time copy)
func seedDefaultIfMissing(bundleAssetName: String, preferredName: String = "Default Location") {
    let fm = FileManager.default
    let id = "default"
    let stubURL = SandboxPaths.stubURL(id)

    // If the stub exists, we're done.
    if fm.fileExists(atPath: stubURL.path) { return }

    // Load bundled asset by name (read-only bundle).
    guard let img = UIImage(named: bundleAssetName) else {
        print("⚠️ Bundled asset '\(bundleAssetName)' not found in Assets.xcassets")
        return
    }

    // Create folders and write files into the sandbox.
    try? fm.createDirectory(at: SandboxPaths.assetsDir(id), withIntermediateDirectories: true)

    // Write display image
    if let data = (img.pngData() ?? img.jpegData(compressionQuality: 0.95)) {
        try? data.write(to: SandboxPaths.displayURL(id), options: .atomic)
    }

    // Write thumbnail
    let longEdge: CGFloat = 512
    let scaled = downscaled(image: img, longEdge: longEdge)
    if let tdata = scaled.jpegData(compressionQuality: 0.9) {
        try? tdata.write(to: SandboxPaths.thumbnailURL(id), options: .atomic)
    }

    // Minimal stub
    struct Stub: Codable {
        let id, name, createdISO, updatedISO: String
        let mapOriginalRel, mapDisplayRel, thumbnailRel: String
        let displayWidth, displayHeight: Int
    }
    let now = ISO8601DateFormatter().string(from: Date())
    let stub = Stub(
        id: id,
        name: preferredName,
        createdISO: now,
        updatedISO: now,
        mapOriginalRel: "assets/map_display.png", // fine if original unknown
        mapDisplayRel: "assets/map_display.png",
        thumbnailRel: "assets/thumbnail.jpg",
        displayWidth: Int(img.size.width.rounded()),
        displayHeight: Int(img.size.height.rounded())
    )
    if let data = try? JSONEncoder().encode(stub) {
        try? data.write(to: stubURL, options: .atomic)
    }

    // Track last opened
    UserDefaults.standard.set(id, forKey: "locations.lastOpened.v1")
    print("✅ Seeded default location at: \(SandboxPaths.locationDir(id).path)")
}

/// Tiny helper to downscale
func downscaled(image: UIImage, longEdge: CGFloat) -> UIImage {
    let w = image.size.width, h = image.size.height
    let maxEdge = max(w, h)
    guard maxEdge > longEdge, longEdge > 0 else { return image }
    let scale = longEdge / maxEdge
    let target = CGSize(width: w * scale, height: h * scale)
    UIGraphicsBeginImageContextWithOptions(target, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: target))
    let out = UIGraphicsGetImageFromCurrentImageContext() ?? image
    UIGraphicsEndImageContext()
    return out
}

/// Reconcile one folder: ensure stub + thumbnail exist
func reconcileFolder(locationID: String) {
    let fm = FileManager.default
    try? fm.createDirectory(at: SandboxPaths.assetsDir(locationID), withIntermediateDirectories: true)

    // Ensure display image exists (skip if not)
    guard fm.fileExists(atPath: SandboxPaths.displayURL(locationID).path) else { return }

    // Ensure thumbnail exists
    if !fm.fileExists(atPath: SandboxPaths.thumbnailURL(locationID).path),
       let img = UIImage(contentsOfFile: SandboxPaths.displayURL(locationID).path) {
        let t = downscaled(image: img, longEdge: 512)
        if let data = t.jpegData(compressionQuality: 0.9) {
            try? data.write(to: SandboxPaths.thumbnailURL(locationID), options: .atomic)
        }
    }

    // Ensure stub exists
    if !fm.fileExists(atPath: SandboxPaths.stubURL(locationID).path) {
        let now = ISO8601DateFormatter().string(from: Date())
        struct Stub: Codable {
            let id, name, createdISO, updatedISO: String
            let mapOriginalRel, mapDisplayRel, thumbnailRel: String
            let displayWidth, displayHeight: Int
        }
        let img = UIImage(contentsOfFile: SandboxPaths.displayURL(locationID).path)
        let w = Int((img?.size.width ?? 0).rounded())
        let h = Int((img?.size.height ?? 0).rounded())
        let stub = Stub(
            id: locationID,
            name: "Unnamed Location",
            createdISO: now,
            updatedISO: now,
            mapOriginalRel: "assets/map_display.png",
            mapDisplayRel: "assets/map_display.png",
            thumbnailRel: "assets/thumbnail.jpg",
            displayWidth: w,
            displayHeight: h
        )
        if let data = try? JSONEncoder().encode(stub) {
            try? data.write(to: SandboxPaths.stubURL(locationID), options: .atomic)
        }
    }
}

/// Menu hook: reconcile + list from Documents
func refreshLocationMenuData(bundleDefaultAssetName: String) -> [String] {
    // Log sandbox paths (not bundle internals)
    let home = NSHomeDirectory()
    print("🏠 App home: \(home)")
    print("📁 Documents: \(SandboxPaths.documents.path)")
    print("📂 Locations root: \(SandboxPaths.locationsRoot.path)")
    
    // Seed default if the sandbox is empty (first run)
    let ids = LocationImportUtils.listSandboxLocationIDs()
    print("🔍 Found locations: \(ids)")
    
    if ids.isEmpty {
        print("🌱 No locations found, seeding default...")
        seedDefaultIfMissing(bundleAssetName: bundleDefaultAssetName)
    }
    
    // Reconcile each folder (stub + thumbnail guarantees chiclet)
    for id in LocationImportUtils.listSandboxLocationIDs() {
        reconcileFolder(locationID: id)
    }
    
    // Return final IDs for the menu to render
    let finalIds = LocationImportUtils.listSandboxLocationIDs()
    return finalIds
}

import UIKit

extension LocationImportUtils {
    /// Create a sample/default location from bundled assets if it doesn't already exist.
    /// Also backfills a missing thumbnail for an existing stub when `thumbnailAssetName` is provided.
    static func seedSampleLocationIfMissing(assetName: String,
                                            thumbnailAssetName: String? = nil,
                                            locationID: String = "default",
                                            displayName: String = "Sample Location",
                                            longEdge: CGFloat = 4096) {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let locDir   = docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
        let assets   = locDir.appendingPathComponent("assets", isDirectory: true)
        let scansDir = locDir.appendingPathComponent("scan_summaries", isDirectory: true)
        let stubURL  = locDir.appendingPathComponent("location.json")
        let display  = assets.appendingPathComponent("map_display.png")
        let thumb    = assets.appendingPathComponent("thumbnail.jpg")

        let ensureThumbFromBundled: () -> Void = {
            guard let tn = thumbnailAssetName, let timg = UIImage(named: tn) else { return }
            try? fm.createDirectory(at: assets, withIntermediateDirectories: true)
            if let tdata = timg.jpegData(compressionQuality: 0.9) {
                try? tdata.write(to: thumb, options: .atomic)
            }
        }

        // If stub already exists, we only backfill a missing thumbnail (if requested) and return.
        if fm.fileExists(atPath: stubURL.path) {
            if !fm.fileExists(atPath: thumb.path) { ensureThumbFromBundled() }
            return
        }

        // Seed from bundled map asset
        guard let ui = UIImage(named: assetName) else {
            print("⚠️ seedSampleLocationIfMissing: asset '\(assetName)' not found in bundle.")
            return
        }

        // Ensure directories
        do {
            try fm.createDirectory(at: assets,   withIntermediateDirectories: true)
            try fm.createDirectory(at: scansDir, withIntermediateDirectories: true)
        } catch {
            print("⚠️ seedSampleLocationIfMissing: dir create failed: \(error)")
            return
        }

        // Write display-sized PNG
        let displayImg = ui.downscaled(longEdge: longEdge)
        guard let displayData = displayImg.pngData() else { return }
        try? displayData.write(to: display, options: .atomic)

        // Prefer bundled thumbnail if provided; else derive from display
        if fm.fileExists(atPath: thumb.path) == false {
            if let tn = thumbnailAssetName, let timg = UIImage(named: tn), let tdata = timg.jpegData(compressionQuality: 0.9) {
                try? tdata.write(to: thumb, options: .atomic)
            } else {
                let thumbImg = displayImg.downscaled(longEdge: 512)
                if let tdata = thumbImg.jpegData(compressionQuality: 0.9) {
                    try? tdata.write(to: thumb, options: .atomic)
                }
            }
        }

        // Minimal, self-describing stub for the menu
        let now = ISO8601DateFormatter().string(from: Date())
        let stub = LocationStub(
            id: locationID,
            name: displayName,
            originalID: UUID().uuidString,  // NEW
            createdISO: now,
            createdBy: AppSettings.authorName,  // NEW
            updatedISO: now,
            lastModifiedBy: AppSettings.authorName,  // NEW
            mapOriginalRel: "assets/\(display.lastPathComponent)", // fine if original unknown
            mapDisplayRel: "assets/\(display.lastPathComponent)",
            thumbnailRel: "assets/\(thumb.lastPathComponent)",
            displayWidth: Int(displayImg.size.width.rounded()),
            displayHeight: Int(displayImg.size.height.rounded()),
            beaconCount: 0,  // NEW - will be updated when beacons are added
            sessionCount: 0  // NEW - will be updated when sessions are recorded
        )
        if let data = try? JSONEncoder().encode(stub) {
            try? data.write(to: stubURL, options: .atomic)
        }

        // Keep behavior: open last-used
        UserDefaults.standard.set(locationID, forKey: "locations.lastOpened.v1")
        PersistenceContext.shared.locationID = locationID

        print("✅ Seeded sample location '\(displayName)' with thumbnail at \(locDir.path)")
    }
}


/// Utilities for creating and enumerating locations on disk.
/// This does NOT change the active PersistenceContext location; it simply creates new ones.
enum LocationImportUtils {

    // MARK: - Public API
    
    /// Enumerate sandbox locations (not the bundle)
    static func listSandboxLocationIDs() -> [String] {
        let fm = FileManager.default
        try? fm.createDirectory(at: SandboxPaths.locationsRoot, withIntermediateDirectories: true)

        let dirs = (try? fm.contentsOfDirectory(
            at: SandboxPaths.locationsRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return dirs.filter(\.hasDirectoryPath).map(\.lastPathComponent).sorted()
    }

    /// Create a new location from an on-disk image file.
    /// - Parameters:
    ///   - fileURL: Source image URL (e.g., from Files picker).
    ///   - proposedName: Optional human-friendly name; defaults to filename (no extension).
    ///   - maxDisplayDimension: Long edge cap for the display image. Keep memory/rendering happy.
    static func createLocation(fromFile fileURL: URL,
                               proposedName: String? = nil,
                               maxDisplayDimension: CGFloat = 4096) throws -> LocationCreationResult {
        let data = try Data(contentsOf: fileURL)
        guard let srcImage = UIImage(data: data)?.normalized() else { throw LocationImportError.imageDecodeFailed }
        
        // Validate image size for memory safety
        let megapixels = (srcImage.size.width * srcImage.size.height) / 1_000_000
        if megapixels > 120 {
            throw LocationImportError.imageTooLarge(Int(megapixels))
        }
        
        let baseName = proposedName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fileURL.deletingPathExtension().lastPathComponent
        
        // Use original image with NO scaling
        return try createLocation(fromImage: srcImage,
                                  preferredName: baseName,
                                  originalData: data,
                                  originalExt: fileURL.pathExtension,
                                  maxDisplayDimension: .infinity)  // No cap - use original size
    }

    /// Create a new location from a UIImage (e.g., from Photos picker).
    /// - Parameters:
    ///   - image: Source image.
    ///   - preferredName: Optional name shown in the menu.
    ///   - maxDisplayDimension: Long edge cap for the display image.
    static func createLocation(fromImage image: UIImage,
                               preferredName: String? = nil,
                               maxDisplayDimension: CGFloat = 4096) throws -> LocationCreationResult {
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.95) else {
            throw LocationImportError.imageDecodeFailed
        }
        let ext = image.pngData() != nil ? "png" : "jpg"
        let baseName = preferredName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "New Map"
        
        // Use original image with NO scaling
        return try createLocation(fromImage: image.normalized(),
                                  preferredName: baseName,
                                  originalData: data,
                                  originalExt: ext,
                                  maxDisplayDimension: .infinity)  // No cap - use original size
    }

    /// Enumerate all existing locations for the Location Menu grid.
    static func listLocationSummaries() -> [LocationSummary] {
        let root = docs.appendingPathComponent("locations", isDirectory: true)
        guard let children = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var out: [LocationSummary] = []
        for dir in children {
            guard dir.hasDirectoryPath else { continue }
            let stubURL = dir.appendingPathComponent("location.json")
            guard let data = try? Data(contentsOf: stubURL),
                  let stub = try? JSONDecoder().decode(LocationStub.self, from: data) else { continue }
            let thumb = dir.appendingPathComponent(stub.thumbnailRel)
            let size = CGSize(width: stub.displayWidth, height: stub.displayHeight)
            out.append(LocationSummary(id: stub.id, name: stub.name, updatedISO: stub.updatedISO, thumbnailURL: thumb, displaySize: size))
        }
        // Most recent first
        return out.sorted { $0.updatedISO > $1.updatedISO }
    }

    /// Convenience for loading the display image when opening a location.
    static func loadDisplayImage(locationID: String) -> UIImage? {
        let dir = docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
        let stubURL = dir.appendingPathComponent("location.json")
        guard let data = try? Data(contentsOf: stubURL),
              let stub = try? JSONDecoder().decode(LocationStub.self, from: data) else { return nil }
        let displayURL = dir.appendingPathComponent(stub.mapDisplayRel)
        guard let imgData = try? Data(contentsOf: displayURL), let ui = UIImage(data: imgData) else { return nil }
        return ui
    }
    
    // MARK: - Location Management Operations
    
    /// Rename an existing location
    static func renameLocation(id: String, newName: String) throws {
        let dir = docs.appendingPathComponent("locations/\(id)", isDirectory: true)
        let stubURL = dir.appendingPathComponent("location.json")
        
        guard let data = try? Data(contentsOf: stubURL),
              var stub = try? JSONDecoder().decode(LocationStub.self, from: data) else {
            throw LocationImportError.invalidDestination
        }
        
        stub.name = newName
        stub.updatedISO = ISO8601DateFormatter().string(from: Date())
        
        let updatedData = try JSONEncoder().encode(stub)
        try updatedData.write(to: stubURL, options: .atomic)
    }
    
    /// Delete a location and its folder
    static func deleteLocation(id: String) throws {
        let dir = docs.appendingPathComponent("locations/\(id)", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: dir.path) else {
            throw LocationImportError.invalidDestination
        }
        
        try FileManager.default.removeItem(at: dir)
    }
    
    /// Duplicate an existing location with a new ID
    static func duplicateLocation(id: String) throws -> LocationCreationResult {
        let sourceDir = docs.appendingPathComponent("locations/\(id)", isDirectory: true)
        let newID = UUID().uuidString.lowercased()
        let destDir = docs.appendingPathComponent("locations/\(newID)", isDirectory: true)
        
        guard FileManager.default.fileExists(atPath: sourceDir.path) else {
            throw LocationImportError.invalidDestination
        }
        
        // Copy the entire folder
        try FileManager.default.copyItem(at: sourceDir, to: destDir)
        
        // Update the location.json with new ID and name
        let stubURL = destDir.appendingPathComponent("location.json")
        guard let data = try? Data(contentsOf: stubURL),
              var stub = try? JSONDecoder().decode(LocationStub.self, from: data) else {
            throw LocationImportError.invalidDestination
        }
        
        stub.id = newID
        stub.name = "\(stub.name) (Copy)"
        stub.createdISO = ISO8601DateFormatter().string(from: Date())
        stub.updatedISO = stub.createdISO
        
        let updatedData = try JSONEncoder().encode(stub)
        try updatedData.write(to: stubURL, options: .atomic)
        
        // Build result from the duplicated location
        let assetsDir = destDir.appendingPathComponent("assets", isDirectory: true)
        let originalURL = assetsDir.appendingPathComponent("map_original.jpg") // Assume jpg for now
        let displayURL = assetsDir.appendingPathComponent("map_display.png")
        let thumbnailURL = assetsDir.appendingPathComponent("thumbnail.jpg")
        
        return LocationCreationResult(
            id: newID,
            name: stub.name,
            locationDir: destDir,
            mapOriginalURL: originalURL,
            mapDisplayURL: displayURL,
            thumbnailURL: thumbnailURL,
            displaySize: CGSize(width: stub.displayWidth, height: stub.displayHeight)
        )
    }
    
    // MARK: - Location Reconciliation
    
    /// Reconcile locations on menu open - ensures every location has proper metadata
    @discardableResult
    static func reconcileLocationsOnMenuOpen(seedDefaultIfEmpty: Bool,
                                             defaultAssetName: String?) -> [LocationSummary] {
        let fm = FileManager.default
        
        let root = docs.appendingPathComponent("locations", isDirectory: true)
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)

        // 1) If empty and seeding is requested, seed default from bundled asset.
        let existingFolders = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        
        if seedDefaultIfEmpty,
           existingFolders.isEmpty,
           let asset = defaultAssetName {
            ensureDefaultLocationPresenceIfNeeded(assetName: asset, preferredName: "Default Location", maxDisplayDimension: 4096)
        }

        // 2) For each subfolder, ensure stub + thumbnail + name.
        let folders = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        
        for dir in folders where dir.hasDirectoryPath {
            let id = dir.lastPathComponent
            guard var stub = ensureStubForLocation(at: dir, id: id) else { 
                print("❌ Failed to ensure stub for location: \(id)")
                continue 
            }
            
            // Name fallback
            if stub.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                stub.name = "Unnamed Location"
            }
            
            // Thumbnail ensure
            ensureThumbnail(for: dir, stub: &stub)
            
            // Persist stub (if changed)
            let stubURL = dir.appendingPathComponent("location.json")
            if let data = try? JSONEncoder().encode(stub) {
                try? data.write(to: stubURL, options: .atomic)
            } else {
                print("❌ Failed to encode/write stub for location: \(id)")
            }
        }

        return listLocationSummaries()
    }

    // MARK: - Private Reconciliation Helpers
    
    /// Ensure a stub exists; create it if missing by probing assets images.
    private static func ensureStubForLocation(at dir: URL, id: String) -> LocationStub? {
        print("🔍 Checking location: \(id)")
        print("📂 Location directory: \(dir.path)")
        
        // STEP 1: Check if location.json already exists
        let stubURL = dir.appendingPathComponent("location.json")
        print("📄 Checking for existing stub at: \(stubURL.path)")
        
        if let data = try? Data(contentsOf: stubURL),
           let stub = try? JSONDecoder().decode(LocationStub.self, from: data) {
            print("📋 Found existing stub for location: \(id)")
            print("   - Name: \(stub.name)")
            print("   - Display image: \(stub.mapDisplayRel)")
            print("   - Thumbnail: \(stub.thumbnailRel)")
            
            // Check if stub is complete (has all required fields)
            if !stub.mapDisplayRel.isEmpty && !stub.thumbnailRel.isEmpty {
                print("✅ Location \(id) has complete stub - no action needed")
                return stub
            }
            print("⚠️ Location \(id) has incomplete stub, regenerating...")
            // If incomplete, we'll regenerate it below
        } else {
            print("⚠️ Location \(id) has no stub, creating...")
        }
        
        // STEP 2: Look for existing image assets in the location folder
        let assets = dir.appendingPathComponent("assets", isDirectory: true)
        print("📁 Checking assets directory: \(assets.path)")
        
        // Check if assets directory exists
        let fm = FileManager.default
        if !fm.fileExists(atPath: assets.path) {
            print("📁 Assets directory doesn't exist, creating it...")
            try? fm.createDirectory(at: assets, withIntermediateDirectories: true)
        }
        
        // List all files in assets directory
        let assetFiles = (try? fm.contentsOfDirectory(at: assets, includingPropertiesForKeys: nil)) ?? []
        print("📋 Found \(assetFiles.count) files in assets directory:")
        for file in assetFiles {
            print("   - \(file.lastPathComponent)")
        }
        
        // STEP 3: Try to find display image first
        let display = assets.appendingPathComponent("map_display.png")
        print("🖼️ Looking for display image at: \(display.path)")
        
        if fm.fileExists(atPath: display.path) {
            print("✅ Found existing display image")
            if let img = UIImage(contentsOfFile: display.path)?.normalized() {
                print("✅ Successfully loaded display image: \(img.size)")
                return writeStub(id: id, dir: dir, img: img, displayURL: display)
            } else {
                print("❌ Failed to load display image")
            }
        } else {
            print("❌ Display image not found")
        }
        
        // STEP 4: Try to find original image as fallback
        print("🔍 Looking for original image files...")
        let originalFiles = assetFiles.filter { $0.lastPathComponent.hasPrefix("map_original.") }
        print("📋 Found \(originalFiles.count) original image files")
        
        if let originalURL = originalFiles.first {
            print("🖼️ Found original image: \(originalURL.lastPathComponent)")
            if let img = UIImage(contentsOfFile: originalURL.path)?.normalized() {
                print("✅ Successfully loaded original image: \(img.size)")
                
                // Create display copy for consistency
                let displayURL = assets.appendingPathComponent("map_display.png")
                print("📝 Creating display copy at: \(displayURL.path)")
                let displayImage = img.downscaled(longEdge: 4096)
                if let data = displayImage.pngData() { 
                    try? data.write(to: displayURL, options: .atomic)
                    print("✅ Created display image from original")
                }
                return writeStub(id: id, dir: dir, img: img, displayURL: displayURL)
            } else {
                print("❌ Failed to load original image")
            }
        } else {
            print("❌ No original images found")
        }
        
        // STEP 5: If no images found, try to create from bundled asset
        print("🔍 No local images found, trying to load bundled asset...")
        
        // COMPREHENSIVE BUNDLE EXPLORATION
        print("🔍 === COMPREHENSIVE BUNDLE EXPLORATION ===")
        print("📱 Bundle identifier: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("📱 Bundle path: \(Bundle.main.bundlePath)")
        
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Resource path: \(resourcePath)")
            let resourceURL = URL(fileURLWithPath: resourcePath)
            
            // List ALL files in bundle recursively
            print("📋 === ALL BUNDLE FILES ===")
            let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            var fileCount = 0
            while let fileURL = enumerator?.nextObject() as? URL {
                fileCount += 1
                let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let prefix = isDir ? "📁" : "📄"
                let relativePath = fileURL.path.replacingOccurrences(of: resourcePath, with: "")
                print("\(prefix) \(relativePath)")
                if fileCount > 50 { // Limit output
                    print("... (showing first 50 files)")
                    break
                }
            }
            print("📊 Total files found: \(fileCount)")
        }
        
        // Try multiple asset name variations
        let assetVariations = [
            "myFirstFloor_v03-metric",
            "myFirstFloor_v03-metric.png", 
            "myFirstFloor_v03-metric.jpg",
            "myFirstFloor_v03-metric.jpeg",
            "myFirstFloor_v03-metric",
            "myFirstFloor_v03-metric.png"
        ]
        
        print("🔍 === TRYING ASSET VARIATIONS ===")
        for (index, assetName) in assetVariations.enumerated() {
            print("🔍 Attempt \(index + 1): Looking for '\(assetName)'")
            
            let (name, ext) = assetName.contains(".") ? 
                (String(assetName.dropLast(4)), String(assetName.suffix(4))) :
                (assetName, nil)
            
            if let assetURL = Bundle.main.url(forResource: name, withExtension: ext) {
                print("✅ FOUND ASSET: \(assetURL.path)")
                if let imageData = try? Data(contentsOf: assetURL) {
                    print("✅ Loaded image data: \(imageData.count) bytes")
                    if let img = UIImage(data: imageData)?.normalized() {
                        print("✅ Created UIImage from bundled asset: \(img.size)")
                        
                        // Create display image
                        let displayURL = assets.appendingPathComponent("map_display.png")
                        print("📝 Creating display image from bundled asset at: \(displayURL.path)")
                        let displayImage = img.downscaled(longEdge: 4096)
                        if let data = displayImage.pngData() {
                            try? data.write(to: displayURL, options: .atomic)
                            print("✅ Created display image from bundled asset")
                        } else {
                            print("❌ Failed to create display image from bundled asset")
                        }
                        return writeStub(id: id, dir: dir, img: img, displayURL: displayURL)
                    } else {
                        print("❌ Failed to create UIImage from bundled asset data")
                    }
                } else {
                    print("❌ Failed to load image data from bundled asset: \(assetURL.path)")
                }
            } else {
                print("❌ Asset not found: '\(assetName)'")
            }
        }
        
        // Try to find ANY image files in the bundle
        print("🔍 === SEARCHING FOR ANY IMAGE FILES ===")
        if let resourcePath = Bundle.main.resourcePath {
            let resourceURL = URL(fileURLWithPath: resourcePath)
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff"]
            var foundImages: [URL] = []
            
            for ext in imageExtensions {
                let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                while let fileURL = enumerator?.nextObject() as? URL {
                    if fileURL.pathExtension.lowercased() == ext {
                        foundImages.append(fileURL)
                    }
                }
            }
            
            print("🖼️ Found \(foundImages.count) image files:")
            for imgURL in foundImages.prefix(20) { // Show first 20
                let relativePath = imgURL.path.replacingOccurrences(of: resourcePath, with: "")
                print("   📄 \(relativePath)")
            }
        }
        
        print("❌ Failed to create stub for location: \(id) - no suitable images found")
        return nil
    }
    
    /// Write a location stub (metadata file) for a location
    private static func writeStub(id: String, dir: URL, img: UIImage, displayURL: URL) -> LocationStub? {
        print("📝 Writing stub for location: \(id)")
        print("   - Image size: \(img.size)")
        print("   - Display URL: \(displayURL.path)")
        
        let now = ISO8601DateFormatter().string(from: Date())
        let assets = dir.appendingPathComponent("assets", isDirectory: true)
        print("📁 Ensuring assets directory exists: \(assets.path)")
        try? FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
        
        let stub = LocationStub(
            id: id,
            name: "Unnamed Location",
            originalID: UUID().uuidString,  // NEW
            createdISO: now,
            createdBy: AppSettings.authorName,  // NEW
            updatedISO: now,
            lastModifiedBy: AppSettings.authorName,  // NEW
            mapOriginalRel: "assets/\(displayURL.lastPathComponent)", // we may not know original; ok
            mapDisplayRel: "assets/\(displayURL.lastPathComponent)",
            thumbnailRel: "assets/thumbnail.jpg",
            displayWidth: Int(img.size.width.rounded()),
            displayHeight: Int(img.size.height.rounded()),
            beaconCount: 0,  // NEW - will be updated when beacons are added
            sessionCount: 0  // NEW - will be updated when sessions are recorded
        )
        
        print("📋 Created stub with:")
        print("   - ID: \(stub.id)")
        print("   - Name: \(stub.name)")
        print("   - Display image: \(stub.mapDisplayRel)")
        print("   - Thumbnail: \(stub.thumbnailRel)")
        print("   - Dimensions: \(stub.displayWidth)x\(stub.displayHeight)")
        
        let stubURL = dir.appendingPathComponent("location.json")
        print("💾 Writing stub to: \(stubURL.path)")
        
        if let data = try? JSONEncoder().encode(stub) {
            do {
                try data.write(to: stubURL, options: .atomic)
                print("✅ Successfully wrote stub for location: \(id)")
                return stub
            } catch {
                print("❌ Failed to write stub file: \(error)")
            }
        } else {
            print("❌ Failed to encode stub data")
        }
        return nil
    }
    
    /// Ensure a thumbnail exists for the location; create it if missing
    private static func ensureThumbnail(for dir: URL, stub: inout LocationStub) {
        let thumbURL = dir.appendingPathComponent(stub.thumbnailRel)
        print("🖼️ Checking for thumbnail at: \(thumbURL.path)")
        
        if FileManager.default.fileExists(atPath: thumbURL.path) { 
            print("✅ Thumbnail already exists, skipping creation")
            return 
        }
        
        print("📝 Thumbnail missing, creating from display image...")
        let displayURL = dir.appendingPathComponent(stub.mapDisplayRel)
        print("🖼️ Loading display image from: \(displayURL.path)")
        
        guard let img = UIImage(contentsOfFile: displayURL.path)?.normalized() else { 
            print("❌ Failed to load display image for thumbnail creation")
            return 
        }
        
        print("✅ Loaded display image: \(img.size)")
        print("📏 Creating thumbnail (max 512px)...")
        let thumb = img.downscaled(longEdge: 512)
        print("✅ Created thumbnail: \(thumb.size)")
        
        if let data = thumb.jpegData(compressionQuality: 0.9) {
            print("💾 Writing thumbnail data: \(data.count) bytes")
            do {
                try data.write(to: thumbURL, options: .atomic)
                print("✅ Successfully created thumbnail at: \(thumbURL.path)")
                stub.updatedISO = ISO8601DateFormatter().string(from: Date())
                print("📅 Updated stub timestamp")
            } catch {
                print("❌ Failed to write thumbnail: \(error)")
            }
        } else {
            print("❌ Failed to create thumbnail JPEG data")
        }
    }

    // MARK: - Default Location Management
    
    /// Ensure a default location exists from bundled asset
    static func ensureDefaultLocationPresenceIfNeeded(assetName: String, preferredName: String, maxDisplayDimension: CGFloat) {
        let root = docs.appendingPathComponent("locations", isDirectory: true)
        let fm = FileManager.default
        
        // Check if locations folder is empty
        let existingFolders = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        if !existingFolders.isEmpty { return } // Already has locations
        
        // Try to find the bundled asset
        guard let assetURL = Bundle.main.url(forResource: assetName, withExtension: nil) else {
            print("⚠️ Could not find bundled asset: \(assetName)")
            return
        }
        
        do {
            let imageData = try Data(contentsOf: assetURL)
            guard let image = UIImage(data: imageData)?.normalized() else {
                print("⚠️ Could not load image from bundled asset: \(assetName)")
                return
            }
            
            let result = try createLocation(fromImage: image, preferredName: preferredName, originalData: imageData, originalExt: assetURL.pathExtension, maxDisplayDimension: maxDisplayDimension)
            print("✅ Created default location: \(result.name) (\(result.id))")
        } catch {
            print("❌ Failed to create default location: \(error)")
        }
    }

    // MARK: - Internals

    private static var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Core creation routine shared by file/UIImage entry points.
    private static func createLocation(fromImage image: UIImage,
                                       preferredName: String,
                                       originalData: Data,
                                       originalExt: String,
                                       maxDisplayDimension: CGFloat) throws -> LocationCreationResult {
        // 1) Generate a stable new ID
        let id = UUID().uuidString.lowercased()

        // 2) Build folder layout
        let root = docs.appendingPathComponent("locations", isDirectory: true)
        let locDir = root.appendingPathComponent(id, isDirectory: true)
        let assetsDir = locDir.appendingPathComponent("assets", isDirectory: true)
        let scansDir = locDir.appendingPathComponent("scan_summaries", isDirectory: true)

        try FileManager.default.createDirectory(at: assetsDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: scansDir, withIntermediateDirectories: true)

        // 3) Persist assets: original, display, thumbnail
        let originalName = "map_original.\(originalExt.safeLowercasedImageExt())"
        let displayName = "map_display.png"
        let thumbName = "thumbnail.jpg"

        let originalURL = assetsDir.appendingPathComponent(originalName)
        try writeAtomic(data: originalData, to: originalURL)

        // Use original image directly - no downscaling
        let displayImage = image
        guard let displayData = displayImage.pngData() else { throw LocationImportError.writeFailed("PNG encode failed") }
        let displayURL = assetsDir.appendingPathComponent(displayName)
        try writeAtomic(data: displayData, to: displayURL)

        // Thumbnail (e.g., 512 px long edge)
        let thumbImage = displayImage.downscaled(longEdge: 512)
        guard let thumbData = thumbImage.jpegData(compressionQuality: 0.9) else { throw LocationImportError.writeFailed("JPEG encode failed") }
        let thumbURL = assetsDir.appendingPathComponent(thumbName)
        try writeAtomic(data: thumbData, to: thumbURL)

        // 4) location.json
        let now = ISO8601DateFormatter().string(from: Date())
        let stub = LocationStub(
            id: id,
            name: preferredName,
            originalID: UUID().uuidString,  // NEW
            createdISO: now,
            createdBy: AppSettings.authorName,  // NEW
            updatedISO: now,
            lastModifiedBy: AppSettings.authorName,  // NEW
            mapOriginalRel: "assets/\(originalName)",
            mapDisplayRel: "assets/\(displayName)",
            thumbnailRel: "assets/\(thumbName)",
            displayWidth: Int(displayImage.size.width.rounded()),
            displayHeight: Int(displayImage.size.height.rounded()),
            beaconCount: 0,  // NEW - will be updated when beacons are added
            sessionCount: 0  // NEW - will be updated when sessions are recorded
        )
        let locJSON = locDir.appendingPathComponent("location.json")
        let stubData = try JSONEncoder().encode(stub)
        try writeAtomic(data: stubData, to: locJSON)

        return LocationCreationResult(
            id: id,
            name: preferredName,
            locationDir: locDir,
            mapOriginalURL: originalURL,
            mapDisplayURL: displayURL,
            thumbnailURL: thumbURL,
            displaySize: displayImage.size
        )
    }

    // MARK: - Helpers

    private static func writeAtomic(data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw LocationImportError.writeFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Migration
    
    /// Migrate existing location.json files to include new metadata fields
    /// - Parameter locationID: The location to migrate
    /// - Returns: True if migration was needed and successful, false if already up-to-date
    @discardableResult
    static func migrateLocationMetadata(locationID: String) -> Bool {
        let ctx = PersistenceContext.shared
        let locationDir = ctx.docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
        let stubURL = locationDir.appendingPathComponent("location.json")
        
        guard FileManager.default.fileExists(atPath: stubURL.path) else {
            print("⚠️ No location.json found for '\(locationID)', skipping migration")
            return false
        }
        
        // Read existing stub
        guard let data = try? Data(contentsOf: stubURL),
              var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to read location.json for '\(locationID)'")
            return false
        }
        
        var needsMigration = false
        
        // Add originalID if missing
        if dict["originalID"] == nil {
            dict["originalID"] = UUID().uuidString
            needsMigration = true
            print("   📝 Adding originalID for '\(locationID)'")
        }
        
        // Add createdBy if missing
        if dict["createdBy"] == nil {
            dict["createdBy"] = AppSettings.authorName
            needsMigration = true
            print("   📝 Adding createdBy for '\(locationID)'")
        }
        
        // Add lastModifiedBy if missing
        if dict["lastModifiedBy"] == nil {
            dict["lastModifiedBy"] = AppSettings.authorName
            needsMigration = true
            print("   📝 Adding lastModifiedBy for '\(locationID)'")
        }
        
        // Update beaconCount from dots.json (beacons placed on map)
        let dotsURL = locationDir.appendingPathComponent("dots.json")
        print("   🔍 Checking dots.json at: \(dotsURL.path)")

        if FileManager.default.fileExists(atPath: dotsURL.path) {
            print("   ✓ dots.json exists")
            
            if let dotsData = try? Data(contentsOf: dotsURL) {
                print("   ✓ Read \(dotsData.count) bytes from dots.json")
                
                // dots.json is an ARRAY of dot objects, not a dictionary
                if let dotsArray = try? JSONSerialization.jsonObject(with: dotsData) as? [[String: Any]] {
                    let currentCount = dict["beaconCount"] as? Int ?? -1
                    if currentCount != dotsArray.count {
                        dict["beaconCount"] = dotsArray.count
                        needsMigration = true
                        print("   📝 Updating beaconCount (\(currentCount) → \(dotsArray.count)) for '\(locationID)'")
                    }
                } else {
                    print("   ❌ Failed to parse dots.json as array")
                }
            } else {
                print("   ❌ Failed to read file data")
            }
        } else {
            print("   ❌ dots.json does NOT exist")
            
            if dict["beaconCount"] == nil {
                dict["beaconCount"] = 0
                needsMigration = true
                print("   📝 Setting beaconCount to 0 (no dots.json) for '\(locationID)'")
            }
        }
        
        // Add sessionCount if missing
        if dict["sessionCount"] == nil {
            let key = "locations.\(locationID).MapPoints_v1"
            if let mapPointsData = UserDefaults.standard.data(forKey: key),
               let jsonArray = try? JSONSerialization.jsonObject(with: mapPointsData) as? [[String: Any]] {
                // Count total sessions across all map points
                let totalSessions = jsonArray.reduce(0) { count, point in
                    if let sessions = point["sessions"] as? [[String: Any]] {
                        return count + sessions.count
                    }
                    return count
                }
                dict["sessionCount"] = totalSessions
                needsMigration = true
                print("   📝 Adding sessionCount (\(totalSessions)) for '\(locationID)'")
            } else {
                dict["sessionCount"] = 0
                needsMigration = true
            }
        }
        
        // Write back if changes were made
        if needsMigration {
            if let updatedData = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]) {
                try? updatedData.write(to: stubURL, options: .atomic)
                print("✅ Migrated metadata for '\(locationID)'")
                return true
            }
        } else {
            print("✅ Location '\(locationID)' already has all metadata fields")
            return false
        }
        
        return false
    }
}

// MARK: - Small extensions

private extension UIImage {
    /// Fix orientation so width/height and pixel data line up.
    func normalized() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }

    /// Downscale preserving aspect ratio to a max long-edge.
    func downscaled(longEdge: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        let maxEdge = max(w, h)
        guard maxEdge > longEdge, longEdge > 0 else { return self }
        let scaleFactor = longEdge / maxEdge
        let target = CGSize(width: w * scaleFactor, height: h * scaleFactor)
        UIGraphicsBeginImageContextWithOptions(target, false, 1.0) // keep 1.0 so pixels ~points for map coords
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: target))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

private extension Optional where Wrapped == String {
    /// If the optional string is nil or empty (after trimming), return nil; else the trimmed value.
    var nilIfEmpty: String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        return s.isEmpty ? nil : s
    }
}

private extension String {
    /// Return nil if (after trimming) the string is empty.
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
    
    func safeLowercasedImageExt() -> String {
        let lower = self.lowercased()
        switch lower {
        case "jpeg": return "jpg"
        case "png", "jpg", "heic", "heif", "tiff", "gif": return lower
        default: return "jpg"
        }
    }
}

// MARK: - Last Opened Location Helper

enum LastOpenedLocation {
    private static let key = "locations.lastOpened.v1"
    static func get() -> String? { UserDefaults.standard.string(forKey: key) }
    static func set(_ id: String) { UserDefaults.standard.set(id, forKey: key) }
}

// MARK: - Location Migration Utilities

enum LocationMigration {
    static let flagKey = "migration.defaultToHome.v1.done"

    static func runIfNeeded() {
        let ud = UserDefaults.standard
        guard ud.bool(forKey: flagKey) == false else { return }

        let oldPrefix = "loc.default."
        let newPrefix = "loc.home."

        // 1) Migrate UserDefaults keys
        for (key, value) in ud.dictionaryRepresentation() {
            guard key.hasPrefix(oldPrefix) else { continue }
            let newKey = newPrefix + key.dropFirst(oldPrefix.count)
            ud.set(value, forKey: String(newKey))
        }

        // 2) Update last-opened location
        if ud.string(forKey: "locations.lastOpened.v1") == "default" {
            ud.set("home", forKey: "locations.lastOpened.v1")
        }

        // 3) Rename location directory if it exists
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("locations", isDirectory: true)
        let oldDir = root.appendingPathComponent("default", isDirectory: true)
        let newDir = root.appendingPathComponent("home", isDirectory: true)
        if fm.fileExists(atPath: oldDir.path), !fm.fileExists(atPath: newDir.path) {
            do {
                try fm.createDirectory(at: root, withIntermediateDirectories: true)
                try fm.moveItem(at: oldDir, to: newDir)
            } catch {
                print("⚠️ Could not rename default→home dir: \(error)")
            }
        }

        ud.set(true, forKey: flagKey)
        ud.synchronize()
        print("✅ Migration default→home complete")
    }
}
