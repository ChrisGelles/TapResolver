//
//  FeatureFlags.swift
//  TapResolver
//
//  Centralized feature flags for controlling UI visibility and feature availability.
//  Flags are persisted to UserDefaults and can be toggled via Debug Settings Panel.
//

import Foundation

/// Centralized feature flags for UI and feature control.
/// All flags are UserDefaults-backed for persistence across launches.
enum FeatureFlags {
    private static let defaults = UserDefaults.standard
    
    // MARK: - Panel Visibility
    
    /// Show the Map Point Log Panel button in the right-side HUD drawer.
    /// Default: false (hidden)
    static var showMapPointLogPanel: Bool {
        get { defaults.object(forKey: "ff_showMapPointLogPanel") as? Bool ?? false }
        set { 
            defaults.set(newValue, forKey: "ff_showMapPointLogPanel")
            print("🚩 [FeatureFlags] showMapPointLogPanel = \(newValue)")
        }
    }
    
    // MARK: - Future Flags (commented templates)
    
    // static var showTriangleCreationButton: Bool {
    //     get { defaults.object(forKey: "ff_showTriangleCreationButton") as? Bool ?? true }
    //     set { defaults.set(newValue, forKey: "ff_showTriangleCreationButton") }
    // }
    
    // static var showZoneCreationButton: Bool {
    //     get { defaults.object(forKey: "ff_showZoneCreationButton") as? Bool ?? true }
    //     set { defaults.set(newValue, forKey: "ff_showZoneCreationButton") }
    // }
}

