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

/// XMLParser delegate for extracting zones from SVG
public class ZoneSVGParser: NSObject, XMLParserDelegate {
    
    // MARK: - Parse State
    
    private var groups: [String: RawZoneGroup] = [:]  // id → group
    private var zones: [RawZone] = []
    private var cssStyles: [String: String] = [:]     // class → color
    private var errors: [String] = []
    
    // Element stack for tracking hierarchy
    private var elementStack: [String] = []  // Stack of element names
    private var groupStack: [String] = []    // Stack of group IDs (only -zones groups)
    
    // Current element state
    private var currentGroupID: String? {
        groupStack.last
    }
    
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
        groupStack = []
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
        
        elementStack.append(elementName)
        
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
        
        if !elementStack.isEmpty {
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
        guard let id = attributes["id"] else { return }
        
        // Only track groups that end with "-zones"
        if id.hasSuffix("-zones") {
            groupStack.append(id)
            
            // Create group if not exists
            if groups[id] == nil {
                let displayName = id
                    .replacingOccurrences(of: "-zones", with: "")
                    .asDisplayName
                
                groups[id] = RawZoneGroup(
                    id: id,
                    displayName: displayName,
                    colorHex: "#808080",  // Default, will be updated from CSS
                    zoneIDs: []
                )
                
                print("📁 [ZoneSVGParser] Found group: \(id) → '\(displayName)'")
            }
        }
    }
    
    private func handleGroupEnd() {
        // Pop from group stack if we're leaving a -zones group
        if let currentID = groupStack.last,
           currentID.hasSuffix("-zones") {
            groupStack.removeLast()
        }
    }
    
    private func handlePolygon(attributes: [String: String]) {
        guard let id = attributes["id"],
              let pointsStr = attributes["points"] else {
            return
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
            groupID: currentGroupID,
            cssClass: cssClass
        )
        
        zones.append(zone)
        print("🔷 [ZoneSVGParser] Found zone: '\(id)' with \(corners.count) corners in group: \(currentGroupID ?? "none")")
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
            if color.count == 4 {
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
