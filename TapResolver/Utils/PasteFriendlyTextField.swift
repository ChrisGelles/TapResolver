//
//  PasteFriendlyTextField.swift
//  KBeaconSettings
//
//  UIKit-backed TextField with rock-solid paste menu
//

import SwiftUI

struct PasteFriendlyTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var contentType: UITextContentType? = nil
    
    final class Field: UITextField {
        // Prevent gesture recognizers from interfering
        override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow long press for paste menu
            return true
        }
        
        // Keep first responder status stable
        override var canBecomeFirstResponder: Bool { true }
        
        // Explicitly allow paste and other editing actions
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            switch action {
            case #selector(paste(_:)):
                return UIPasteboard.general.hasStrings
            case #selector(cut(_:)), #selector(copy(_:)), #selector(selectAll(_:)):
                return true
            default:
                return super.canPerformAction(action, withSender: sender)
            }
        }
        
        // Prevent menu dismissal during touch handling
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
        }
    }
    
    func makeUIView(context: Context) -> Field {
        let tf = Field()
        tf.delegate = context.coordinator
        tf.placeholder = placeholder
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.textContentType = contentType
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.borderStyle = .none
        tf.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        
        // Critical: Use .editingChanged instead of target-action to avoid async issues
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textFieldChanged(_:)), for: .editingChanged)
        
        // Ensure menu interaction works
        tf.isUserInteractionEnabled = true
        
        return tf
    }
    
    func updateUIView(_ uiView: Field, context: Context) {
        // Only update if text actually differs to prevent layout thrashing
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textFieldChanged(_ textField: UITextField) {
            // Update binding WITHOUT async dispatch to prevent menu dismissal
            // SwiftUI can handle synchronous binding updates during editing
            text = textField.text ?? ""
        }
        
        // Optional: Prevent return key from dismissing
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

