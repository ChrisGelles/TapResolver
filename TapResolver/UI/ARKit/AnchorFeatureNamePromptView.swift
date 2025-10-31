//
//  AnchorFeatureNamePromptView.swift
//  TapResolver
//
//  Role: Prompt user to name an anchor feature with autocomplete
//

import SwiftUI

struct AnchorFeatureNamePromptView: View {
    @Binding var featureName: String
    let existingNames: [String]
    let patchID: UUID
    let worldMapStore: ARWorldMapStore
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @State private var showError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Name This Anchor Feature")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Features with the same name link patches together")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Text field
            TextField("e.g., Cat Painting", text: $featureName)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 20)
                .submitLabel(.done)
                .onChange(of: featureName) { _, _ in
                    showError = nil
                }
                .onSubmit {
                    validateAndSave()
                }
            
            // Error message
            if let error = showError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
            
            // Autocomplete suggestions
            if !existingNames.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("💡 Existing features:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(existingNames, id: \.self) { name in
                                Button(action: {
                                    featureName = name
                                    isTextFieldFocused = false
                                }) {
                                    HStack {
                                        Text("🔗 \(name)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("Tap to link")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                }
                                .buttonStyle(.plain)
                                
                                if name != existingNames.last {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
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
                
                Button(action: validateAndSave) {
                    Text("Save Feature")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(featureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.orange)
                        .cornerRadius(10)
                }
                .disabled(featureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func validateAndSave() {
        let trimmed = featureName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            showError = "Feature name cannot be empty"
            return
        }
        
        // Check if already exists in THIS patch
        if worldMapStore.featureExists(named: trimmed, inPatch: patchID) {
            showError = "Feature '\(trimmed)' already exists in this patch"
            return
        }
        
        onSave()
    }
}

