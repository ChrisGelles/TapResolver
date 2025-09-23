//
//  UIElements.swift
//  TapResolver
//
//  Created by restructuring on 9/22/25.
//

import SwiftUI

// MARK: - Generic Numeric Input Keypad Component
struct NumericInputKeypad: View {
    let title: String
    let initialText: String
    let onCommit: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var currentText: String
    
    private let keyRows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        [".","0","⌫"]
    ]
    
    init(title: String, initialText: String, onCommit: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.title = title
        self.initialText = initialText
        self.onCommit = onCommit
        self.onDismiss = onDismiss
        self._currentText = State(initialValue: initialText)
    }
    
    var body: some View {
        ZStack {
            // Dim backdrop (tap to dismiss without commit)
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Keypad panel - takes up lower third to half of screen
            VStack(spacing: 0) {
                Spacer() // Push keypad to lower portion
                
                VStack(spacing: 16) {
                    // Title and current value display
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(currentText.isEmpty ? " " : currentText)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                    }
                    
                    // Keypad grid
                    VStack(spacing: 12) {
                        ForEach(0..<keyRows.count, id: \.self) { r in
                            HStack(spacing: 12) {
                                ForEach(keyRows[r], id: \.self) { key in
                                    Button { tap(key: key) } label: {
                                        Text(key)
                                            .font(.system(size: 24, weight: .medium))
                                            .frame(width: 80, height: 50)
                                            .background(Color.white.opacity(0.15))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Enter row
                        HStack {
                            Button {
                                // Commit and dismiss
                                onCommit(currentText)
                                onDismiss()
                            } label: {
                                Text("Enter")
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 54)
                                    .background(Color.white.opacity(0.25))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.opacity)
        .zIndex(200)
        .allowsHitTesting(true)
    }
    
    private func tap(key: String) {
        switch key {
        case "⌫":
            if !currentText.isEmpty { currentText.removeLast() }
        case ".":
            if !currentText.contains(".") { currentText.append(".") }
        default:
            // digits
            if key.allSatisfy({ $0.isNumber }) {
                // prevent leading zero spam like "000"
                if currentText == "0" { currentText = key }
                else { currentText.append(contentsOf: key) }
            }
        }
    }
}
