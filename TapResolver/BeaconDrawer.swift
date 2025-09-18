//
//  BeaconDrawer.swift
//  TapResolver
//
//  Right-side drawer listing beacons, toggling one dot per beacon on the map.
//

import SwiftUI

struct BeaconDrawer: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    @State private var isOpen = false
    @State private var phaseOneDone = false

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 160

    // TODO: replace with real data later
    private let mockBeacons = [
        "12-rowdySquirrel","15-frostyIbis","08-bouncyPenguin","23-sparklyDolphin","31-gigglyGiraffe"
    ]

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            topBar
                .frame(width: max(44, isOpen ? expandedWidth : collapsedWidth)) // expand tap area when collapsed
            beaconList
                .frame(height: isOpen && phaseOneDone ? nil : 0)
                .clipped()
                .opacity(isOpen && phaseOneDone ? 1 : 0)
        }
        .frame(width: isOpen ? expandedWidth : collapsedWidth)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))
        )
        .contentShape(Rectangle())
    }

    private var topBar: some View {
        HStack(spacing: 2) {
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
                    .background(Circle().fill(Color.black.opacity(0.4)))
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .contentShape(Circle())
            }
            .accessibilityLabel(isOpen ? "Close beacon drawer" : "Open beacon drawer")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private var beaconList: some View {
        let sorted = mockBeacons.sorted()
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sorted, id: \.self) { name in
                    BeaconListItem(beaconName: name) { globalTapPoint, color in
                        // 1) 20 px left of tap (in GLOBAL coords)
                        let shifted = CGPoint(x: globalTapPoint.x, y: globalTapPoint.y)
                        // 2) Convert to MAP-LOCAL coords using current transform
                        let mapPoint = mapTransform.screenToMap(shifted)
                        // 3) Toggle the dot for this beacon
                        beaconDotStore.toggleDot(for: name, mapPoint: mapPoint, color: color)
                        // 4) Close the drawer
                        closeDrawer()
                    }
                    .frame(height: 44)
                    .padding(.leading, 8)   // ⬅️ add this line
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxHeight: 300) // cap if list is long
        .fixedSize(horizontal: false, vertical: true)
        .transition(.opacity)
    }

    private func toggleDrawer() { isOpen ? closeDrawer() : openDrawer() }

    private func openDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { isOpen = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) { phaseOneDone = true }
        }
    }

    private func closeDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { phaseOneDone = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) { isOpen = false }
        }
    }
}

// MARK: - Row

struct BeaconListItem: View {
    let beaconName: String
    var onSelect: ((CGPoint, Color) -> Void)? = nil

    private var beaconColor: Color {
        let hash = beaconName.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(beaconColor)
                .frame(width: 12, height: 12)

            Text(beaconName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(beaconColor.opacity(0.2))
        )
        .contentShape(Rectangle())
        // capture tap in GLOBAL space and pass to callback
        .onTapGesture(coordinateSpace: .global) { globalPoint in
            onSelect?(globalPoint, beaconColor)
        }
    }
}
