//
//  MapPointDrawer.swift
//  TapResolver
//
//  by Chris Gelles
//

import SwiftUI
import CoreGraphics

struct MapPointDrawer: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState

    private let crosshairScreenOffset = CGPoint(x: 0, y: 0)
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 172
    private let topBarHeight: CGFloat = 48
    private let drawerMaxHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            // List
            ScrollView(.vertical) {
                ScrollViewReader { proxy in
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(mapPointStore.points.sorted(by: { $0.createdDate > $1.createdDate }), id: \.id) { point in
                            MapPointListItem(
                                point: point,
                                coordinateText: mapPointStore.coordinateString(for: point),
                                isActive: mapPointStore.isActive(point.id),
                                onSelect: {
                                    // ✅ TOGGLE: If already selected, deselect
                                    if mapPointStore.selectedPointID == point.id {
                                        mapPointStore.selectedPointID = nil
                                        print("🔘 Deselected MapPoint from drawer: \(point.id)")
                                    } else {
                                        print("📍 Map Point selected with ID: \(point.id.uuidString)")
                                        mapPointStore.selectPoint(id: point.id)
                                        mapPointStore.selectedPointID = point.id
                                        mapTransform.centerOnPoint(point.mapPoint, animated: true)
                                    }
                                },
                                onDelete: {
                                    mapPointStore.removePoint(id: point.id)
                                }
                            )
                            .frame(height: 44)
                            .padding(.leading, 4)
                            .id(point.id)
                        }
                    }
                    .padding(.top, topBarHeight + 6)
                    .padding(.bottom, 8)
                    .padding(.trailing, 6)
                    .onChange(of: mapPointStore.selectedPointID) { newSelection in
                        guard let selectedID = newSelection else { return }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(selectedID, anchor: .top)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .opacity(hud.isMapPointOpen ? 1 : 0)          // hide visuals when closed
            .allowsHitTesting(hud.isMapPointOpen)         // ignore touches when closed

            // Top bar
            HStack(spacing: 2) {
                if hud.isMapPointOpen {
                    Text("Map Points")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Point count badge
                    Text("\(mapPointStore.points.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                    
                    Spacer(minLength: 0)
                }
                Button {
                    if hud.isMapPointOpen { 
                        hud.closeAll() 
                    } else { 
                        hud.openMapPoint()
                        printMapPointDiagnostic()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .rotationEffect(.degrees(hud.isMapPointOpen ? 180 : 0))
                        .contentShape(Circle())
                }
                .accessibilityLabel(hud.isMapPointOpen ? "Close map point drawer" : "Open map point drawer")
            }
            .padding(.horizontal, 8)
            .frame(height: topBarHeight)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // ⚠️ TEMPORARY DEBUG BUTTON - COMMENTED OUT
            // Uncomment to show delete button for debugging
            /*
            if hud.isMapPointOpen {
                Button(action: {
                    print("⚠️ USER TRIGGERED: Delete all scan files")
                    mapPointLogManager.deleteAllScanFiles()
                }) {
                    Text("🗑️ DELETE ALL SCANS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                }
                .padding(.horizontal, 8)
                .padding(.top, topBarHeight + 4)
            }
            */
        }
        .frame(
            width: hud.isMapPointOpen ? expandedWidth : collapsedWidth,
            height: hud.isMapPointOpen ? min(drawerMaxHeight, idealOpenHeight) : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
    }

    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(mapPointStore.points.count)
        let rowsHeight = rows * 44 + (rows - 1) * 6 + 6 + 8
        let total = max(topBarHeight, min(drawerMaxHeight, topBarHeight + rowsHeight))
        return total
    }
    
    // MARK: - Diagnostic
    
    private func printMapPointDiagnostic() {
        print("\n" + String(repeating: "=", count: 80))
        print("📍 MAP POINT DRAWER - PLIST DATA STRUCTURE")
        print(String(repeating: "=", count: 80))
        
        print("\nLocation: \(PersistenceContext.shared.locationID)")
        print("Total Map Points in Store: \(mapPointStore.points.count)")
        
        if mapPointStore.points.isEmpty {
            print("\n⚠️ NO MAP POINTS FOUND")
        } else {
            for (index, point) in mapPointStore.points.enumerated() {
                print("\n[\(index + 1)] Map Point:")
                print("   ID: \(point.id.uuidString)")
                print("   Position: (\(Int(point.mapPoint.x)), \(Int(point.mapPoint.y)))")
                print("   Created: \(point.createdDate)")
                print("   Sessions: \(point.sessions.count)")
                
                if point.sessions.isEmpty {
                    print("      (No sessions)")
                } else {
                    for (sessionIndex, session) in point.sessions.enumerated() {
                        print("      [\(sessionIndex + 1)] Session:")
                        print("         Session ID: \(session.sessionID)")
                        print("         Scan ID: \(session.scanID)")
                        print("         Duration: \(String(format: "%.1f", session.duration_s))s")
                        print("         Beacons: \(session.beacons.count)")
                        print("         Timing: \(session.timingStartISO)")
                    }
                }
            }
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("📊 SUMMARY:")
        print("   Total Points: \(mapPointStore.points.count)")
        print("   Total Sessions: \(mapPointStore.points.reduce(0) { $0 + $1.sessions.count })")
        print(String(repeating: "=", count: 80) + "\n")
    }
}

struct MapPointListItem: View {
    let point: MapPointStore.MapPoint
    let coordinateText: String
    let isActive: Bool
    var onSelect: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @EnvironmentObject private var mapPointStore: MapPointStore

    var body: some View {
        HStack(spacing: 2) {
            // Coordinate display in rounded rectangle - tappable for selection
            Button(action: { onSelect?() }) {
                Text(coordinateText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isActive ? Color(hex: 0x10fff1).opacity(0.9) : Color.blue.opacity(0.2))
                    )
                    .fixedSize(horizontal: true, vertical: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isActive ? "Deactivate map point" : "Activate map point")
            
            // AR Marker indicator flag
            if point.linkedARMarkerID != nil {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
            
            Spacer(minLength: 0)

            // Delete button (red X)
            Button(action: { onDelete?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete map point")
        }
        .padding(.horizontal, 0)                                    // ← row side padding
        .padding(.vertical, 6)                                      // ← row vertical padding
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
        .frame(height: 44)                                          // ← row height (matches drawer)
    }
}
