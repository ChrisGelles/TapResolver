//
//  FacingRoseHUD.swift
//  TapResolver
//
//  Displays 8-sector compass rose during Survey Marker dwell
//  Shows which facing directions have accumulated BLE data
//

import SwiftUI

struct FacingRoseHUD: View {
    @EnvironmentObject private var surveySessionCollector: SurveySessionCollector
    
    /// Controls visibility - bound to dwell state from parent
    let isVisible: Bool
    
    // MARK: - Configuration
    private let diameter: CGFloat = 120
    private let innerRadiusRatio: CGFloat = 0.55  // 55% hollow center
    private let updateInterval: TimeInterval = 0.125  // 8 Hz
    
    // MARK: - State
    @State private var sectorData: FacingSectorSnapshot = .empty
    @State private var updateTimer: Timer?
    
    var body: some View {
        if isVisible {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outerRadius = min(size.width, size.height) / 2
                let innerRadius = outerRadius * innerRadiusRatio
                
                // Draw 8 wedges
                for i in 0..<8 {
                    let startAngle = Angle(degrees: Double(i) * 45.0 - 90.0 - 22.5)
                    let endAngle = Angle(degrees: Double(i) * 45.0 - 90.0 + 22.5)
                    
                    let wedgePath = createWedgePath(
                        center: center,
                        innerRadius: innerRadius,
                        outerRadius: outerRadius,
                        startAngle: startAngle,
                        endAngle: endAngle
                    )
                    
                    let color = colorForSector(
                        index: i,
                        hitCount: sectorData.sectorHitCounts[i],
                        isCurrentFacing: sectorData.isValid && i == sectorData.currentSectorIndex
                    )
                    
                    context.fill(wedgePath, with: .color(color))
                    
                    // Subtle border between wedges
                    context.stroke(wedgePath, with: .color(.black.opacity(0.3)), lineWidth: 1)
                }
                
                // Draw cardinal direction indicators (small ticks)
                drawCardinalTicks(context: context, center: center, radius: outerRadius)
                
            }
            .frame(width: diameter, height: diameter)
            .drawingGroup() // Flatten for compositor efficiency
            .onAppear {
                startUpdateTimer()
                // DIAGNOSTIC: Uncomment to confirm HUD activation
                print("🧭 [FacingRoseHUD] Visible - timer started")
            }
            .onDisappear {
                stopUpdateTimer()
                // DIAGNOSTIC: Uncomment to confirm HUD deactivation
                print("🧭 [FacingRoseHUD] Hidden - timer stopped")
            }
        }
    }
    
    // MARK: - Wedge Path Construction
    
    private func createWedgePath(
        center: CGPoint,
        innerRadius: CGFloat,
        outerRadius: CGFloat,
        startAngle: Angle,
        endAngle: Angle
    ) -> Path {
        var path = Path()
        
        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // Line to inner arc end point
        let innerEndX = center.x + innerRadius * CGFloat(cos(endAngle.radians))
        let innerEndY = center.y + innerRadius * CGFloat(sin(endAngle.radians))
        path.addLine(to: CGPoint(x: innerEndX, y: innerEndY))
        
        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        
        // Close path back to outer arc start
        path.closeSubpath()
        
        return path
    }
    
    // MARK: - Cardinal Direction Ticks
    
    private func drawCardinalTicks(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let tickLength: CGFloat = 6
        let cardinals = [0, 90, 180, 270] // N, E, S, W in screen coordinates
        
        for angle in cardinals {
            let radians = Double(angle - 90) * .pi / 180 // -90 to put N at top
            let outerPoint = CGPoint(
                x: center.x + (radius + 2) * CGFloat(cos(radians)),
                y: center.y + (radius + 2) * CGFloat(sin(radians))
            )
            let innerPoint = CGPoint(
                x: center.x + (radius + 2 + tickLength) * CGFloat(cos(radians)),
                y: center.y + (radius + 2 + tickLength) * CGFloat(sin(radians))
            )
            
            var tickPath = Path()
            tickPath.move(to: outerPoint)
            tickPath.addLine(to: innerPoint)
            
            context.stroke(tickPath, with: .color(.white.opacity(0.8)), lineWidth: 2)
        }
    }
    
    // MARK: - Color Logic
    
    private func colorForSector(index: Int, hitCount: Int, isCurrentFacing: Bool) -> Color {
        if isCurrentFacing {
            return .yellow  // Always highlight current facing
        }
        
        switch hitCount {
        case 0:
            return Color.red.opacity(0.7)
        case 1...2:
            return Color.orange.opacity(0.8)
        default:
            return Color.green.opacity(0.9)
        }
    }
    
    // MARK: - Update Timer
    
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            sectorData = surveySessionCollector.getFacingSectorData()
        }
        // Immediate first update
        sectorData = surveySessionCollector.getFacingSectorData()
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        sectorData = .empty
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                FacingRoseHUD(isVisible: true)
                    .environmentObject(SurveySessionCollector())
                    .padding(20)
                Spacer()
            }
        }
    }
}

