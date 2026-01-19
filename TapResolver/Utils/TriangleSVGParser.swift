//
//  TriangleSVGParser.swift
//  TapResolver
//
//  Parses triangle polygons from SVG files.
//

import Foundation
import CoreGraphics

// MARK: - Parse Result Types

struct RawTriangle {
    let id: String?          // Polygon ID from SVG (e.g., "tri-E325D867")
    let vertices: [CGPoint]  // Exactly 3 points
}

struct TriangleSVGParseResult {
    let triangles: [RawTriangle]
    let errors: [String]
    let warnings: [String]
    let manifest: SVGManifest?  // Extracted manifest (if present)
}

// MARK: - Parser

class TriangleSVGParser: NSObject, XMLParserDelegate {
    
    private var triangles: [RawTriangle] = []
    private var errors: [String] = []
    private var warnings: [String] = []
    
    // Track if we're inside the triangles layer
    private var insideTrianglesLayer: Bool = false
    private var groupDepth: Int = 0
    
    // MARK: - Public API
    
    func parse(data: Data) -> TriangleSVGParseResult {
        // Reset state
        triangles = []
        errors = []
        warnings = []
        insideTrianglesLayer = false
        groupDepth = 0
        
        print("📐 [TriangleSVGParser] Starting parse, data size: \(data.count) bytes")
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        print("📐 [TriangleSVGParser] Parse complete: \(triangles.count) triangles, \(errors.count) errors, \(warnings.count) warnings")
        
        if triangles.isEmpty && errors.isEmpty {
            errors.append("No triangles found in SVG. Ensure polygons are inside <g id=\"triangles\"> layer.")
            print("📐 [TriangleSVGParser] ❌ No triangles found - was triangles layer detected? Check logs above for '✅ FOUND triangles layer'")
        }
        
        // Extract manifest from SVG (if present)
        let manifest: SVGManifest?
        if let svgString = String(data: data, encoding: .utf8) {
            manifest = SVGManifest.extract(from: svgString)
        } else {
            manifest = nil
        }
        
        return TriangleSVGParseResult(
            triangles: triangles,
            errors: errors,
            warnings: warnings,
            manifest: manifest
        )
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String]) {
        
        // Diagnostic: log all elements with id attribute
        if let id = attributes["id"] {
            print("📐 [TriangleSVGParser] Element: <\(elementName)> id=\"\(id)\"")
        }
        
        if elementName == "g" {
            // Check if this is the triangles layer
            if let id = attributes["id"] {
                // Check for exact match and common variations
                let isTrianglesLayer = (id == "triangles" || id == "Triangles" || id.lowercased() == "triangles")
                if isTrianglesLayer {
                    print("📐 [TriangleSVGParser] ✅ FOUND triangles layer: id=\"\(id)\"")
                    insideTrianglesLayer = true
                    groupDepth = 0
                }
            } else if insideTrianglesLayer {
                groupDepth += 1
            }
        }
        
        // Parse polygon elements inside triangles layer
        if elementName == "polygon" && insideTrianglesLayer {
            parsePolygon(attributes: attributes)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        
        if elementName == "g" && insideTrianglesLayer {
            if groupDepth == 0 {
                insideTrianglesLayer = false
            } else {
                groupDepth -= 1
            }
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        errors.append("XML parse error: \(parseError.localizedDescription)")
    }
    
    // MARK: - Polygon Parsing
    
    private func parsePolygon(attributes: [String: String]) {
        print("📐 [TriangleSVGParser] Parsing polygon, attributes: \(attributes.keys.sorted())")
        
        guard let pointsString = attributes["points"] else {
            print("📐 [TriangleSVGParser] ⚠️ Polygon missing 'points' attribute")
            warnings.append("Polygon missing points attribute, skipped")
            return
        }
        
        var vertices = parsePoints(pointsString)
        print("📐 [TriangleSVGParser] Parsed \(vertices.count) vertices from points string (length: \(pointsString.count))")

        // Handle closed polygons: Illustrator repeats the first point at the end
        if vertices.count == 4 {
            let first = vertices.first!
            let last = vertices.last!
            let distance = hypot(first.x - last.x, first.y - last.y)
            if distance < 1.0 {  // Within 1 pixel = same point
                print("📐 [TriangleSVGParser] Detected closed polygon (first==last), removing duplicate vertex")
                vertices.removeLast()
            }
        }

        if vertices.count != 3 {
            warnings.append("Polygon has \(vertices.count) vertices (need exactly 3), skipped")
            return
        }
        
        let polygonID = attributes["id"]
        triangles.append(RawTriangle(id: polygonID, vertices: vertices))
    }
    
    /// Parse SVG points attribute into CGPoint array
    /// Handles both "x1,y1 x2,y2" and "x1 y1 x2 y2" formats
    private func parsePoints(_ pointsString: String) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Normalize: replace commas with spaces, then split on whitespace
        let normalized = pointsString.replacingOccurrences(of: ",", with: " ")
        let components = normalized.split(whereSeparator: { $0.isWhitespace })
            .map { String($0) }
            .compactMap { Double($0) }
        
        // Pair up as x,y coordinates
        for i in stride(from: 0, to: components.count - 1, by: 2) {
            let x = components[i]
            let y = components[i + 1]
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
}
