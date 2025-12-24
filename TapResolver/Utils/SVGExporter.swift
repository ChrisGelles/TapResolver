//
//  SVGExporter.swift
//  TapResolver
//
//  SVG export utilities for diagnostic visualization
//

import Foundation
import UIKit

struct SVGExporter {
    
    /// Generates SVG showing AR session markers at their pixel positions
    static func generateARSessionSVG(
        sessionMarkers: [(mapPointID: UUID, pixelPosition: CGPoint)],
        mapWidth: Int,
        mapHeight: Int,
        sessionID: UUID
    ) -> String {
        let sessionShort = String(sessionID.uuidString.prefix(8))
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" 
             viewBox="0 0 \(mapWidth) \(mapHeight)"
             width="\(mapWidth)" height="\(mapHeight)">
        <title>AR Session \(sessionShort)</title>
        
        <g id="SessionMarkers" fill="blue" fill-opacity="0.6">
        """
        
        for marker in sessionMarkers {
            let shortID = String(marker.mapPointID.uuidString.prefix(8))
            svg += """
            
            <circle cx="\(String(format: "%.1f", marker.pixelPosition.x))" 
                    cy="\(String(format: "%.1f", marker.pixelPosition.y))" 
                    r="12">
              <title>\(shortID)</title>
            </circle>
            """
        }
        
        svg += """
        
        </g>
        </svg>
        """
        
        return svg
    }
    
    /// Generates SVG showing MapPoints at their stored pixel positions
    static func generateMapPointsSVG(
        mapPoints: [(id: UUID, position: CGPoint, isLocked: Bool, hasCanonical: Bool)],
        mapWidth: Int,
        mapHeight: Int,
        locationName: String
    ) -> String {
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" 
             viewBox="0 0 \(mapWidth) \(mapHeight)"
             width="\(mapWidth)" height="\(mapHeight)">
        <title>MapPoints - \(locationName)</title>
        
        <g id="MapPoints">
        """
        
        for point in mapPoints {
            let shortID = String(point.id.uuidString.prefix(8))
            let fillColor: String
            if point.isLocked {
                fillColor = "#34C759"  // green
            } else if point.hasCanonical {
                fillColor = "#007AFF"  // blue
            } else {
                fillColor = "#FF9500"  // orange
            }
            
            svg += """
            
            <circle cx="\(String(format: "%.1f", point.position.x))" 
                    cy="\(String(format: "%.1f", point.position.y))" 
                    r="8"
                    fill="\(fillColor)" fill-opacity="0.8">
              <title>\(shortID)</title>
            </circle>
            """
        }
        
        svg += """
        
        </g>
        </svg>
        """
        
        return svg
    }
}
