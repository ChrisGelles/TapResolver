import SwiftUI

struct NewMapTileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Square area with plus icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                
                Image(systemName: "plus")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundColor(.white.opacity(0.6))
            )
            .shadow(radius: 4, y: 2)
            
            // Text below the square
            Text("New Map")
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    NewMapTileView()
        .padding()
        .background(Color.black)
}
