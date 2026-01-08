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
        ZStack {
            // Only render rose when we have valid data
            if isVisible && sectorData.isValid {
                ZStack {
                    // Rose and labels together, rotating as a unit
                    ZStack {
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
                                    time_s: sectorData.sectorTime_s[i],
                                    isCurrentFacing: sectorData.isValid && i == sectorData.currentSectorIndex
                                )
                                
                                context.fill(wedgePath, with: .color(color))
                                context.stroke(wedgePath, with: .color(.black.opacity(0.3)), lineWidth: 1)
                            }
                            
                            drawCardinalTicks(context: context, center: center, radius: outerRadius)
                        }
                        .frame(width: diameter, height: diameter)
                        
                        // Cardinal direction labels - fixed positions, rotated by parent ZStack
                        let cardinals = [("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)]
                        let centerPt = diameter / 2
                        let labelRadius = diameter * 0.28
                        
                        ForEach(cardinals, id: \.0) { label, cardinalAngle in
                            let baseAngle = cardinalAngle - 90.0  // -90 puts N at top (screen coords)
                            let angleRadians = baseAngle * .pi / 180.0
                            let x = centerPt + labelRadius * CGFloat(cos(angleRadians))
                            let y = centerPt + labelRadius * CGFloat(sin(angleRadians))
                            
                            Text(label)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                                .position(x: x, y: y)
                        }
                    }
                    .rotationEffect(Angle(degrees: -sectorData.currentHeading))
                    
                    // Fixed facing indicator at top
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                        .position(x: diameter / 2, y: 8)
                }
                .frame(width: diameter, height: diameter)
                .drawingGroup()
            }
        }
        // CRITICAL: These modifiers are OUTSIDE the conditional so they always fire
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                startUpdateTimer()
                print("🧭 [FacingRoseHUD] isVisible changed to true - timer started")
            } else {
                stopUpdateTimer()
                print("🧭 [FacingRoseHUD] isVisible changed to false - timer stopped")
            }
        }
        .onAppear {
            if isVisible {
                startUpdateTimer()
                print("🧭 [FacingRoseHUD] onAppear (visible) - timer started")
            }
        }
        .onDisappear {
            stopUpdateTimer()
            print("🧭 [FacingRoseHUD] onDisappear - timer stopped")
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
    
    private func colorForSector(index: Int, time_s: Double, isCurrentFacing: Bool) -> Color {
        if isCurrentFacing {
            return .yellow  // Always highlight current facing
        }
        
        // Time thresholds: 0s = red, <1s = orange, ≥1s = green
        if time_s < 0.001 {
            return Color.red.opacity(0.7)
        } else if time_s < 1.0 {
            return Color.orange.opacity(0.8)
        } else {
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

