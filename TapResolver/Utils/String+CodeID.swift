//
//  String+CodeID.swift
//  TapResolver
//
//  String extensions for display name ↔ code ID conversion.
//

import Foundation

extension String {
    /// Convert display name to code ID: "Dunk Theater" → "dunk-theater"
    var asCodeID: String {
        self.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
    
    /// Convert code ID to display name: "dunk-theater" → "Dunk Theater"
    var asDisplayName: String {
        self.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
