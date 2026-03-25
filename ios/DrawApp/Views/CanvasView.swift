import SwiftUI

struct CanvasView: View {
    @Binding var lines: [DrawingLine]
    @Binding var currentColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var brushType: BrushType
    @Binding var placedStickers: [PlacedSticker]
    @Binding var placedShapes: [PlacedShape]
    @Binding var selectedShapeType: ShapeType?
    var canvasStyle: CanvasStyle = .normal

    var onSaveThumbnail: ((UIImage) -> Void)?

    @State private var isDrawing: Bool = false
    @State private var selectedSticker: Sticker?
    @State private var dragPosition: CGPoint = .zero
    @State private var stickerScale: CGFloat = 1.0
    @State private var stickerRotation: Double = 0
    @State private var shapeStartPoint: CGPoint?
    @State private var shapeEndPoint: CGPoint?

    var body: some View {
        ZStack {
            // 画布背景
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
                    // 根据风格计算最终颜色
                    let brushOpacity = line.brushType.opacity
                    let styleOpacity = canvasStyle.lineOpacity
                    let finalOpacity = line.brushType.isEraser ? 1.0 : brushOpacity * styleOpacity

                    // 素描风格：线条变灰色，模拟铅笔效果
                    let strokeColor: Color
                    if line.brushType.isEraser {
                        strokeColor = Color.white
                    } else if canvasStyle == .sketch {
                        // 素描模式：将颜色转换为灰色系（保留透明度变化）
                        let gray = line.color.grayLevel
                        strokeColor = Color(white: gray).opacity(styleOpacity)
                    } else {
                        strokeColor = line.color.color.opacity(finalOpacity)
                    }

                    // 刷子效果：绘制多条错位线条模拟拉丝
                    if line.brushType == .brush && !line.brushType.isEraser {
                        let bristleCount = 5
                        let offsetAmount = line.lineWidth * 0.3
                        for i in 0..<bristleCount {
                            var bristlePath = Path()
                            let yOffset = CGFloat(i - bristleCount / 2) * offsetAmount
                            if let firstPoint = line.points.first {
                                bristlePath.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y + yOffset))
                                if line.points.count >= 3 {
                                    for j in 1..<line.points.count - 1 {
                                        let current = line.points[j]
                                        let next = line.points[j + 1]
                                        let midPoint = CGPoint(
                                            x: (current.x + next.x) / 2,
                                            y: (current.y + next.y) / 2 + yOffset
                                        )
                                        bristlePath.addQuadCurve(to: midPoint, control: CGPoint(x: current.x, y: current.y + yOffset))
                                    }
                                    if let last = line.points.last {
                                        bristlePath.addLine(to: CGPoint(x: last.x, y: last.y + yOffset))
                                    }
                                } else {
                                    for point in line.points.dropFirst() {
                                        bristlePath.addLine(to: CGPoint(x: point.x, y: point.y + yOffset))
                                    }
                                }
                            }
                            // 每根刷丝的透明度略有不同
                            let bristleOpacity = finalOpacity * (0.6 + Double(i) * 0.1)
                            context.stroke(
                                bristlePath,
                                with: .color(strokeColor.opacity(bristleOpacity)),
                                style: StrokeStyle(lineWidth: line.lineWidth * 0.6, lineCap: .round, lineJoin: .round)
                            )
                        }
                    } else {
                        context.stroke(
                            path,
                            with: .color(strokeColor),
                            style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
            }

            // 渲染已放置的贴纸
            ForEach(placedStickers) { sticker in
                Image(systemName: sticker.systemName)
                    .font(.system(size: 50 * sticker.scale))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(sticker.rotation))
                    .position(sticker.position)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let index = placedStickers.firstIndex(where: { $0.id == sticker.id }) {
                                    placedStickers[index].position = value.location
                                }
                            }
                    )
                    .onLongPressGesture {
                        // 删除贴纸
                        if let index = placedStickers.firstIndex(where: { $0.id == sticker.id }) {
                            placedStickers.remove(at: index)
                        }
                    }
            }

            // 渲染已放置的形状
            ForEach(placedShapes) { shape in
                ShapeView(shape: shape)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let index = placedShapes.firstIndex(where: { $0.id == shape.id }) {
                                    let dx = value.translation.width
                                    let dy = value.translation.height
                                    placedShapes[index].startPoint = CGPoint(x: shape.startPoint.x + dx, y: shape.startPoint.y + dy)
                                    placedShapes[index].endPoint = CGPoint(x: shape.endPoint.x + dx, y: shape.endPoint.y + dy)
                                }
                            }
                    )
                    .onLongPressGesture {
                        // 删除形状
                        if let index = placedShapes.firstIndex(where: { $0.id == shape.id }) {
                            placedShapes.remove(at: index)
                        }
                    }
            }

            // 当前绘制中的形状预览
            if let start = shapeStartPoint, let end = shapeEndPoint, let shapeType = selectedShapeType {
                ShapePreview(shapeType: shapeType, startPoint: start, endPoint: end, color: currentColor, lineWidth: lineWidth)
            }

            // 当前拖拽的贴纸预览
            if let sticker = selectedSticker {
                Image(systemName: sticker.systemName)
                    .font(.system(size: 50 * stickerScale))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(stickerRotation))
                    .position(dragPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragPosition = value.location
                            }
                            .onEnded { value in
                                let newSticker = PlacedSticker(
                                    sticker: sticker,
                                    position: value.location
                                )
                                placedStickers.append(newSticker)
                                selectedSticker = nil
                                dragPosition = .zero
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                stickerScale = value
                            }
                    )
                    .gesture(
                        RotationGesture()
                            .onChanged { value in
                                stickerRotation = value.degrees
                            }
                    )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // 只有在没有选中贴纸时才绘制
                    guard selectedSticker == nil else { return }

                    let point = value.location

                    // 如果选择了形状工具
                    if let shapeType = selectedShapeType {
                        if shapeStartPoint == nil {
                            shapeStartPoint = point
                            shapeEndPoint = point
                        } else {
                            shapeEndPoint = point
                        }
                        return
                    }

                    // 普通绘制
                    if isDrawing, let lastLine = lines.last, lastLine.id == lines.last?.id {
                        // Continue current line
                        var newLines = lines
                        if newLines[newLines.count - 1].points.last == point {
                            return
                        }
                        newLines[newLines.count - 1].points.append(point)
                        lines = newLines
                    } else {
                        // Start a new line
                        isDrawing = true
                        let newLine = DrawingLine(
                            points: [point],
                            color: currentColor,
                            lineWidth: lineWidth,
                            brushType: brushType,
                            isEraser: brushType.isEraser
                        )
                        lines.append(newLine)
                    }
                }
                .onEnded { _ in
                    // 如果有形状工具选中，结束时创建形状
                    if let shapeType = selectedShapeType, let start = shapeStartPoint, let end = shapeEndPoint {
                        let newShape = PlacedShape(
                            shapeType: shapeType,
                            startPoint: start,
                            endPoint: end,
                            fillColor: .white,
                            strokeColor: currentColor,
                            lineWidth: lineWidth,
                            isFilled: false
                        )
                        placedShapes.append(newShape)
                        shapeStartPoint = nil
                        shapeEndPoint = nil
                        // 清除形状选择
                        selectedShapeType = nil
                    }
                    isDrawing = false
                }
        )
        .background(canvasStyle.backgroundColor)
    }

    func addSticker(_ sticker: Sticker) {
        selectedSticker = sticker
        stickerScale = 1.0
        stickerRotation = 0
    }
}

// 形状视图
struct ShapeView: View {
    let shape: PlacedShape

    private var strokeColor: Color {
        shape.strokeColor.color
    }

    private var frameWidth: CGFloat {
        shape.frame.width
    }

    private var frameHeight: CGFloat {
        shape.frame.height
    }

    private var midX: CGFloat {
        shape.frame.midX
    }

    private var midY: CGFloat {
        shape.frame.midY
    }

    var body: some View {
        switch shape.shapeType {
        case .line:
            LineShape(start: shape.startPoint, end: shape.endPoint)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round))

        case .rectangle:
            Rectangle()
                .stroke(strokeColor, lineWidth: shape.lineWidth)
                .frame(width: frameWidth, height: frameHeight)
                .position(x: midX, y: midY)

        case .circle:
            Ellipse()
                .stroke(strokeColor, lineWidth: shape.lineWidth)
                .frame(width: frameWidth, height: frameHeight)
                .position(x: midX, y: midY)

        case .triangle:
            TriangleShape(frame: shape.frame)
                .stroke(strokeColor, lineWidth: shape.lineWidth)

        case .star:
            StarShape(frame: shape.frame)
                .stroke(strokeColor, lineWidth: shape.lineWidth)

        case .curve:
            CurveShape(start: shape.startPoint, end: shape.endPoint)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round))

        case .polygon:
            PolygonShape(frame: shape.frame, sides: 6)
                .stroke(strokeColor, lineWidth: shape.lineWidth)

        case .arrow:
            ArrowShape(start: shape.startPoint, end: shape.endPoint)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

// 直线形状
struct LineShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// 三角形形状
struct TriangleShape: Shape {
    let frame: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: frame.midX, y: frame.minY))
        path.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
        path.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))
        path.closeSubpath()
        return path
    }
}

// 星星形状
struct StarShape: Shape {
    let frame: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = 5
        let outerRadius = min(frame.width, frame.height) / 2
        let innerRadius = outerRadius * 0.4
        let center = CGPoint(x: frame.midX, y: frame.midY)

        for i in 0..<points * 2 {
            let radius: CGFloat = i % 2 == 0 ? outerRadius : innerRadius
            let angle: CGFloat = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * Darwin.cos(angle),
                y: center.y + radius * Darwin.sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// 曲线形状
struct CurveShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        let controlPoint1 = CGPoint(x: start.x + (end.x - start.x) * 0.5, y: start.y)
        let controlPoint2 = CGPoint(x: start.x + (end.x - start.x) * 0.5, y: end.y)
        path.addCurve(to: end, control1: controlPoint1, control2: controlPoint2)
        return path
    }
}

// 多边形形状
struct PolygonShape: Shape {
    let frame: CGRect
    let sides: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let radius = min(frame.width, frame.height) / 2

        for i in 0..<sides {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(sides) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * Darwin.cos(angle),
                y: center.y + radius * Darwin.sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// 箭头形状
struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 主线
        path.move(to: start)
        path.addLine(to: end)

        // 箭头头部
        let arrowLength: CGFloat = 20
        let arrowAngle: CGFloat = .pi / 6

        let angle = Darwin.atan2(end.y - start.y, end.x - start.x)

        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * Darwin.cos(angle - arrowAngle),
            y: end.y - arrowLength * Darwin.sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * Darwin.cos(angle + arrowAngle),
            y: end.y - arrowLength * Darwin.sin(angle + arrowAngle)
        )

        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)

        return path
    }
}

// 形状预览
struct ShapePreview: View {
    let shapeType: ShapeType
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: Color
    let lineWidth: CGFloat

    private var frame: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }

    var body: some View {
        switch shapeType {
        case .line:
            LineShape(start: startPoint, end: endPoint)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

        case .rectangle:
            Rectangle()
                .stroke(color, lineWidth: lineWidth)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

        case .circle:
            Ellipse()
                .stroke(color, lineWidth: lineWidth)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)

        case .triangle:
            TriangleShape(frame: frame)
                .stroke(color, lineWidth: lineWidth)

        case .star:
            StarShape(frame: frame)
                .stroke(color, lineWidth: lineWidth)

        case .curve:
            CurveShape(start: startPoint, end: endPoint)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

        case .polygon:
            PolygonShape(frame: frame, sides: 6)
                .stroke(color, lineWidth: lineWidth)

        case .arrow:
            ArrowShape(start: startPoint, end: endPoint)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}
