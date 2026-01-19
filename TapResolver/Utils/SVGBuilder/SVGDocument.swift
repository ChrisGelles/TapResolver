//
//  SVGDocument.swift
//  TapResolver
//
//  Core SVG document builder with layer management.
//

import Foundation
import UIKit

/// A builder for creating layered SVG documents
class SVGDocument {
    
    // MARK: - Properties
    
    let width: CGFloat
    let height: CGFloat
    private var layers: [(id: String, content: String)] = []
    private var backgroundImageData: String?  // Base64 PNG
    private var styles: [String: String] = [:]  // className -> CSS properties
    private var documentID: String?  // Root SVG element ID
    
    // MARK: - Initialization
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    // MARK: - Style Registry
    
    /// Register a CSS style class
    /// - Parameters:
    ///   - className: The class name (without leading dot)
    ///   - css: The CSS properties (e.g., "fill: #0064ff;")
    func registerStyle(className: String, css: String) {
        styles[className] = css
    }
    
    /// Set the document ID (appears on root <svg> element)
    func setDocumentID(_ id: String) {
        documentID = id
    }
    
    /// Convert rgba() to hex color for CSS
    static func rgbaToHex(_ r: Int, _ g: Int, _ b: Int, _ a: Double = 1.0) -> String {
        if a < 1.0 {
            // Use rgba for transparency
            return "rgba(\(r), \(g), \(b), \(a))"
        } else {
            // Use hex for solid colors
            return String(format: "#%02x%02x%02x", r, g, b)
        }
    }
    
    // MARK: - Background Image
    
    /// Embed a UIImage as the background layer
    func setBackgroundImage(_ image: UIImage) {
        guard let pngData = image.pngData() else {
            print("⚠️ [SVGDocument] Failed to convert image to PNG")
            return
        }
        backgroundImageData = pngData.base64EncodedString()
        print("📐 [SVGDocument] Embedded background image: \(pngData.count) bytes")
    }
    
    // MARK: - Layer Management
    
    /// Add a layer with SVG content
    func addLayer(id: String, content: String) {
        layers.append((id: id, content: content))
    }
    
    /// Add a layer with circle elements using CSS class
    /// - Parameters:
    ///   - id: Layer ID
    ///   - circles: Array of circle data (cx, cy, r, elementID)
    ///   - styleClass: CSS class name for fill color
    func addCircleLayer(id: String, circles: [(cx: CGFloat, cy: CGFloat, r: CGFloat, elementID: String?)], styleClass: String) {
        var content = ""
        for circle in circles {
            let idAttr = circle.elementID.map { "id=\"\($0)\" " } ?? ""
            content += "<circle \(idAttr)class=\"\(styleClass)\" cx=\"\(String(format: "%.1f", circle.cx))\" cy=\"\(String(format: "%.1f", circle.cy))\" r=\"\(String(format: "%.1f", circle.r))\"/>\n"
        }
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with line elements
    func addLineLayer(id: String, lines: [(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, stroke: String, strokeWidth: CGFloat)]) {
        var content = ""
        for line in lines {
            content += "<line x1=\"\(String(format: "%.1f", line.x1))\" y1=\"\(String(format: "%.1f", line.y1))\" x2=\"\(String(format: "%.1f", line.x2))\" y2=\"\(String(format: "%.1f", line.y2))\" stroke=\"\(line.stroke)\" stroke-width=\"\(String(format: "%.1f", line.strokeWidth))\"/>\n"
        }
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with a polygon (closed path)
    func addPolygonLayer(id: String, points: [CGPoint], stroke: String, strokeWidth: CGFloat, fill: String = "none", strokeDasharray: String? = nil) {
        guard points.count >= 3 else { return }
        
        let pointsString = points.map { "\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.y))" }.joined(separator: " ")
        let dashAttr = strokeDasharray.map { " stroke-dasharray=\"\($0)\"" } ?? ""
        
        let content = "<polygon points=\"\(pointsString)\" stroke=\"\(stroke)\" stroke-width=\"\(String(format: "%.1f", strokeWidth))\" fill=\"\(fill)\"\(dashAttr)/>\n"
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with path elements (for triangle mesh edges)
    func addPathLayer(id: String, paths: [(d: String, stroke: String, strokeWidth: CGFloat, fill: String)]) {
        var content = ""
        for path in paths {
            content += "<path d=\"\(path.d)\" stroke=\"\(path.stroke)\" stroke-width=\"\(String(format: "%.1f", path.strokeWidth))\" fill=\"\(path.fill)\"/>\n"
        }
        addLayer(id: id, content: content)
    }
    
    // MARK: - Manifest Layer
    
    /// Add the export manifest as a hidden text layer
    /// - Parameter jsonString: Pretty-printed JSON manifest content
    func addManifestLayer(_ jsonString: String) {
        // Register hidden style for data layer
        registerStyle(className: "dataClass", css: "display: none;")
        
        // Escape JSON for XML text content
        let escapedJSON = jsonString
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
        
        // Build single text element with tspan lines (Illustrator-compatible format)
        let lines = escapedJSON.components(separatedBy: "\n")
        let lineHeight: Double = 14.4
        
        var tspans: [String] = []
        for (index, line) in lines.enumerated() {
            let yOffset = Double(index) * lineHeight
            tspans.append("<tspan x=\"0\" y=\"\(String(format: "%.1f", yOffset))\">\(line)</tspan>")
        }
        
        let textContent = "<text class=\"dataClass\" transform=\"translate(10 20)\">" + tspans.joined() + "</text>"
        
        addLayer(id: "data", content: textContent)
        print("📋 [SVGDocument] Added manifest layer (\(lines.count) lines)")
    }
    
    // MARK: - SVG Generation
    
    /// Generate the complete SVG string
    func generateSVG() -> String {
        let idAttr = documentID.map { "id=\"\($0)\" " } ?? ""
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg \(idAttr)viewBox="0 0 \(Int(width)) \(Int(height))"
             xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink">
        
        """
        
        // Defs section with styles (if any styles registered)
        if !styles.isEmpty {
            svg += "  <defs>\n"
            svg += "    <style>\n"
            for (className, css) in styles.sorted(by: { $0.key < $1.key }) {
                svg += "      .\(className) {\n"
                svg += "        \(css)\n"
                svg += "      }\n"
            }
            svg += "    </style>\n"
            svg += "  </defs>\n\n"
        }
        
        // Background image (if embedded)
        if let imageData = backgroundImageData {
            svg += "  <image id=\"map-background\" width=\"\(Int(width))\" height=\"\(Int(height))\" xlink:href=\"data:image/png;base64,\(imageData)\"/>\n\n"
        }
        
        // Layers
        for layer in layers {
            svg += "  <g id=\"\(layer.id)\">\n"
            for line in layer.content.split(separator: "\n") {
                svg += "    \(line)\n"
            }
            svg += "  </g>\n\n"
        }
        
        svg += "</svg>\n"
        return svg
    }
    
    // MARK: - File Output
    
    /// Write SVG to a temporary file and return the URL
    func writeToTempFile(filename: String) -> URL? {
        let svgString = generateSVG()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try svgString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📁 [SVGDocument] Wrote SVG to: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ [SVGDocument] Failed to write SVG: \(error)")
            return nil
        }
    }
}
