//
//  MetricSquareDrawer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Drawer
struct MetricSquareDrawer: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var squareMetrics: SquareMetrics

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 180
    private let topBarHeight: CGFloat = 48
    private let rowHeight: CGFloat = 44
    private let drawerMaxHeight: CGFloat = 320
    private let bottomMargin: CGFloat = 8

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    addRow
                        .frame(height: rowHeight)
                        .padding(.leading, 8)

                    ForEach(squares.squares) { sq in
                        squareRow(sq)
                            .frame(height: rowHeight)
                            .padding(.leading, 8)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, bottomMargin)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)

            topBar
                .frame(height: topBarHeight)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(
            width: hud.isSquareOpen ? expandedWidth : collapsedWidth,
            height: hud.isSquareOpen ? min(drawerMaxHeight, idealOpenHeight) : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isSquareOpen)
    }

    private var topBar: some View {
        HStack(spacing: 2) {
            if hud.isSquareOpen {
                Text("Metric Squares")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            Button {
                if hud.isSquareOpen { hud.closeAll() } else { hud.openSquares() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.4)))
                    .rotationEffect(.degrees(hud.isSquareOpen ? 180 : 0))
                    .contentShape(Circle())
            }
            .accessibilityLabel(hud.isSquareOpen ? "Close squares drawer" : "Open squares drawer")
        }
        .padding(.horizontal, 12)
    }

    private var addRow: some View {
        Button {
            guard squares.squares.count < squares.maxSquares else { return }
            guard mapTransform.mapSize != .zero else {
                print("⚠️ Square add ignored: mapTransform not ready (mapSize == .zero)")
                return
            }
            let targetScreen = mapTransform.screenCenter
            let centerOnMap  = mapTransform.screenToMap(targetScreen)
            let color = nextColor(for: squares.squares.count)
            squares.add(at: centerOnMap, color: color)
            print("▢ Square added @ map \(Int(centerOnMap.x)),\(Int(centerOnMap.y)) from screen center")
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                Text("Add square")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                //Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
    }

    private func squareRow(_ sq: MetricSquareStore.Square) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(sq.color.opacity(0.9))
                .frame(width: 20, height: 20)
                .cornerRadius(3)

            Button {
                // Seed with existing meters (no trailing "m")
                let existing = squareMetrics.entry(for: sq.id)?.meters ?? 1.0
                let seed = String(format: "%g", existing) // compact 1, 1.5, 0.25, etc.
                squareMetrics.activeEdit = .init(id: sq.id, text: seed)
            } label: {
                 Text(squareMetrics.displayMetersText(for: sq.id))
                     .font(.system(size: 10, weight: .medium, design: .monospaced))
                     .foregroundColor(.white)
                     .padding(.horizontal, 4)
                     .padding(.vertical, 7)
                     .background(Color.black.opacity(0.5))
                     .cornerRadius(6)
                     .fixedSize(horizontal: true, vertical: false)
             }
             .buttonStyle(.plain)
             .frame(maxWidth: 60, alignment: .leading) // Constrain width to prevent pushing buttons off
            
            // 🔒 Lock toggle
            Button {
                squares.toggleLock(id: sq.id)
            } label: {
                Image(systemName: sq.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(sq.isLocked ? .yellow : .primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(sq.isLocked ? "Unlock square" : "Lock square")

            // Reset
            Button {
                squares.reset(id: sq.id)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset square")

            // Delete (red X)
            Button {
                squares.remove(id: sq.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete square")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
    }

    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(squares.squares.count + 1)
        let rowsHeight = rows * rowHeight + (rows - 1) * 8 + 6 + bottomMargin
        let total = max(topBarHeight, min(drawerMaxHeight, topBarHeight + rowsHeight))
        return total
    }

    private func nextColor(for index: Int) -> Color {
        let hues: [Double] = [0.02, 0.10, 0.58, 0.78, 0.85, 0.42]
        let h = hues[index % hues.count]
        return Color(hue: h, saturation: 0.75, brightness: 0.9)
    }
}

// MARK: - Full-screen numeric keypad overlay (appears when squareMetrics.activeEdit != nil)
struct NumericKeypadOverlay: View {
    @EnvironmentObject private var squareMetrics: SquareMetrics

    private let keyRows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        [".","0","⌫"]
    ]

    var body: some View {
        // Only render when editing
        if let edit = squareMetrics.activeEdit {
            ZStack {
                // Dim backdrop (tap to dismiss without commit)
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { squareMetrics.activeEdit = nil }

                // Keypad panel pinned to bottom
                VStack(spacing: 10) {
                    // Display the current numeric text buffer (monospaced)
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
                        // Enter row
                        HStack {
                            Button {
                                // Commit and dismiss
                                let id = edit.id
                                let text = edit.text
                                squareMetrics.commitMetersText(text, for: id)
                                squareMetrics.activeEdit = nil
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
        guard var edit = squareMetrics.activeEdit else { return }
        switch key {
        case "⌫":
            if !edit.text.isEmpty { edit.text.removeLast() }
        case ".":
            if !edit.text.contains(".") { edit.text.append(".") }
        default:
            // digits
            if key.allSatisfy({ $0.isNumber }) {
                // prevent leading zero spam like "000"
                if edit.text == "0" { edit.text = key }
                else { edit.text.append(contentsOf: key) }
            }
        }
        squareMetrics.activeEdit = edit
    }
}