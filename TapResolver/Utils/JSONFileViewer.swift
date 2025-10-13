//
//  JSONFileViewer.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/12/25.
//


//
//  JSONFileViewer.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Utility for displaying formatted JSON file contents in Console
//

import Foundation

struct JSONFileViewer {
    
    /// Display the contents of a JSON file with formatted output
    /// - Parameters:
    ///   - fileURL: URL of the JSON file to display
    ///   - maxDepth: Maximum nesting depth to display (default: 10)
    ///   - truncateArrays: Maximum array elements to show (default: nil = show all)
    static func displayFile(at fileURL: URL, maxDepth: Int = 10, truncateArrays: Int? = nil) {
        print("\n" + String(repeating: "=", count: 80))
        print("📄 JSON FILE VIEWER")
        print(String(repeating: "=", count: 80))
        print("File: \(fileURL.lastPathComponent)")
        print("Path: \(fileURL.path)")
        print(String(repeating: "-", count: 80))
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Try to parse as JSON
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                print("❌ File is not valid JSON")
                print(String(repeating: "=", count: 80) + "\n")
                return
            }
            
            // Display formatted
            displayValue(json, indent: 0, maxDepth: maxDepth, truncateArrays: truncateArrays)
            
        } catch {
            print("❌ Error reading file: \(error.localizedDescription)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Display a JSON file with file path as String
    static func displayFile(atPath path: String, maxDepth: Int = 10, truncateArrays: Int? = nil) {
        let url = URL(fileURLWithPath: path)
        displayFile(at: url, maxDepth: maxDepth, truncateArrays: truncateArrays)
    }
    
    /// Display raw JSON string
    static func displayJSON(_ jsonString: String, title: String = "JSON") {
        print("\n" + String(repeating: "=", count: 80))
        print("📄 \(title)")
        print(String(repeating: "=", count: 80))
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("❌ Invalid JSON string")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        displayValue(json, indent: 0, maxDepth: 10, truncateArrays: nil)
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Display Data as JSON
    static func displayData(_ data: Data, title: String = "JSON Data") {
        print("\n" + String(repeating: "=", count: 80))
        print("📄 \(title)")
        print(String(repeating: "=", count: 80))
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            print("❌ Data is not valid JSON")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        displayValue(json, indent: 0, maxDepth: 10, truncateArrays: nil)
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Private Helpers
    
    private static func displayValue(_ value: Any, indent: Int, maxDepth: Int, truncateArrays: Int?) {
        let indentStr = String(repeating: "  ", count: indent)
        
        if indent > maxDepth {
            print("\(indentStr)... (max depth reached)")
            return
        }
        
        switch value {
        case let dict as [String: Any]:
            displayDictionary(dict, indent: indent, maxDepth: maxDepth, truncateArrays: truncateArrays)
            
        case let array as [Any]:
            displayArray(array, indent: indent, maxDepth: maxDepth, truncateArrays: truncateArrays)
            
        case let string as String:
            print("\(indentStr)\"\(string)\"")
            
        case let number as NSNumber:
            // Detect booleans
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                print("\(indentStr)\(number.boolValue)")
            } else {
                print("\(indentStr)\(number)")
            }
            
        case is NSNull:
            print("\(indentStr)null")
            
        default:
            print("\(indentStr)\(value)")
        }
    }
    
    private static func displayDictionary(_ dict: [String: Any], indent: Int, maxDepth: Int, truncateArrays: Int?) {
        let indentStr = String(repeating: "  ", count: indent)
        
        if dict.isEmpty {
            print("\(indentStr){}")
            return
        }
        
        print("\(indentStr){")
        
        let sortedKeys = dict.keys.sorted()
        for (index, key) in sortedKeys.enumerated() {
            let value = dict[key]!
            let isLast = index == sortedKeys.count - 1
            
            // Print key
            print("\(indentStr)  \"\(key)\": ", terminator: "")
            
            // Handle value inline for simple types
            switch value {
            case let string as String:
                print("\"\(string)\"\(isLast ? "" : ",")")
                
            case let number as NSNumber:
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    print("\(number.boolValue)\(isLast ? "" : ",")")
                } else {
                    print("\(number)\(isLast ? "" : ",")")
                }
                
            case is NSNull:
                print("null\(isLast ? "" : ",")")
                
            case let nestedDict as [String: Any]:
                print("")
                displayDictionary(nestedDict, indent: indent + 1, maxDepth: maxDepth, truncateArrays: truncateArrays)
                if !isLast { print("\(indentStr)  ,") }
                
            case let array as [Any]:
                print("")
                displayArray(array, indent: indent + 1, maxDepth: maxDepth, truncateArrays: truncateArrays)
                if !isLast { print("\(indentStr)  ,") }
                
            default:
                print("\(value)\(isLast ? "" : ",")")
            }
        }
        
        print("\(indentStr)}")
    }
    
    private static func displayArray(_ array: [Any], indent: Int, maxDepth: Int, truncateArrays: Int?) {
        let indentStr = String(repeating: "  ", count: indent)
        
        if array.isEmpty {
            print("\(indentStr)[]")
            return
        }
        
        print("\(indentStr)[")
        
        let displayCount = truncateArrays.map { min($0, array.count) } ?? array.count
        let truncated = displayCount < array.count
        
        for (index, item) in array.prefix(displayCount).enumerated() {
            let isLast = index == displayCount - 1 && !truncated
            
            print("\(indentStr)  ", terminator: "")
            
            switch item {
            case let string as String:
                print("\"\(string)\"\(isLast ? "" : ",")")
                
            case let number as NSNumber:
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    print("\(number.boolValue)\(isLast ? "" : ",")")
                } else {
                    print("\(number)\(isLast ? "" : ",")")
                }
                
            case is NSNull:
                print("null\(isLast ? "" : ",")")
                
            case let nestedDict as [String: Any]:
                print("")
                displayDictionary(nestedDict, indent: indent + 1, maxDepth: maxDepth, truncateArrays: truncateArrays)
                if !isLast { print("\(indentStr)  ,") }
                
            case let nestedArray as [Any]:
                print("")
                displayArray(nestedArray, indent: indent + 1, maxDepth: maxDepth, truncateArrays: truncateArrays)
                if !isLast { print("\(indentStr)  ,") }
                
            default:
                print("\(item)\(isLast ? "" : ",")")
            }
        }
        
        if truncated {
            print("\(indentStr)  ... (\(array.count - displayCount) more items)")
        }
        
        print("\(indentStr)]")
    }
}

// MARK: - Convenience Extensions

extension URL {
    /// Display this JSON file's contents in Console
    func displayJSON(maxDepth: Int = 10, truncateArrays: Int? = nil) {
        JSONFileViewer.displayFile(at: self, maxDepth: maxDepth, truncateArrays: truncateArrays)
    }
}

extension Data {
    /// Display this Data as formatted JSON in Console
    func displayJSON(title: String = "JSON Data") {
        JSONFileViewer.displayData(self, title: title)
    }
}

extension String {
    /// Display this String as formatted JSON in Console (if valid JSON)
    func displayJSON(title: String = "JSON") {
        JSONFileViewer.displayJSON(self, title: title)
    }
}