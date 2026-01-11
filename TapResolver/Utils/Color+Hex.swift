//
//  Color+Hex.swift
//  TapResolver
//
//  SwiftUI Color extension for hex string conversion.
//

import SwiftUI
import UIKit

extension Color {
    /// Initialize Color from hex string (e.g., "#3154ff" or "3154ff")
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    /// Convert Color to hex string (e.g., "#3154FF")
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(r * 255)
        let gi = Int(g * 255)
        let bi = Int(b * 255)
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
