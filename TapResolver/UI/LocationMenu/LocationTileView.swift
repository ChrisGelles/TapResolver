import SwiftUI

struct LocationTileView: View {
    let summary: LocationSummary
    let onTap: () -> Void
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                ZStack {
                    if let image = thumbnailImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Name
                Text(summary.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Updated date
                Text(formatDate(summary.updatedISO))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename") {
                // TODO: Implement rename
                print("Rename location: \(summary.id)")
            }
            
            Button("Duplicate") {
                // TODO: Implement duplicate
                print("Duplicate location: \(summary.id)")
            }
            
            Button("Delete", role: .destructive) {
                // TODO: Implement delete
                print("Delete location: \(summary.id)")
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let image = UIImage(contentsOfFile: summary.thumbnailURL.path) else {
            return
        }
        thumbnailImage = image
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "Unknown"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

#Preview {
    LocationTileView(
        summary: LocationSummary(
            id: "preview",
            name: "Sample Location",
            updatedISO: "2025-09-27T19:00:00Z",
            thumbnailURL: URL(fileURLWithPath: "/tmp/placeholder.jpg"),
            displaySize: CGSize(width: 800, height: 600)
        )
    ) {
        print("Tapped preview tile")
    }
    .padding()
    .background(Color.black)
}
