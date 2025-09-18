//
//  TapResolverApp.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

@main
struct TapResolverApp: App {
    @StateObject private var mapTransform = MapTransformStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mapTransform)
        }
    }
}


