//
//  HUDPanelsState.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// MARK: - HUD panel state (unchanged except for isMorgueOpen you added)
final class HUDPanelsState: ObservableObject {
    @Published var isBeaconOpen: Bool = false
    @Published var isSquareOpen: Bool = false
    @Published var isMorgueOpen: Bool = false
    @Published var isMapPointOpen: Bool = false
    @Published var isCalibratingNorth: Bool = false
    @Published var showFacingOverlay: Bool = true

    func openBeacon() { isBeaconOpen = true; isSquareOpen = false; isMorgueOpen = false; isMapPointOpen = false }
    func openSquares() { isSquareOpen = true; isBeaconOpen = false; isMorgueOpen = false; isMapPointOpen = false }
    func openMorgue() { isMorgueOpen = true; isBeaconOpen = false; isSquareOpen = false; isMapPointOpen = false }
    func openMapPoint() { isMapPointOpen = true; isBeaconOpen = false; isSquareOpen = false; isMorgueOpen = false }
    func closeAll() { isBeaconOpen = false; isSquareOpen = false; isMorgueOpen = false; isMapPointOpen = false }
}
