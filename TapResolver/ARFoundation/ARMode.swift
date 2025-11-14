import Foundation

enum ARMode: Equatable {
    case idle
    case calibration(mapPointID: UUID)
    case interpolation(firstID: UUID, secondID: UUID)
    case anchor(mapPointID: UUID)
    case metricSquare(squareID: UUID, sideLength: Double)
}

