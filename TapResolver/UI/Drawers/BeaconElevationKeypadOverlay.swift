//
//  BeaconElevationKeypadOverlay.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// MARK: - Elevation keypad overlay
struct BeaconElevationKeypadOverlay: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore

    private let keyRows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        [".","0","⌫"]
    ]

    var body: some View {
        if let edit = beaconDotStore.activeElevationEdit {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { beaconDotStore.activeElevationEdit = nil }

                VStack(spacing: 10) {
                    Text(edit.text.isEmpty ? " " : edit.text)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        ForEach(0..<keyRows.count, id: \.self) { r in
                            HStack(spacing: 8) {
                                ForEach(keyRows[r], id: \.self) { key in
                                    Button { tap(key: key) } label: {
                                        Text(key)
                                            .font(.system(size: 20, weight: .medium))
                                            .frame(width: 68, height: 44)
                                            .background(Color.white.opacity(0.12))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        HStack {
                            Button {
                                let beaconID = edit.beaconID
                                let text = edit.text
                                beaconDotStore.commitElevationText(text, for: beaconID)
                                beaconDotStore.activeElevationEdit = nil
                            } label: {
                                Text("Enter")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 46)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .transition(.opacity)
            .zIndex(200)
            .allowsHitTesting(true)
        }
    }

    private func tap(key: String) {
        guard var edit = beaconDotStore.activeElevationEdit else { return }
        switch key {
        case "⌫":
            if !edit.text.isEmpty { edit.text.removeLast() }
        case ".":
            if !edit.text.contains(".") { edit.text.append(".") }
        default:
            if key.allSatisfy({ $0.isNumber }) {
                if edit.text == "0" { edit.text = key }
                else { edit.text.append(contentsOf: key) }
            }
        }
        beaconDotStore.activeElevationEdit = edit
    }
}
