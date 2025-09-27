import SwiftUI

struct LocationMenuViewPlaceholder: View {
    @EnvironmentObject var locationManager: LocationManager
    var body: some View {
        VStack(spacing: 16) {
            Text("Location Menu (coming soon)").font(.headline)
            Button("Back to Map") { locationManager.showLocationMenu = false }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }
}
