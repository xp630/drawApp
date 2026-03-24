import SwiftUI

struct CanvasView: View {
    @Binding var lines: [DrawingLine]
    @Binding var currentColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool

    var onSaveThumbnail: ((UIImage) -> Void)?

    var body: some View {
        Canvas { context, size in
            for line in lines {
                var path = Path()
                if let firstPoint = line.points.first {
                    path.move(to: firstPoint)
                    for point in line.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                context.stroke(
                    path,
                    with: .color(line.isEraser ? .white : line.color),
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
                            lineWidth: lineWidth,
                            isEraser: isEraser
                        )
                        lines.append(newLine)
                    }
                }
        )
        .background(Color.white)
    }
}
