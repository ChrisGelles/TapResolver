//
//  SVGIllustratorFormatter.swift
//  TapResolver
//
//  Post-processor that transforms SVG output to match Adobe Illustrator conventions.
//  This is a modular transformation applied after SVG generation.
//

import Foundation

/// Transforms SVG to match Adobe Illustrator's export conventions
struct SVGIllustratorFormatter {
    
    // MARK: - Public Interface
    
    /// Transform an SVG string to Illustrator-compatible format
    /// - Parameter svg: The original SVG string
    /// - Returns: Transformed SVG matching Illustrator conventions
    static func format(_ svg: String) -> String {
        var result = svg
        
        // Step 1: Add version attribute to SVG root
        result = addVersionAttribute(result)
        
        // Step 2: Transform CSS classes to st0, st1, etc. with deduplication
        result = transformCSSClasses(result)
        
        // Step 3: Convert points format and close polygons
        result = transformPolygonPoints(result)
        
        // Step 4: Format numbers (remove leading zeros, lowercase hex)
        result = formatNumbers(result)
        
        return result
    }
    
    // MARK: - SVG Root
    
    private static func addVersionAttribute(_ svg: String) -> String {
        // Add version="1.1" after the opening <svg tag if not present
        guard !svg.contains("version=") else { return svg }
        
        return svg.replacingOccurrences(
            of: "<svg ",
            with: "<svg version=\"1.1\" "
        )
    }
    
    // MARK: - CSS Transformation
    
    private static func transformCSSClasses(_ svg: String) -> String {
        // Extract the style block
        guard let styleStart = svg.range(of: "<style>"),
              let styleEnd = svg.range(of: "</style>") else {
            return svg
        }
        
        let styleContent = String(svg[styleStart.upperBound..<styleEnd.lowerBound])
        
        // Parse all CSS rules: className -> properties
        let cssRules = parseCSSRules(styleContent)
        guard !cssRules.isEmpty else { return svg }
        
        // Group classes by identical properties (for deduplication)
        // properties -> [classNames]
        var propertiesGroups: [String: [String]] = [:]
        for (className, properties) in cssRules {
            let normalized = normalizeProperties(properties)
            propertiesGroups[normalized, default: []].append(className)
        }
        
        // Assign st0, st1, etc. to each unique property set
        // Also build mapping: oldClassName -> stN
        var classMapping: [String: String] = [:]
        var stIndex = 0
        var newCSSBlocks: [String] = []
        var comments: [String] = []
        
        // Sort by first class name for consistent output
        let sortedGroups = propertiesGroups.sorted { 
            ($0.value.first ?? "") < ($1.value.first ?? "") 
        }
        
        for (properties, classNames) in sortedGroups {
            let stName = "st\(stIndex)"
            
            // Map all original class names to this st name
            for className in classNames {
                classMapping[className] = stName
            }
            
            // Add comment showing what semantic names map to this class
            if classNames.count == 1 {
                comments.append("      /* \(classNames[0]) */")
            } else {
                comments.append("      /* \(classNames.sorted().joined(separator: ", ")) */")
            }
            
            // Build the CSS rule
            let formattedProps = formatCSSProperties(properties)
            newCSSBlocks.append("      .\(stName) {\n\(formattedProps)\n      }")
            
            stIndex += 1
        }
        
        // Build new style block with comments
        var newStyleContent = "\n"
        for i in 0..<newCSSBlocks.count {
            newStyleContent += comments[i] + "\n"
            newStyleContent += newCSSBlocks[i] + "\n\n"
        }
        
        // Replace style block
        var result = svg
        let fullStyleRange = styleStart.lowerBound..<styleEnd.upperBound
        result.replaceSubrange(fullStyleRange, with: "<style>\(newStyleContent)    </style>")
        
        // Replace all class references in the document, but preserve dataClass
        for (oldClass, newClass) in classMapping {
            // Skip dataClass - preserve it for manifest layer
            if oldClass == "dataClass" {
                continue
            }
            result = result.replacingOccurrences(
                of: "class=\"\(oldClass)\"",
                with: "class=\"\(newClass)\""
            )
        }
        
        return result
    }
    
    /// Parse CSS rules from style content
    private static func parseCSSRules(_ css: String) -> [String: String] {
        var rules: [String: String] = [:]
        
        // Pattern: .className { properties }
        let pattern = #"\.([a-zA-Z0-9_-]+)\s*\{([^}]*)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return rules
        }
        
        let range = NSRange(css.startIndex..<css.endIndex, in: css)
        let matches = regex.matches(in: css, options: [], range: range)
        
        for match in matches {
            guard let classRange = Range(match.range(at: 1), in: css),
                  let propsRange = Range(match.range(at: 2), in: css) else {
                continue
            }
            
            let className = String(css[classRange])
            let properties = String(css[propsRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            rules[className] = properties
        }
        
        return rules
    }
    
    /// Normalize properties for comparison (sort, trim, lowercase)
    private static func normalizeProperties(_ props: String) -> String {
        let parts = props.split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
            .sorted()
        return parts.joined(separator: "; ")
    }
    
    /// Format CSS properties with Illustrator conventions
    private static func formatCSSProperties(_ props: String) -> String {
        let parts = props.split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var formatted: [String] = []
        for part in parts {
            var prop = part
            
            // Lowercase hex colors
            if let hashIndex = prop.firstIndex(of: "#") {
                let beforeHash = prop[..<hashIndex]
                let afterHash = prop[hashIndex...]
                prop = beforeHash + afterHash.lowercased()
            }
            
            // Format opacity values: 0.30 -> .3
            prop = formatOpacityValues(String(prop))
            
            // Add px to stroke-width if missing
            if prop.contains("stroke-width") && !prop.contains("px") {
                prop = prop.replacingOccurrences(
                    of: #"stroke-width:\s*(\d+)"#,
                    with: "stroke-width: $1px",
                    options: .regularExpression
                )
            }
            
            formatted.append("        \(prop);")
        }
        
        return formatted.joined(separator: "\n")
    }
    
    /// Format opacity values: 0.30 -> .3, 0.2 -> .2
    private static func formatOpacityValues(_ input: String) -> String {
        var result = input
        
        // Match patterns like "0.30" or "0.2" and convert to ".3" or ".2"
        let pattern = #"(\s|:)0\.(\d)0?"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: "$1.$2"
            )
        }
        
        return result
    }
    
    // MARK: - Polygon Points Transformation
    
    private static func transformPolygonPoints(_ svg: String) -> String {
        var result = svg
        
        // Find the data layer bounds to exclude it from transformation
        var dataLayerRange: Range<String.Index>? = nil
        if let dataStart = result.range(of: "<g id=\"data\">") {
            if let dataEnd = result.range(of: "</g>", range: dataStart.upperBound..<result.endIndex) {
                dataLayerRange = dataStart.lowerBound..<dataEnd.upperBound
            }
        }
        
        // Find all polygon points attributes
        let pattern = #"<polygon([^>]*)\s+points="([^"]+)"([^>]*)>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return svg
        }
        
        let range = NSRange(result.startIndex..<result.endIndex, in: result)
        let matches = regex.matches(in: result, options: [], range: range)
        
        // Process in reverse order to preserve indices
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result) else {
                continue
            }
            
            // Skip polygons inside the data layer
            if let dataRange = dataLayerRange {
                let matchStart = fullRange.lowerBound
                if matchStart >= dataRange.lowerBound && matchStart < dataRange.upperBound {
                    continue
                }
            }
            
            guard let beforeRange = Range(match.range(at: 1), in: result),
                  let pointsRange = Range(match.range(at: 2), in: result),
                  let afterRange = Range(match.range(at: 3), in: result) else {
                continue
            }
            
            let before = String(result[beforeRange])
            let pointsStr = String(result[pointsRange])
            let after = String(result[afterRange])
            
            // Transform points: "x,y x,y" -> "x y x y x y" (closed)
            let transformedPoints = transformPoints(pointsStr)
            
            // Strip any trailing "/" from after since we add our own closure
            let afterClean = after.hasSuffix("/") ? String(after.dropLast()) : after
            let newElement = "<polygon\(before) points=\"\(transformedPoints)\"\(afterClean)/>"
            result.replaceSubrange(fullRange, with: newElement)
        }
        
        return result
    }
    
    /// Transform points from "x,y x,y x,y" to "x y x y x y x y" (space-separated, closed)
    private static func transformPoints(_ points: String) -> String {
        // Replace commas with spaces
        var result = points.replacingOccurrences(of: ",", with: " ")
        
        // Normalize multiple spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        result = result.trimmingCharacters(in: .whitespaces)
        
        // Parse coordinates
        let parts = result.split(separator: " ").map { String($0) }
        guard parts.count >= 2 && parts.count % 2 == 0 else { return result }
        
        // Check if already closed (first point == last point)
        let firstX = parts[0]
        let firstY = parts[1]
        let lastX = parts[parts.count - 2]
        let lastY = parts[parts.count - 1]
        
        let isClosed = (firstX == lastX && firstY == lastY)
        
        // Close polygon if not already closed
        if !isClosed {
            result += " \(firstX) \(firstY)"
        }
        
        return result
    }
    
    // MARK: - Number Formatting
    
    private static func formatNumbers(_ svg: String) -> String {
        var result = svg
        
        // Format decimal numbers in points attributes: remove trailing zeros
        // e.g., "1024.0" -> "1024", "530.80" -> "530.8"
        let pointsPattern = #"points="([^"]+)""#
        if let regex = try? NSRegularExpression(pattern: pointsPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, options: [], range: range)
            
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let pointsRange = Range(match.range(at: 1), in: result) else {
                    continue
                }
                
                let pointsStr = String(result[pointsRange])
                let formatted = formatPointNumbers(pointsStr)
                result.replaceSubrange(fullRange, with: "points=\"\(formatted)\"")
            }
        }
        
        return result
    }
    
    /// Format numbers in points string: remove unnecessary trailing zeros
    private static func formatPointNumbers(_ points: String) -> String {
        let parts = points.split(separator: " ")
        let formatted = parts.map { part -> String in
            guard let value = Double(part) else { return String(part) }
            
            // Format: remove trailing zeros, but keep one decimal if needed
            if value == value.rounded() {
                return String(format: "%.0f", value)
            } else {
                // Remove trailing zeros
                let str = String(format: "%.1f", value)
                if str.hasSuffix(".0") {
                    return String(str.dropLast(2))
                }
                return str
            }
        }
        return formatted.joined(separator: " ")
    }
}
