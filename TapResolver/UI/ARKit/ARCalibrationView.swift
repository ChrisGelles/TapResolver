import SwiftUI

struct ARCalibrationView: View {
    @Binding var isPresented: Bool
    @State private var currentMode: ARMode = .idle

    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(mode: $currentMode)
                .edgesIgnoringSafeArea(.all)

            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding(.top, 50) // Push down past notch
                    .padding(.leading, 16)
            }

            VStack {
                Spacer()
                Button("Enter Calibration Mode") {
                    currentMode = .calibration(mapPointID: UUID())
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding()
            }
        }
        .onDisappear {
            // Clear AR Mode & Coordinator State on Exit
            currentMode = .idle
            print("🧹 ARCalibrationView: Cleaned up on disappear")
        }
    }
}
