import SwiftUI

struct DrawingLine: Identifiable, Equatable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool = false

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 3, isEraser: Bool = false) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.isEraser = isEraser
    }
}
