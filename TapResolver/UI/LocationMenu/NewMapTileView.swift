import SwiftUI

struct NewMapTileView: View {
    var body: some View {
        VStack(spacing: 12) {
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.8))
            
            // "New Map" text
            Text("New Map")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [8, 4]
                    )
                )
                .foregroundColor(.white.opacity(0.6))
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    NewMapTileView()
        .padding()
        .background(Color.black)
}
