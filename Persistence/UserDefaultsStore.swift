//
//  UserDefaultsStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import Foundation

enum UserDefaultsStore {
    static func save<T: Encodable>(_ value: T, key: String) {
        do { 
            UserDefaults.standard.set(try JSONEncoder().encode(value), forKey: key) 
        } catch { 
            print("Failed to save \(key): \(error)")
        }
    }
    
    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Failed to load \(key): \(error)")
            return nil
        }
    }
}
