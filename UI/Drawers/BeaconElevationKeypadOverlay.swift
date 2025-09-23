//
//  NumericKeypadInterface.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// MARK: - Generic numeric keypad interface
struct NumericKeypadInterface: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore

    var body: some View {
        if let edit = beaconDotStore.activeElevationEdit {
            NumericInputKeypad(
                title: "Elevation",
                initialText: edit.text,
                onCommit: { text in
                    beaconDotStore.commitElevationText(text, for: edit.beaconID)
                },
                onDismiss: {
                    beaconDotStore.activeElevationEdit = nil
                }
            )
        }
    }
}
