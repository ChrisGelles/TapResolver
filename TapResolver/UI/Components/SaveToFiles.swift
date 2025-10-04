//
//  SaveToFiles.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/3/25.
//
import SwiftUI
import UIKit

/// Presents the iOS Files save dialog and exports the provided data as a copy.
/// Writes the data to a temporary file first, then offers it to the user to pick a destination.
/// - Parameters:
///   - data: The bytes to export.
///   - suggestedFileName: A filename suggestion (e.g., "scan_record_2025-10-03T18-35-12Z.json").
///   - onCompleted: Called with `true` if the user completed the export, `false` if cancelled or failed.
struct SaveToFilesPicker: UIViewControllerRepresentable {
    let data: Data
    let suggestedFileName: String
    let onCompleted: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCompleted: onCompleted) }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .clear

        DispatchQueue.main.async {
            // 1) Write to a temp file (so the picker can export a file URL)
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFileName)
            do {
                try data.write(to: tmpURL, options: .atomic)
            } catch {
                onCompleted(false)
                return
            }

            // 2) Present the standard Files "Save to" sheet
            let picker = UIDocumentPickerViewController(forExporting: [tmpURL], asCopy: true)
            context.coordinator.cleanupURL = tmpURL
            picker.delegate = context.coordinator
            picker.modalPresentationStyle = .formSheet
            host.present(picker, animated: true)
        }

        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onCompleted: (Bool) -> Void
        var cleanupURL: URL?

        init(onCompleted: @escaping (Bool) -> Void) { self.onCompleted = onCompleted }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            if let url = cleanupURL { try? FileManager.default.removeItem(at: url) }
            controller.dismiss(animated: true) { self.onCompleted(false) }
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = cleanupURL { try? FileManager.default.removeItem(at: url) }
            controller.dismiss(animated: true) { self.onCompleted(true) }
        }
    }
}

/// A tiny SwiftUI wrapper that shows a button and, when tapped,
/// encodes a `MapPointScanUtility.ScanRecord` to JSON and presents the Files picker.
/// It uses the **same JSON encoder settings** as your current persistence logic.
struct SaveToFilesButton: View {
    let record: MapPointScanUtility.ScanRecord
    var onComplete: (Bool) -> Void = { _ in }

    @State private var showPicker = false
    @State private var exportData: Data?
    @State private var suggestedName = "scan_record.json"

    var body: some View {
        Button("Export Last Scan JSON") {
            // Mirror MapPointScanPersistence encoder settings (pretty + stable sort + ISO 8601)
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601

            do {
                exportData = try enc.encode(record)
                let base = record.scanID.isEmpty
                    ? ISO8601DateFormatter().string(from: Date())
                    : record.scanID
                suggestedName = "scan_record_\(base.replacingOccurrences(of: ":", with: "-")).json"
                showPicker = true
            } catch {
                onComplete(false)
            }
        }
        .sheet(isPresented: $showPicker) {
            if let data = exportData {
                SaveToFilesPicker(
                    data: data,
                    suggestedFileName: suggestedName,
                    onCompleted: { success in
                        onComplete(success)
                    }
                )
            }
        }
    }
}
