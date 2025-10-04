//
//  DocumentExportPicker.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/3/25.
//


import SwiftUI
import UIKit

/// Presents the iOS Files "Save to" sheet for an existing file URL.
/// The file remains in your sandbox; the picker exports a copy to the user-selected destination.
struct DocumentExportPicker: UIViewControllerRepresentable {
    let fileURL: URL
    let onCompleted: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCompleted: onCompleted) }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear

        DispatchQueue.main.async {
            let picker = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
            picker.delegate = context.coordinator
            picker.modalPresentationStyle = .formSheet
            host.present(picker, animated: true)
        }
        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onCompleted: (Bool) -> Void
        init(onCompleted: @escaping (Bool) -> Void) { self.onCompleted = onCompleted }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true) { self.onCompleted(false) }
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            controller.dismiss(animated: true) { self.onCompleted(true) }
        }
    }
}
