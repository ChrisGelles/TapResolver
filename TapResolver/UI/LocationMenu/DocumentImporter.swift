import SwiftUI
import UniformTypeIdentifiers

struct DocumentImporter: UIViewControllerRepresentable {
    let onFileSelected: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentImporter
        
        init(_ parent: DocumentImporter) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Failed to access security-scoped resource")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            parent.onFileSelected(url)
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    DocumentImporter { url in
        print("Selected file: \(url.lastPathComponent)")
    }
}
