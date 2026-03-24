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

struct DrawingLine: Identifiable, Equatable, Codable {
    let id = UUID()
    var points: [CGPoint]
    var color: CodableColor
    var lineWidth: CGFloat
    var isEraser: Bool = false

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 3, isEraser: Bool = false) {
        self.points = points
        self.color = CodableColor(color)
        self.lineWidth = lineWidth
        self.isEraser = isEraser
    }
}
