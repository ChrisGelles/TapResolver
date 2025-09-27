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

/// Minimal model written to `location.json` inside each location folder.
/// This is intentionally small; we can extend it later without breaking older files.
struct LocationStub: Codable {
    let id: String
    var name: String
    let createdISO: String
    var updatedISO: String
    // Relative (to the location folder) asset paths
    let mapOriginalRel: String
    let mapDisplayRel: String
    let thumbnailRel: String
    // Pixel dimensions of the display image (what the app should render)
    let displayWidth: Int
    let displayHeight: Int
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

/// Utilities for creating and enumerating locations on disk.
/// This does NOT change the active PersistenceContext location; it simply creates new ones.
enum LocationImportUtils {

    // MARK: - Public API

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
        return try createLocation(fromImage: srcImage, preferredName: baseName, originalData: data, originalExt: fileURL.pathExtension, maxDisplayDimension: maxDisplayDimension)
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
        return try createLocation(fromImage: image.normalized(),
                                  preferredName: baseName,
                                  originalData: data,
                                  originalExt: ext,
                                  maxDisplayDimension: maxDisplayDimension)
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

        // Downscale for display
        let displayImage = image.downscaled(longEdge: maxDisplayDimension)
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
            createdISO: now,
            updatedISO: now,
            mapOriginalRel: "assets/\(originalName)",
            mapDisplayRel: "assets/\(displayName)",
            thumbnailRel: "assets/\(thumbName)",
            displayWidth: Int(displayImage.size.width.rounded()),
            displayHeight: Int(displayImage.size.height.rounded())
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