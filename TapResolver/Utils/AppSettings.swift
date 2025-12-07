//
//  AppSettings.swift
//  TapResolver
//
//  Manages app-wide settings and user preferences
//

import Foundation

enum AppSettings {
    private static let authorNameKey = "app.authorName"
    private static let hasCompletedOnboardingKey = "app.hasCompletedOnboarding"
    
    /// Get or set the author name for location exports
    static var authorName: String {
        get {
            UserDefaults.standard.string(forKey: authorNameKey) ?? "Unknown"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: authorNameKey)
        }
    }
    
    /// Check if user has completed initial onboarding
    static var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }
    
    /// Check if author name needs to be set
    static var needsAuthorName: Bool {
        return UserDefaults.standard.string(forKey: authorNameKey) == nil
    }
    
    private static let followUserInPiPKey = "app.followUserInPiP"
    private static let followUserInMainMapKey = "app.followUserInMainMap"
    
    /// Whether PiP map follows user position during AR sessions (default: ON)
    static var followUserInPiP: Bool {
        get {
            UserDefaults.standard.object(forKey: followUserInPiPKey) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: followUserInPiPKey)
        }
    }
    
    /// Whether main map view follows user position (default: OFF)
    static var followUserInMainMap: Bool {
        get {
            UserDefaults.standard.bool(forKey: followUserInMainMapKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: followUserInMainMapKey)
        }
    }
}

