//
//  ZoneSVGParser.swift
//  TapResolver
//
//  XMLParser delegate for extracting zone groups and zones from SVG files.
//

import Foundation
import CoreGraphics

/// Raw zone data extracted from SVG (before MapPoint resolution)
public struct RawZone {
    public let id: String           // From polygon id attribute (e.g., "Dunk Theater")
    public let displayName: String  // Same as id
    public let corners: [CGPoint]   // Raw pixel coordinates from points attribute
    public let groupID: String?     // Parent group ID (e.g., "evolvingLife-zones")
    public let cssClass: String?    // CSS class for color lookup
}

/// Raw zone group data extracted from SVG
public struct RawZoneGroup {
    public let id: String           // From g id attribute (e.g., "evolvingLife-zones")
    public let displayName: String  // Derived from ID
    public let colorHex: String     // From CSS or default
    public var zoneIDs: [String]    // Zone IDs in this group (populated during parsing)
}

/// Result of parsing an SVG file
public struct SVGParseResult {
    public let groups: [RawZoneGroup]
    public let zones: [RawZone]
    public let cssStyles: [String: String]  // class name → color hex
    public let errors: [String]
}

// MARK: - Deterministic Color Assignment

/// 12-color palette for zone groups (deterministic assignment via name hash)
private let zoneGroupColorPalette: [String] = [
    "#E63946",  // Red
    "#F4A261",  // Orange
    "#E9C46A",  // Yellow
    "#2A9D8F",  // Teal
    "#264653",  // Dark blue-green
    "#457B9D",  // Steel blue
    "#1D3557",  // Navy
    "#A8DADC",  // Light cyan
    "#6D597A",  // Purple
    "#B56576",  // Mauve
    "#355070",  // Slate blue
    "#83C5BE",  // Seafoam
]

/// Stable hash function (djb2) - consistent across app launches
private func stableHash(_ string: String) -> Int {
    var hash: UInt64 = 5381
    for char in string.utf8 {
        hash = ((hash << 5) &+ hash) &+ UInt64(char)  // hash * 33 + c
    }
    return Int(hash & 0x7FFFFFFF)  // Ensure positive
}

/// Get deterministic color for a zone group name
private func colorForGroupName(_ name: String) -> String {
    let hash = stableHash(name.lowercased())
    let index = hash % zoneGroupColorPalette.count
    return zoneGroupColorPalette[index]
}

/// XMLParser delegate for extracting zones from SVG
public class ZoneSVGParser: NSObject, XMLParserDelegate {
    
    // MARK: - Parse State
    
    private var groups: [String: RawZoneGroup] = [:]  // id → group
    private var zones: [RawZone] = []
    private var cssStyles: [String: String] = [:]     // class → color (legacy, kept for compatibility)
    private var errors: [String] = []
    
    // Hierarchy tracking for zone detection
    private var insideZonesGroup: Bool = false        // True when inside <g id="zones">
    private var currentZoneGroupID: String?           // Set when inside a direct child of zones
    private var zoneGroupDepth: Int = 0               // 0 = not in zone group, 1 = in zone group, 2+ = nested
    
    // Auto-ID generation for unnamed polygons
    private var unnamedCountPerGroup: [String: Int] = [:]  // groupID → count of unnamed polygons
    
    // Legacy state (kept for element tracking)
    private var elementStack: [String] = []           // Stack of element names
    
    // Style parsing state
    private var inStyleElement = false
    private var styleContent = ""
    
    // MARK: - Public Interface
    
    /// Parse an SVG file and extract zone data
    /// - Parameter data: Raw SVG file data
    /// - Returns: Parse result with groups, zones, and any errors
    public func parse(data: Data) -> SVGParseResult {
        // Reset state
        groups = [:]
        zones = []
        cssStyles = [:]
        errors = []
        elementStack = []
        insideZonesGroup = false
        currentZoneGroupID = nil
        zoneGroupDepth = 0
        unnamedCountPerGroup = [:]
        inStyleElement = false
        styleContent = ""
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        // Convert groups dictionary to array
        var groupsArray = Array(groups.values)
        
        // Update group colors from CSS (must happen AFTER groups are parsed)
        for i in groupsArray.indices {
            let groupID = groupsArray[i].id
            
            // Strategy 1: Try direct match from group ID
            let baseName = groupID.replacingOccurrences(of: "-zones", with: "")
            if let color = cssStyles[baseName] ?? cssStyles[baseName.lowercased()] {
                groupsArray[i] = RawZoneGroup(
                    id: groupsArray[i].id,
                    displayName: groupsArray[i].displayName,
                    colorHex: color,
                    zoneIDs: groupsArray[i].zoneIDs
                )
                print("🎨 [ZoneSVGParser] Group '\(groupID)' color from group name: \(color)")
                continue
            }
            
            // Strategy 2: Use cssClass from first zone in this group
            if let firstZone = zones.first(where: { $0.groupID == groupID }),
               let cssClass = firstZone.cssClass,
               let color = cssStyles[cssClass] ?? cssStyles[cssClass.lowercased()] {
                groupsArray[i] = RawZoneGroup(
                    id: groupsArray[i].id,
                    displayName: groupsArray[i].displayName,
                    colorHex: color,
                    zoneIDs: groupsArray[i].zoneIDs
                )
                print("🎨 [ZoneSVGParser] Group '\(groupID)' color from zone class '\(cssClass)': \(color)")
                continue
            }
            
            print("⚠️ [ZoneSVGParser] Group '\(groupID)' no CSS match found")
        }
        
        // Populate zone IDs in each group
        for i in groupsArray.indices {
            let groupID = groupsArray[i].id
            groupsArray[i].zoneIDs = zones.filter { $0.groupID == groupID }.map { $0.id }
        }
        
        print("📄 [ZoneSVGParser] Parsed \(groupsArray.count) groups, \(zones.count) zones")
        
        return SVGParseResult(
            groups: groupsArray,
            zones: zones,
            cssStyles: cssStyles,
            errors: errors
        )
    }
    
    // MARK: - XMLParserDelegate
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?,
                       attributes attributeDict: [String: String]) {
        
        // Skip elementStack management for "g" elements - handleGroupStart manages it with IDs
        if elementName.lowercased() != "g" {
            elementStack.append(elementName)
        }
        
        switch elementName.lowercased() {
        case "g":
            handleGroupStart(attributes: attributeDict)
            
        case "polygon":
            handlePolygon(attributes: attributeDict)
            
        case "style":
            inStyleElement = true
            styleContent = ""
            
        default:
            break
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                       namespaceURI: String?, qualifiedName qName: String?) {
        
        switch elementName.lowercased() {
        case "g":
            handleGroupEnd()
            
        case "style":
            inStyleElement = false
            parseCSS(styleContent)
            
        default:
            break
        }
        
        // Skip elementStack management for "g" elements - handleGroupEnd manages it
        if elementName.lowercased() != "g" && !elementStack.isEmpty {
            elementStack.removeLast()
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inStyleElement {
            styleContent += string
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        errors.append("XML parse error: \(parseError.localizedDescription)")
    }
    
    // MARK: - Element Handlers
    
    private func handleGroupStart(attributes: [String: String]) {
        let id = attributes["id"]
        elementStack.append(id ?? "")
        
        // Check if entering the top-level "zones" container (case-insensitive)
        if id?.lowercased() == "zones" {
            insideZonesGroup = true
            print("📂 [ZoneSVGParser] Entered zones container")
            return
        }
        
        // Check if this is a zone group (direct child of "zones")
        if insideZonesGroup && zoneGroupDepth == 0, let groupID = id {
            currentZoneGroupID = groupID
            zoneGroupDepth = 1
            
            // Derive display name: strip "-zones" suffix if present, otherwise use as-is
            let displayName: String
            if groupID.hasSuffix("-zones") {
                displayName = String(groupID.dropLast(6))
            } else {
                displayName = groupID
            }
            
            // Get deterministic color from group name
            let colorHex = colorForGroupName(displayName)
            
            let group = RawZoneGroup(
                id: groupID,
                displayName: displayName,
                colorHex: colorHex,
                zoneIDs: []
            )
            groups[groupID] = group
            print("📁 [ZoneSVGParser] Found zone group: '\(groupID)' → display: '\(displayName)', color: \(colorHex)")
            return
        }
        
        // Track nesting depth within a zone group
        if zoneGroupDepth >= 1 {
            zoneGroupDepth += 1
            if zoneGroupDepth == 2 {
                print("⚠️ [ZoneSVGParser] Warning: Nested group detected inside '\(currentZoneGroupID ?? "unknown")' - content will be skipped")
            }
        }
    }
    
    private func handleGroupEnd() {
        guard !elementStack.isEmpty else { return }
        let closedID = elementStack.removeLast()
        
        // Exiting the top-level "zones" container (case-insensitive)
        if closedID.lowercased() == "zones" {
            insideZonesGroup = false
            print("📂 [ZoneSVGParser] Exited zones container")
            return
        }
        
        // Exiting a zone group or nested group
        if zoneGroupDepth > 0 {
            zoneGroupDepth -= 1
            if zoneGroupDepth == 0 {
                print("📁 [ZoneSVGParser] Exited zone group: '\(currentZoneGroupID ?? "unknown")'")
                currentZoneGroupID = nil
            }
        }
    }
    
    private func handlePolygon(attributes: [String: String]) {
        // Only process polygons inside the zones container, at zone group level
        guard insideZonesGroup else {
            return  // Not inside <g id="zones"> - ignore (e.g., triangles layer)
        }
        
        guard zoneGroupDepth == 1 else {
            return  // Not a direct child of a zone group - ignore
        }
        
        guard let pointsStr = attributes["points"] else {
            return
        }
        
        // Generate ID if not provided
        let id: String
        if let providedID = attributes["id"], !providedID.isEmpty {
            id = providedID
        } else {
            let groupKey = currentZoneGroupID ?? "ungrouped"
            let count = (unnamedCountPerGroup[groupKey] ?? 0) + 1
            unnamedCountPerGroup[groupKey] = count
            id = String(format: "%@-%02d", groupKey, count)
            print("🏷️ [ZoneSVGParser] Generated ID '\(id)' for unnamed polygon")
        }
        
        // Parse points
        var corners = parsePoints(pointsStr)
        
        // SVG polygons often close by repeating the first point — strip it
        if corners.count > 1 {
            let first = corners.first!
            let last = corners.last!
            let epsilon: CGFloat = 0.1  // tolerance for floating point comparison
            if abs(first.x - last.x) < epsilon && abs(first.y - last.y) < epsilon {
                corners.removeLast()
            }
        }
        
        guard corners.count >= 3 else {
            errors.append("Polygon '\(id)' has fewer than 3 points")
            return
        }
        
        // Validate 4 corners for zones (bilinear interpolation requirement)
        if corners.count != 4 {
            errors.append("Zone '\(id)' has \(corners.count) corners, expected 4")
            // Still include it but flag the error
        }
        
        let cssClass = attributes["class"]
        
        let zone = RawZone(
            id: id,
            displayName: id,
            corners: corners,
            groupID: currentZoneGroupID,
            cssClass: cssClass
        )
        
        zones.append(zone)
        print("🔷 [ZoneSVGParser] Found zone: '\(id)' with \(corners.count) corners in group: \(currentZoneGroupID ?? "none")")
    }
    
    // MARK: - Parsing Helpers
    
    /// Parse SVG points attribute: "x1,y1 x2,y2 x3,y3" or "x1 y1 x2 y2 x3 y3"
    private func parsePoints(_ pointsStr: String) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Normalize: replace commas with spaces, collapse multiple spaces
        let normalized = pointsStr
            .replacingOccurrences(of: ",", with: " ")
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        // Parse pairs of numbers
        var i = 0
        while i + 1 < normalized.count {
            if let x = Double(normalized[i]),
               let y = Double(normalized[i + 1]) {
                points.append(CGPoint(x: x, y: y))
            }
            i += 2
        }
        
        return points
    }
    
    /// Parse CSS from style element to extract fill colors
    private func parseCSS(_ css: String) {
        // Pattern: .className { fill: #hexcolor; ... }
        // Also handle: .className{fill:#hexcolor}
        
        let pattern = #"\.([a-zA-Z0-9_-]+)\s*\{[^}]*fill:\s*(#[a-fA-F0-9]{6}|#[a-fA-F0-9]{3}|[a-zA-Z]+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return
        }
        
        let range = NSRange(css.startIndex..<css.endIndex, in: css)
        let matches = regex.matches(in: css, options: [], range: range)
        
        for match in matches {
            guard let classRange = Range(match.range(at: 1), in: css),
                  let colorRange = Range(match.range(at: 2), in: css) else {
                continue
            }
            
            let className = String(css[classRange])
            var color = String(css[colorRange])
            
            // Expand 3-digit hex to 6-digit
            if color.count == 4 && color.hasPrefix("#") {
                let r = color[color.index(color.startIndex, offsetBy: 1)]
                let g = color[color.index(color.startIndex, offsetBy: 2)]
                let b = color[color.index(color.startIndex, offsetBy: 3)]
                color = "#\(r)\(r)\(g)\(g)\(b)\(b)"
            }
            
            // Convert named colors to hex
            if !color.hasPrefix("#") {
                let namedColors: [String: String] = [
                    "blue": "#0000FF",
                    "red": "#FF0000",
                    "green": "#008000",
                    "yellow": "#FFFF00",
                    "orange": "#FFA500",
                    "purple": "#800080",
                    "cyan": "#00FFFF",
                    "magenta": "#FF00FF",
                    "white": "#FFFFFF",
                    "black": "#000000",
                    "gray": "#808080",
                    "grey": "#808080"
                ]
                if let hex = namedColors[color.lowercased()] {
                    print("🎨 [ZoneSVGParser] Converted named color '\(color)' → \(hex)")
                    color = hex
                } else {
                    print("⚠️ [ZoneSVGParser] Unknown named color '\(color)', skipping")
                    continue
                }
            }
            
            cssStyles[className] = color.uppercased()
            print("🎨 [ZoneSVGParser] CSS style: .\(className) → \(color)")
        }
    }
}
