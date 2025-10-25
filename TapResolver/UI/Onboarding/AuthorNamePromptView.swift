//
//  AuthorNamePromptView.swift
//  TapResolver
//
//  First-launch prompt for author name
//

import SwiftUI

struct AuthorNamePromptView: View {
    @Binding var isPresented: Bool
    @State private var authorName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Welcome to TapResolver!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("What's your name?")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Your Name", text: $authorName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
                Text("This will be used to identify your work when sharing location data.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("You can change this later in Settings.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
                
                Button(action: {
                    saveAndDismiss()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(authorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(authorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }
    
    private func saveAndDismiss() {
        let trimmedName = authorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        AppSettings.authorName = trimmedName
        AppSettings.hasCompletedOnboarding = true
        
        print("✅ Author name set: \(trimmedName)")
        isPresented = false
    }
}

#Preview {
    AuthorNamePromptView(isPresented: .constant(true))
}

