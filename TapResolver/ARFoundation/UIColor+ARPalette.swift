//
//  UIColor+ARPalette.swift
//  TapResolver
//
//  Centralized AR marker color palette
//

import UIKit

extension UIColor {
    struct ARPalette {
        static let markerBase = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: 0.98)
        static let markerRing = UIColor(red: 71/255, green: 199/255, blue: 239/255, alpha: 0.7)
        static let markerFill = UIColor.white.withAlphaComponent(0.15)
        static let markerLine = UIColor(red: 0/255, green: 50/255, blue: 98/255, alpha: 0.95)
        static let badge = UIColor.systemPink
        
        // Mode-specific colors
        static let calibration = UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 0.98) // Orange
        static let anchor = UIColor(red: 0/255, green: 200/255, blue: 255/255, alpha: 0.98) // Cyan
    }
}

