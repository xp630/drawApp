import SwiftUI

// 形状类型
enum ShapeType: String, CaseIterable, Identifiable, Codable {
    case line = "直线"
    case rectangle = "方形"
    case circle = "圆形"
    case triangle = "三角形"
    case star = "星星"
    case curve = "曲线"
    case polygon = "多边形"
    case arrow = "箭头"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .line: return "line.diagonal"
        case .rectangle: return "square"
        case .circle: return "circle"
        case .triangle: return "triangle"
        case .star: return "star"
        case .curve: return "scribble"
        case .polygon: return "hexagon"
        case .arrow: return "arrow.right"
        }
    }
}

// 画布上的形状实例
struct PlacedShape: Identifiable, Equatable, Codable {
    let id: UUID
    var shapeType: ShapeType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var fillColor: CodableColor
    var strokeColor: CodableColor
    var lineWidth: CGFloat
    var isFilled: Bool

    init(shapeType: ShapeType, startPoint: CGPoint, endPoint: CGPoint, fillColor: Color, strokeColor: Color, lineWidth: CGFloat, isFilled: Bool = false) {
        self.id = UUID()
        self.shapeType = shapeType
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.fillColor = CodableColor(fillColor)
        self.strokeColor = CodableColor(strokeColor)
        self.lineWidth = lineWidth
        self.isFilled = isFilled
    }

    var frame: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }
}
