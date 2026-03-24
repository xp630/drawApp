import SwiftUI

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum BrushType: String, CaseIterable, Codable {
    case pencil = "铅笔"
    case pen = "钢笔"
    case brush = "刷子"

    var icon: String {
        switch self {
        case .pencil: return "pencil"
        case .pen: return "pencil.tip"
        case .brush: return "paintbrush.fill"
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .pencil: return 2
        case .pen: return 3
        case .brush: return 8
        }
    }

    var opacity: Double {
        switch self {
        case .pencil: return 0.8
        case .pen: return 1.0
        case .brush: return 0.6
        }
    }
}

struct DrawingLine: Identifiable, Equatable, Codable {
    let id = UUID()
    var points: [CGPoint]
    var color: CodableColor
    var lineWidth: CGFloat
    var brushType: BrushType
    var isEraser: Bool = false

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 3, brushType: BrushType = .pen, isEraser: Bool = false) {
        self.points = points
        self.color = CodableColor(color)
        self.lineWidth = lineWidth
        self.brushType = brushType
        self.isEraser = isEraser
    }
}
