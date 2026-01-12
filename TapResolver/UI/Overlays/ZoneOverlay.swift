//
//  ZoneOverlay.swift
//  TapResolver
//
//  Renders zone quadrilaterals on the map using group colors.
//

import SwiftUI

struct ZoneOverlay: View {
    @EnvironmentObject private var zoneStore: ZoneStore
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    var body: some View {
        // Explicit dependencies to trigger Canvas redraw
        let _ = zoneStore.zones.count
        let _ = zoneStore.zonesVisible
        let _ = mapPointStore.points.count
        
        return Canvas { context, size in
            guard zoneStore.zonesVisible else { return }
            
            for zone in zoneStore.zones {
                drawZone(zone, in: context)
            }
        }
    }
    
    private func drawZone(_ zone: Zone, in context: GraphicsContext) {
        // Get corner positions from MapPoints
        let corners: [CGPoint] = zone.cornerMapPointIDs.compactMap { cornerID in
            guard let uuid = UUID(uuidString: cornerID),
                  let mapPoint = mapPointStore.points.first(where: { $0.id == uuid }) else {
                return nil
            }
            return mapPoint.mapPoint
        }
        
        // Need exactly 4 corners to draw
        guard corners.count == 4 else { return }
        
        // Build the path
        var path = Path()
        path.move(to: corners[0])
        path.addLine(to: corners[1])
        path.addLine(to: corners[2])
        path.addLine(to: corners[3])
        path.closeSubpath()
        
        // Get color from zone's group, fallback to gray
        let fillColor = zoneColor(for: zone).opacity(0.2)
        
        // Draw filled polygon
        context.fill(path, with: .color(fillColor))
    }
    
    private func zoneColor(for zone: Zone) -> Color {
        // Try to get color from group
        if let groupID = zone.groupID,
           let group = zoneGroupStore.group(withID: groupID),
           let color = Color(hex: group.colorHex) {
            return color
        }
        // Fallback
        return Color.orange
    }
}

#Preview {
    ZoneOverlay()
        .environmentObject(ZoneStore())
        .environmentObject(ZoneGroupStore())
        .environmentObject(MapPointStore())
}
