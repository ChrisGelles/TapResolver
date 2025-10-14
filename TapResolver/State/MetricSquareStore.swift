//
//  MetricSquareStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics
import UIKit

// MARK: - Squares Store (map-local positions) + Lock + Persistence
final class MetricSquareStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    @Published var isInteracting: Bool = false

    struct Square: Identifiable, Equatable {
        let id = UUID()
        var color: Color
        var center: CGPoint          // map-local center
        var side: CGFloat            // map-local side length
        var isLocked: Bool = false   // 🔒
        var meters: Double   // Numeric input for side length in meters
    }

    @Published private(set) var squares: [Square] = []
    let maxSquares = 4

    // persistence
    private let squaresKey = "MetricSquares_v1"

    init() {
        load()
    }

    func add(at mapPoint: CGPoint, color: Color) {
        guard squares.count < maxSquares else { return }
        squares.append(Square(color: color, center: mapPoint, side: 80, isLocked: false, meters: 1.00))
        save()
    }

    func remove(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares.remove(at: i)
            save()
        }
    }

    func reset(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = 80
            save()
        }
    }

    func updateCenter(id: UUID, to newCenter: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].center = newCenter
            save()
        }
    }

    func updateSideAndCenter(id: UUID, side: CGFloat, center: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = max(10, side)
            squares[i].center = center
            save()
        }
    }

    func toggleLock(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].isLocked.toggle()
            save()
        }
    }
    
    func updateMeters(for id: UUID, meters: Double) {
        if let idx = squares.firstIndex(where: { $0.id == id }) {
            squares[idx].meters = meters
            save()
        }
    }
    

    // MARK: persistence helpers
    private struct ColorHSBA: Codable {
        var h: CGFloat; var s: CGFloat; var b: CGFloat; var a: CGFloat
    }
    private struct SquareDTO: Codable {
        let id: UUID
        let color: ColorHSBA
        let cx: CGFloat
        let cy: CGFloat
        let side: CGFloat
        let locked: Bool
        let meters: Double
    }

    private func save() {
        let dto = squares.map { sq in
            let ui = UIColor(sq.color)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            return SquareDTO(id: sq.id,
                             color: ColorHSBA(h: h, s: s, b: b, a: a),
                             cx: sq.center.x, cy: sq.center.y,
                             side: sq.side,
                             locked: sq.isLocked,
                             meters: sq.meters)
        }
        ctx.write(squaresKey, value: dto)
    }

    private func load() {
        guard let dto: [SquareDTO] = ctx.read(squaresKey, as: [SquareDTO].self) else {
            return
        }
        self.squares = dto.map { d in
            let color = Color(hue: d.color.h, saturation: d.color.s, brightness: d.color.b, opacity: d.color.a)
            return Square(color: color,
                          center: CGPoint(x: d.cx, y: d.cy),
                          side: d.side,
                          isLocked: d.locked,
                          meters: d.meters)
        }
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    public func clearAndReloadForActiveLocation() {
        squares.removeAll()
        load()
        objectWillChange.send()
    }
    
    func flush() {
        // clear in-memory without saving
        squares.removeAll()
        objectWillChange.send()
    }
}
