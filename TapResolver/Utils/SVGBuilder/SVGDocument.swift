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
    
    // MARK: - Initialization
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
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
    
    /// Add a layer with circle elements
    func addCircleLayer(id: String, circles: [(cx: CGFloat, cy: CGFloat, r: CGFloat, fill: String, title: String?)]) {
        var content = ""
        for circle in circles {
            let titleElement = circle.title.map { "<title>\($0)</title>" } ?? ""
            content += """
                <circle cx="\(String(format: "%.1f", circle.cx))" cy="\(String(format: "%.1f", circle.cy))" r="\(String(format: "%.1f", circle.r))" fill="\(circle.fill)">\(titleElement)</circle>\n
            """
        }
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with line elements
    func addLineLayer(id: String, lines: [(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, stroke: String, strokeWidth: CGFloat)]) {
        var content = ""
        for line in lines {
            content += """
                <line x1="\(String(format: "%.1f", line.x1))" y1="\(String(format: "%.1f", line.y1))" x2="\(String(format: "%.1f", line.x2))" y2="\(String(format: "%.1f", line.y2))" stroke="\(line.stroke)" stroke-width="\(String(format: "%.1f", line.strokeWidth))"/>\n
            """
        }
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with a polygon (closed path)
    func addPolygonLayer(id: String, points: [CGPoint], stroke: String, strokeWidth: CGFloat, fill: String = "none", strokeDasharray: String? = nil) {
        guard points.count >= 3 else { return }
        
        let pointsString = points.map { "\(String(format: "%.1f", $0.x)),\(String(format: "%.1f", $0.y))" }.joined(separator: " ")
        let dashAttr = strokeDasharray.map { " stroke-dasharray=\"\($0)\"" } ?? ""
        
        let content = """
            <polygon points="\(pointsString)" stroke="\(stroke)" stroke-width="\(String(format: "%.1f", strokeWidth))" fill="\(fill)"\(dashAttr)/>\n
        """
        addLayer(id: id, content: content)
    }
    
    /// Add a layer with path elements (for triangle mesh edges)
    func addPathLayer(id: String, paths: [(d: String, stroke: String, strokeWidth: CGFloat, fill: String)]) {
        var content = ""
        for path in paths {
            content += """
                <path d="\(path.d)" stroke="\(path.stroke)" stroke-width="\(String(format: "%.1f", path.strokeWidth))" fill="\(path.fill)"/>\n
            """
        }
        addLayer(id: id, content: content)
    }
    
    // MARK: - SVG Generation
    
    /// Generate the complete SVG string
    func generateSVG() -> String {
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg viewBox="0 0 \(Int(width)) \(Int(height))" 
             xmlns="http://www.w3.org/2000/svg"
             xmlns:xlink="http://www.w3.org/1999/xlink">
        
        """
        
        // Background image (if embedded)
        if let imageData = backgroundImageData {
            // Single-line format with width/height before href for better compatibility
            svg += "  <image id=\"map-background\" width=\"\(Int(width))\" height=\"\(Int(height))\" xlink:href=\"data:image/png;base64,\(imageData)\"/>\n\n"
        }
        
        // Layers
        for layer in layers {
            svg += """
              <g id="\(layer.id)">
            \(layer.content.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))
              </g>
            
            """
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

