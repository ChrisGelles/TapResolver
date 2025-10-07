//
//  MeasureLines.swift
//  TapResolver
//
//  Created by restructuring on 9/26/25.
//

import SwiftUI
import CoreGraphics

struct MeasureLines: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var beaconLists: BeaconListsStore
    
    var body: some View {
        Canvas { context, size in
            // Only draw lines when MapPointDrawer is open and there's an active map point
            guard hud.isMapPointOpen,
                  let activePoint = mapPointStore.activePoint else {
                return
            }
            
            // Get all beacon dots that are in the beacon list (whitelisted)
            let activeBeaconDots = beaconDotStore.dots.filter { dot in
                beaconLists.beacons.contains(dot.beaconID)
            }
            
            // Draw a line from the active map point to each beacon dot
            for beaconDot in activeBeaconDots {
                let startPoint = activePoint.mapPoint
                let endPoint = beaconDot.mapPoint
                
                // Create path for the line
                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                
                // Draw the line with black color and 40% opacity
                context.stroke(path, with: .color(.black.opacity(0.4)), lineWidth: 1.0)
            }
        }
    }
}
