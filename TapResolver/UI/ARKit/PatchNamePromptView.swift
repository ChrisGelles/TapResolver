//
//  PatchNamePromptView.swift
//  TapResolver
//
//  Role: Prompt user to name a world map patch before saving
//

import SwiftUI

struct PatchNamePromptView: View {
    @Binding var patchName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Name This Patch")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Give this AR map section a descriptive name")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Text field
            TextField("e.g., Entrance Hall - West", text: $patchName)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 20)
                .submitLabel(.done)
                .onSubmit {
                    if !patchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave()
                    }
                }
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                
                Button(action: onSave) {
                    Text("Save Patch")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(patchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(patchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .onAppear {
            // Auto-focus text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

