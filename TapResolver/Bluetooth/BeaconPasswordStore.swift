//
//  BeaconPasswordStore.swift
//  TapResolver
//
//  Secure storage for beacon passwords using Keychain
//

import Foundation
import Security

class BeaconPasswordStore {
    static let shared = BeaconPasswordStore()
    
    private let servicePrefix = "com.tapresolver.beacon"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get the beacon password for a location
    func getPassword(for locationID: String) -> String? {
        let key = makeKey(for: locationID)
        return readFromKeychain(key: key)
    }
    
    /// Set the beacon password for a location
    func setPassword(_ password: String, for locationID: String) {
        let key = makeKey(for: locationID)
        if password.isEmpty {
            deleteFromKeychain(key: key)
            print("🔐 [BeaconPassword] Cleared password for location '\(locationID)'")
        } else {
            saveToKeychain(key: key, value: password)
            print("🔐 [BeaconPassword] Saved password for location '\(locationID)'")
        }
    }
    
    /// Check if a password exists for a location
    func hasPassword(for locationID: String) -> Bool {
        return getPassword(for: locationID) != nil
    }
    
    /// Delete the password for a location
    func deletePassword(for locationID: String) {
        let key = makeKey(for: locationID)
        deleteFromKeychain(key: key)
        print("🔐 [BeaconPassword] Deleted password for location '\(locationID)'")
    }
    
    // MARK: - Private Helpers
    
    private func makeKey(for locationID: String) -> String {
        return "\(servicePrefix).\(locationID)"
    }
    
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete existing item first
        deleteFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ [BeaconPassword] Keychain save failed: \(status)")
        }
    }
    
    private func readFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

