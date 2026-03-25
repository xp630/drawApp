import SwiftUI

// 画布风格
enum CanvasStyle: String, CaseIterable {
    case normal = "彩色"
    case sketch = "素描"

    var backgroundColor: Color {
        switch self {
        case .normal: return .white
        case .sketch: return Color(white: 0.93)
        }
    }

    var lineOpacity: Double {
        switch self {
        case .normal: return 1.0
        case .sketch: return 0.65
        }
    }

    var description: String {
        switch self {
        case .normal: return "标准绘画效果"
        case .sketch: return "灰色调铅笔画效果"
        }
    }
}

struct ContentView: View {
    @State private var lines: [DrawingLine] = []
    @State private var currentColor: Color = .black
    @State private var lineWidth: CGFloat = 3
    @State private var brushType: BrushType = .pen
    @State private var canvasStyle: CanvasStyle = .normal

    @State private var showDraftBox: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showStylePicker: Bool = false
    @State private var showStickerPicker: Bool = false
    @State private var showFramePicker: Bool = false
    @State private var showShapePicker: Bool = false

    @State private var placedStickers: [PlacedSticker] = []
    @State private var selectedFrame: FrameType = .none
    @State private var placedShapes: [PlacedShape] = []
    @State private var selectedShapeType: ShapeType?

    @State private var autoSaveEnabled: Bool = true
    @StateObject private var draftStorage = DraftStorage.shared

    private let autoSaveInterval: TimeInterval = 30
    @State private var lastSavedLines: [DrawingLine] = []

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // ========== 顶部栏 ==========
                TopToolbar(
                    onNew: { lines = [] },
                    onSave: { saveDraft() },
                    onUndo: { if !lines.isEmpty { lines.removeLast() } },
                    onExport: { exportImage() },
                    onSettings: { /* 待实现 */ }
                )
                .frame(height: 60)

                // ========== 中央画布 ==========
                ZStack {
                    CanvasView(
                        lines: $lines,
                        currentColor: $currentColor,
                        lineWidth: $lineWidth,
                        brushType: $brushType,
                        placedStickers: $placedStickers,
                        placedShapes: $placedShapes,
                        selectedShapeType: $selectedShapeType,
                        canvasStyle: canvasStyle,
                        onSaveThumbnail: { image in
                            _ = draftStorage.saveDraft(lines: lines, thumbnail: image)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canvasStyle.backgroundColor)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(8)

                    // 相框
                    if selectedFrame != .none {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: selectedFrame.frameColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selectedFrame.frameWidth
                            )
                            .padding(8)
                    }

                    // 右上角草稿箱按钮
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showDraftBox = true
                            } label: {
                                Image(systemName: "folder")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                    .padding(10)
                                    .background(Color(UIColor.systemGray6).opacity(0.9))
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }

                // ========== 底部工具栏 ==========
                BottomToolbar(
                    selectedColor: $currentColor,
                    lineWidth: $lineWidth,
                    brushType: $brushType,
                    showColorPicker: $showColorPicker,
                    showStylePicker: $showStylePicker,
                    showStickerPicker: $showStickerPicker,
                    showFramePicker: $showFramePicker,
                    showShapePicker: $showShapePicker,
                    canvasStyle: canvasStyle,
                    onUndo: { if !lines.isEmpty { lines.removeLast() } },
                    onExport: { exportImage() }
                )
                .frame(height: 100)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .sheet(isPresented: $showDraftBox) {
            DraftBoxView(
                isPresented: $showDraftBox,
                autoSaveEnabled: $autoSaveEnabled,
                onSelectDraft: { draft in
                    lines = draftStorage.loadDrawingData(for: draft)
                },
                onNewCanvas: {
                    lines = []
                }
            )
            .environmentObject(draftStorage)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $currentColor, isPresented: $showColorPicker)
        }
        .sheet(isPresented: $showStylePicker) {
            StylePickerView(canvasStyle: $canvasStyle, isPresented: $showStylePicker)
        }
        .sheet(isPresented: $showStickerPicker) {
            StickerView(isPresented: $showStickerPicker) { sticker in
                let centerSticker = PlacedSticker(sticker: sticker, position: CGPoint(x: 400, y: 300))
                placedStickers.append(centerSticker)
            }
        }
        .sheet(isPresented: $showFramePicker) {
            FramePickerView(selectedFrame: $selectedFrame, isPresented: $showFramePicker)
        }
        .sheet(isPresented: $showShapePicker) {
            ShapePickerView(isPresented: $showShapePicker) { shape in
                selectedShapeType = shape
            }
        }
        .onAppear {
            startAutoSave()
        }
    }

    private func startAutoSave() {
        Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            guard self.autoSaveEnabled else { return }
            if self.lines != self.lastSavedLines {
                self.saveThumbnail()
            }
        }
    }

    private func saveThumbnail() {
        guard !lines.isEmpty else { return }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))

            for line in lines {
                let path = UIBezierPath()
                if let firstPoint = line.points.first {
                    path.move(to: firstPoint)
                    for point in line.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                path.lineWidth = line.lineWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                (line.isEraser ? UIColor.white : UIColor(line.color.color)).setStroke()
                path.stroke()
            }
        }
        _ = draftStorage.saveDraft(lines: lines, thumbnail: image)
        lastSavedLines = lines
    }

    private func saveDraft() {
        saveThumbnail()
    }

    private func exportImage() {
        guard !lines.isEmpty || !placedStickers.isEmpty else { return }

        let canvasWidth: CGFloat = UIScreen.main.bounds.width - 40
        let canvasHeight: CGFloat = UIScreen.main.bounds.height - 160
        let canvasSize = CGSize(width: canvasWidth, height: canvasHeight)

        let image = ExportService.shared.renderCanvasToImage(
            lines: lines,
            placedStickers: placedStickers,
            canvasSize: canvasSize,
            backgroundColor: canvasStyle.backgroundColor,
            showFrame: selectedFrame != .none,
            frameType: selectedFrame
        )

        ExportService.shared.saveToPhotoLibrary(image: image) { success, error in
            if success {
                SoundService.shared.playExportSuccessSound()
                print("图片已保存到相册")
            } else if let error = error {
                print("保存失败: \(error.localizedDescription)")
            }
        }
    }
}

// ========== 顶部栏 ==========
struct TopToolbar: View {
    let onNew: () -> Void
    let onSave: () -> Void
    let onUndo: () -> Void
    let onExport: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：新建设置
            HStack(spacing: 12) {
                TopBarButton(icon: "doc.badge.plus", label: "新建") {
                    onNew()
                }
                TopBarButton(icon: "folder", label: "草稿箱") {
                    // 打开草稿箱
                }
            }

            Spacer()

            // 中间：撤销
            HStack(spacing: 12) {
                TopBarButton(icon: "arrow.uturn.backward", label: "撤销") {
                    onUndo()
                }
            }

            Spacer()

            // 右侧：导出/设置
            HStack(spacing: 12) {
                TopBarButton(icon: "square.and.arrow.down", label: "导出") {
                    onExport()
                }
                TopBarButton(icon: "gearshape", label: "设置") {
                    onSettings()
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(Color(UIColor.systemBackground))
    }
}

struct TopBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(.primary)
            .frame(minWidth: 50)
        }
    }
}

// ========== 底部工具栏 ==========
struct BottomToolbar: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var brushType: BrushType
    @Binding var showColorPicker: Bool
    @Binding var showStylePicker: Bool
    @Binding var showStickerPicker: Bool
    @Binding var showFramePicker: Bool
    @Binding var showShapePicker: Bool
    var canvasStyle: CanvasStyle
    let onUndo: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 颜色选择
            Button {
                showColorPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 48, height: 48)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 48, height: 48)
                }
            }
            .padding(.horizontal, 12)

            Divider()
                .frame(height: 50)

            // 画笔类型
            HStack(spacing: 8) {
                ForEach(BrushType.allCases, id: \.self) { type in
                    BottomBrushButton(type: type, selectedType: $brushType)
                }
            }
            .padding(.horizontal, 12)

            Divider()
                .frame(height: 50)

            // 粗细滑块
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.pink.opacity(0.5))
                    .frame(width: 6, height: 6)
                Slider(value: $lineWidth, in: 1...30, step: 1)
                    .frame(width: 100)
                    .tint(.pink)
                Circle()
                    .fill(Color.pink.opacity(0.5))
                    .frame(width: 18, height: 18)
            }
            .padding(.horizontal, 12)

            Divider()
                .frame(height: 50)

            // 特效区域
            HStack(spacing: 8) {
                BottomToolButton(icon: "star.fill", color: .yellow) {
                    showStickerPicker = true
                }
                BottomToolButton(icon: "square.on.circle", color: .blue) {
                    showShapePicker = true
                }
                BottomToolButton(icon: "sparkles", color: .purple) {
                    showStylePicker = true
                }
                BottomToolButton(icon: "square.dashed", color: .orange) {
                    showFramePicker = true
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 100)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
        )
    }
}

struct BottomBrushButton: View {
    let type: BrushType
    @Binding var selectedType: BrushType

    var isSelected: Bool { selectedType == type }

    private var brushColor: Color {
        switch type {
        case .pencil: return .gray
        case .pen: return .blue
        case .brush: return .orange
        case .eraser: return .pink
        }
    }

    var body: some View {
        Button {
            selectedType = type
            SoundService.shared.playToolSelectSound()
        } label: {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : brushColor)
                .frame(width: 48, height: 48)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(LinearGradient(colors: [brushColor, brushColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: brushColor.opacity(0.4), radius: 3, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                )
        }
    }
}

struct BottomToolButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                )
        }
    }
}

// 装饰背景
struct DecorativeBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.05),
                            Color.purple.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -50, y: geometry.size.height - 100)
        }
    }
}

// Color Picker Sheet
struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool
    @State private var brightness: Double = 0.8

    let hueColors: [(name: String, hue: Double)] = [
        ("红", 0.0), ("橙红", 25.0), ("橙", 35.0), ("橙黄", 50.0),
        ("黄", 60.0), ("黄绿", 90.0), ("绿", 135.0), ("青绿", 165.0),
        ("青", 185.0), ("蓝", 220.0), ("蓝紫", 265.0), ("紫", 285.0)
    ]

    let rings: [Double] = [1.0, 0.80, 0.60, 0.40, 0.20]

    let quickColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .brown, .black, .gray, .white
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择颜色")
                    .font(.title2.bold())
                    .padding(.top, 10)

                ZStack {
                    ColorWheelRing(rings: rings, hueColors: hueColors, brightness: brightness, selectedColor: $selectedColor, isPresented: $isPresented)
                        .frame(width: 380, height: 380)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 4)], spacing: 4) {
                    ForEach(Array(hueColors.enumerated()), id: \.offset) { index, hue in
                        Text(hue.name)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    Text("快捷颜色")
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)

                    HStack(spacing: 12) {
                        ForEach(quickColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sun.min").foregroundColor(.gray)
                        Slider(value: $brightness, in: 0.2...1.0).tint(.orange)
                        Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                    }
                    Text("亮度: \(Int(brightness * 100))%")
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)

                HStack {
                    Text("当前:")
                        .font(.headline)
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)

                Spacer()
            }
            .navigationTitle("选颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ColorWheelRing: View {
    let rings: [Double]
    let hueColors: [(name: String, hue: Double)]
    let brightness: Double
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let maxRadius = min(geometry.size.width, geometry.size.height) / 2

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .onTapGesture {
                        selectedColor = Color.white
                        isPresented = false
                    }

                ColorWheelRingsView(rings: rings, hueColors: hueColors, brightness: brightness, center: center, maxRadius: maxRadius, selectedColor: $selectedColor, isPresented: $isPresented)
            }
        }
    }
}

struct ColorWheelRingsView: View {
    let rings: [Double]
    let hueColors: [(name: String, hue: Double)]
    let brightness: Double
    let center: CGPoint
    let maxRadius: CGFloat
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        ColorWheelSingleRing(saturation: rings[0], brightness: brightness, outerRadius: maxRadius, innerRadius: maxRadius * 0.72, hueColors: hueColors, center: center, selectedColor: $selectedColor, isPresented: $isPresented)
        ColorWheelSingleRing(saturation: rings[1], brightness: brightness, outerRadius: maxRadius * 0.72, innerRadius: maxRadius * 0.52, hueColors: hueColors, center: center, selectedColor: $selectedColor, isPresented: $isPresented)
        ColorWheelSingleRing(saturation: rings[2], brightness: brightness, outerRadius: maxRadius * 0.52, innerRadius: maxRadius * 0.34, hueColors: hueColors, center: center, selectedColor: $selectedColor, isPresented: $isPresented)
        ColorWheelSingleRing(saturation: rings[3], brightness: brightness, outerRadius: maxRadius * 0.34, innerRadius: maxRadius * 0.18, hueColors: hueColors, center: center, selectedColor: $selectedColor, isPresented: $isPresented)
        ColorWheelSingleRing(saturation: rings[4], brightness: brightness, outerRadius: maxRadius * 0.18, innerRadius: maxRadius * 0.08, hueColors: hueColors, center: center, selectedColor: $selectedColor, isPresented: $isPresented)
    }
}

struct ColorWheelSingleRing: View {
    let saturation: Double
    let brightness: Double
    let outerRadius: CGFloat
    let innerRadius: CGFloat
    let hueColors: [(name: String, hue: Double)]
    let center: CGPoint
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { hueIndex in
                let hue = hueColors[hueIndex].hue
                let sliceAngle = 30.0
                let startAngle = Double(hueIndex) * sliceAngle - 90
                let endAngle = startAngle + sliceAngle

                PieSlice(center: center, innerRadius: innerRadius, outerRadius: outerRadius, startAngle: startAngle, endAngle: endAngle)
                    .fill(Color(hue: hue / 360, saturation: saturation, brightness: brightness))
                    .onTapGesture {
                        selectedColor = Color(hue: hue / 360, saturation: saturation, brightness: brightness)
                        isPresented = false
                    }
            }
        }
    }
}

struct PieSlice: Shape {
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let innerStart = CGPoint(x: center.x + innerRadius * cos(CGFloat(startAngle) * .pi / 180), y: center.y + innerRadius * sin(CGFloat(startAngle) * .pi / 180))
        let outerStart = CGPoint(x: center.x + outerRadius * cos(CGFloat(startAngle) * .pi / 180), y: center.y + outerRadius * sin(CGFloat(startAngle) * .pi / 180))
        let outerEnd = CGPoint(x: center.x + outerRadius * cos(CGFloat(endAngle) * .pi / 180), y: center.y + outerRadius * sin(CGFloat(endAngle) * .pi / 180))
        let innerEnd = CGPoint(x: center.x + innerRadius * cos(CGFloat(endAngle) * .pi / 180), y: center.y + innerRadius * sin(CGFloat(endAngle) * .pi / 180))

        path.move(to: innerStart)
        path.addLine(to: outerStart)
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
        path.addLine(to: innerEnd)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(endAngle), endAngle: .degrees(startAngle), clockwise: true)
        path.closeSubpath()
        return path
    }
}

// 风格选择器
struct StylePickerView: View {
    @Binding var canvasStyle: CanvasStyle
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择画布风格")
                    .font(.title2.bold())
                    .padding(.top, 20)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                    ForEach(CanvasStyle.allCases, id: \.self) { style in
                        StyleCard(style: style, isSelected: canvasStyle == style)
                            .onTapGesture {
                                canvasStyle = style
                                isPresented = false
                            }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("画布风格")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { isPresented = false }
                }
            }
        }
    }
}

struct StyleCard: View {
    let style: CanvasStyle
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(style.backgroundColor)
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 4) {
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 30))
                            path.addQuadCurve(to: CGPoint(x: 60, y: 50), control: CGPoint(x: 40, y: 20))
                        }
                        .stroke(Color.gray.opacity(style.lineOpacity), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        Path { path in
                            path.move(to: CGPoint(x: 30, y: 60))
                            path.addQuadCurve(to: CGPoint(x: 80, y: 40), control: CGPoint(x: 50, y: 80))
                        }
                        .stroke(Color.gray.opacity(style.lineOpacity * 0.8), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3))

            Text(style.rawValue)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .blue : .primary)
            Text(style.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
