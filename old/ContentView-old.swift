//
//  ContentView.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Use a GeometryReader to make the ZStack fill the entire screen,
        // and to get the size of the view for accurate tap coordinate reporting.
        GeometryReader { geometry in
            ZStack {
                // A solid color fills the entire screen to ensure it's tappable everywhere
                Color.blue
                    .ignoresSafeArea() // Make it truly full-screen, under safe areas
            }
            .contentShape(Rectangle()) // Makes the entire ZStack tappable, even transparent parts
            .onTapGesture(coordinateSpace: .local) { location in
                // Report the tap location relative to this view's local coordinate space
                print("Tapped at X: \(location.x), Y: \(location.y) (relative to view: \(geometry.size.width)x\(geometry.size.height))")
            }
            
            ZStack {
                // Main map container (matches MapImage size)
                MapContainer()
                    .zIndex(10)

                // HUD overlays (full screen, above map)
                HUDContainer()
                    .zIndex(100)
            }

        }
    }
}

struct MapContainer: View {
    var body: some View {
        if let uiImage = UIImage(named: "myFirstFloor_v03-metric") {
            let width = uiImage.size.width
            let height = uiImage.size.height
        
        ZStack {
            MapImage()
                .zIndex(10)

            MeasureLines()
                .frame(width: width, height: height)
                .zIndex(20)

            BeaconOverlay()
                .frame(width: width, height: height)
                .zIndex(30)

            UserNavigation()
                .frame(width: width, height: height)
                .zIndex(35)

            MeterLabels()
                .frame(width: width, height: height)
                .zIndex(40)
        }
        .frame(width: width, height: height)   //MapContainer matches MapImage size
        .position(x: UIScreen.main.bounds.width / 2,
                  y: UIScreen.main.bounds.height / 2) // center whole container
    } else {
        Color.red // fallback if image not found
    }
        
    }
}

// Empty placeholder views for now
struct MapImage: View {
    var body: some View {
        if let uiImage = UIImage(named: "myFirstFloor_v03-metric") {
            let width = uiImage.size.width
            let height = uiImage.size.height
            
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: width,
                       height: height)  // native size
        }
    }
}
struct MeasureLines: View { var body: some View { Color.clear } }
struct BeaconOverlay: View { var body: some View { Color.clear } }
struct UserNavigation: View { var body: some View { Color.clear } }
struct MeterLabels: View { var body: some View { Color.clear } }

struct HUDContainer: View {
    // Drawer state
    @State private var isOpen = false
    @State private var phaseOneDone = false
    @State private var drawerWidth: CGFloat = 56
    private let expandedWidth: CGFloat = min(320, UIScreen.main.bounds.width * 0.6)

    // Keep mock data for testing; replace later with BeaconManager
    private let mockBeacons = ["12-rowdySquirrel","15-frostyIbis","08-bouncyPenguin","23-sparklyDolphin","31-gigglyGiraffe"]

    var body: some View {
        // Full-screen overlay; DOES NOT block gestures outside drawer
        ZStack(alignment: .topTrailing) {
            // Right-side drawer only
            drawerContainer
                .padding(.top, 16)
                .padding(.trailing, 16)
                .zIndex(100)                // above map/HUD
                .allowsHitTesting(true)     // only this captures touches
        }
        .ignoresSafeArea()
        .zIndex(100) // ensure above your map stack
    }

    // MARK: - Drawer Container
    private var drawerContainer: some View {
        VStack(alignment: .trailing, spacing: 0) {
            topBar
            beaconList
                .frame(height: isOpen && phaseOneDone ? nil : 0)
                .clipped()
                .opacity(isOpen && phaseOneDone ? 1 : 0)
        }
        .frame(width: isOpen ? expandedWidth : drawerWidth)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.06)) // light, unobtrusive
        )
        .contentShape(Rectangle()) // reliable tap hit area
        // No extra shadows/material to keep performance and interactions clean
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 8) {
            if isOpen {
                Text("Beacons")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }

            Button(action: toggleDrawer) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.08)))
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .accessibilityLabel(isOpen ? "Close beacon drawer" : "Open beacon drawer")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    // MARK: - Beacon List
    private var beaconList: some View {
        let sorted = mockBeacons.sorted()
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sorted, id: \.self) { name in
                    BeaconListItem(beaconName: name)
                        .frame(height: 44)

                    // Divider except after last
                    if name != sorted.last {
                        Divider().padding(.horizontal, 12)
                    }
                }
            }
        }
        .transition(.opacity) // simple, predictable
    }

    // MARK: - Animation Logic
    private func toggleDrawer() {
        isOpen ? closeDrawer() : openDrawer()
    }

    private func openDrawer() {
        // Phase 1: width expands
        withAnimation(.easeInOut(duration: 0.25)) {
            isOpen = true
        }
        // Phase 2: content reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                phaseOneDone = true
            }
        }
    }

    private func closeDrawer() {
        // Phase 1: content hide
        withAnimation(.easeInOut(duration: 0.25)) {
            phaseOneDone = false
        }
        // Phase 2: width collapses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isOpen = false
            }
        }
    }
}

// MARK: - Beacon List Item
struct BeaconListItem: View {
    let beaconName: String

    private var beaconColor: Color {
        let hash = beaconName.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(beaconColor).frame(width: 12, height: 12)
            Text(beaconName)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }
}


#Preview {
    ContentView()
}
