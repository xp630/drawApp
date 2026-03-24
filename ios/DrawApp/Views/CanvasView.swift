import SwiftUI

struct CanvasView: View {
    @Binding var lines: [DrawingLine]
    @Binding var currentColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var brushType: BrushType

    var onSaveThumbnail: ((UIImage) -> Void)?

    var body: some View {
        Canvas { context, size in
            for line in lines {
                var path = Path()
                if let firstPoint = line.points.first {
                    path.move(to: firstPoint)
                    if line.points.count >= 3 {
                        // Use quadratic curve for smoothness
                        for i in 1..<line.points.count - 1 {
                            let current = line.points[i]
                            let next = line.points[i + 1]
                            let midPoint = CGPoint(
                                x: (current.x + next.x) / 2,
                                y: (current.y + next.y) / 2
                            )
                            path.addQuadCurve(to: midPoint, control: current)
                        }
                        // Connect to last point
                        if let last = line.points.last {
                            path.addLine(to: last)
                        }
                    } else {
                        for point in line.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                let opacity = line.isEraser ? 1.0 : line.brushType.opacity
                context.stroke(
                    path,
                    with: .color(line.isEraser ? Color.white : line.color.color.opacity(opacity)),
                    style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    if let lastLine = lines.last, lastLine.id == lines.last?.id {
                        var newLines = lines
                        if newLines[newLines.count - 1].points.last == point {
                            return
                        }
                        newLines[newLines.count - 1].points.append(point)
                        lines = newLines
                    } else {
                        let newLine = DrawingLine(
                            points: [point],
                            color: currentColor,
                            lineWidth: brushType.lineWidth,
                            brushType: brushType,
                            isEraser: isEraser
                        )
                        lines.append(newLine)
                    }
                }
        )
        .background(Color.white)
    }
}
