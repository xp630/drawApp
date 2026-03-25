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

    @State private var autoSaveEnabled: Bool = false
    @State private var colorHistory: [Color] = []  // 颜色历史记录
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
                    onSettings: { /* 待实现 */ },
                    onDraftBox: { showDraftBox = true }
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
            ColorPickerSheet(selectedColor: $currentColor, isPresented: $showColorPicker, colorHistory: $colorHistory)
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
    let onDraftBox: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：新建设置
            HStack(spacing: 12) {
                TopBarButton(icon: "doc.badge.plus", label: "新建") {
                    onNew()
                }
                TopBarButton(icon: "folder", label: "草稿箱") {
                    onDraftBox()
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
            .padding(.horizontal, 20)

            Divider()
                .frame(height: 50)
                .padding(.horizontal, 12)

            // 画笔类型
            HStack(spacing: 16) {
                ForEach(BrushType.allCases, id: \.self) { type in
                    BottomBrushButton(type: type, selectedType: $brushType)
                }
            }
            .padding(.horizontal, 20)

            Divider()
                .frame(height: 50)
                .padding(.horizontal, 12)

            // 粗细滑块
            HStack(spacing: 16) {
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
            .padding(.horizontal, 20)

            Divider()
                .frame(height: 50)
                .padding(.horizontal, 12)

            // 特效区域
            HStack(spacing: 20) {
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
            .padding(.horizontal, 20)
        }
        .frame(height: 100)
        .background(
            Color.clear
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
                .frame(width: 56, height: 56)
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
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
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

// Color Picker Sheet - 增强版
struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool
    @Binding var colorHistory: [Color]
    @State private var hue: Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1
    @State private var selectedTab: Int = 1

    // 色环标签页独立的颜色状态
    @State private var ringColor: Color = .red
    // RGB标签页独立的颜色状态
    @State private var rgbColor: Color = .red

    init(selectedColor: Binding<Color>, isPresented: Binding<Bool>, colorHistory: Binding<[Color]>) {
        self._selectedColor = selectedColor
        self._isPresented = isPresented
        self._colorHistory = colorHistory
        // 从初始颜色提取 HSB 值
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(selectedColor.wrappedValue).getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // 如果饱和度或亮度为0（黑色），使用默认值
        let finalHue = Double(h)
        let finalSaturation = s > 0 ? Double(s) : 1.0
        let finalBrightness = b > 0 ? Double(b) : 1.0

        self._hue = State(initialValue: finalHue)
        self._saturation = State(initialValue: finalSaturation)
        self._brightness = State(initialValue: finalBrightness)

        // 初始化各标签页颜色
        self._ringColor = State(initialValue: Color(hue: finalHue, saturation: finalSaturation, brightness: finalBrightness))
        self._rgbColor = State(initialValue: selectedColor.wrappedValue)
    }

    // 24色基础色盘
    let basicColors: [Color] = [
        // 红系
        Color(red: 1.0, green: 0.0, blue: 0.0),     // 红
        Color(red: 1.0, green: 0.23, blue: 0.0),      // 橙红
        Color(red: 1.0, green: 0.5, blue: 0.0),      // 橙
        Color(red: 1.0, green: 0.75, blue: 0.0),     // 橙黄
        Color(red: 1.0, green: 1.0, blue: 0.0),      // 黄
        Color(red: 0.75, green: 1.0, blue: 0.0),     // 黄绿
        Color(red: 0.5, green: 1.0, blue: 0.0),      // 绿
        Color(red: 0.0, green: 1.0, blue: 0.5),      // 青绿
        Color(red: 0.0, green: 1.0, blue: 1.0),      // 青
        Color(red: 0.0, green: 0.5, blue: 1.0),      // 蓝
        Color(red: 0.0, green: 0.0, blue: 1.0),      // 蓝
        Color(red: 0.5, green: 0.0, blue: 1.0),      // 蓝紫
        Color(red: 1.0, green: 0.0, blue: 1.0),      // 紫
        Color(red: 1.0, green: 0.0, blue: 0.5),     // 紫红
        // 灰度系
        Color(red: 0.9, green: 0.9, blue: 0.9),     // 浅灰
        Color(red: 0.7, green: 0.7, blue: 0.7),     // 中灰
        Color(red: 0.5, green: 0.5, blue: 0.5),     // 深灰
        Color(red: 0.3, green: 0.3, blue: 0.3),     // 暗灰
        Color(red: 0.1, green: 0.1, blue: 0.1),     // 深灰黑
        // 暖色系
        Color(red: 1.0, green: 0.85, blue: 0.7),   // 肤色
        Color(red: 0.96, green: 0.87, blue: 0.7),   // 米色
        Color(red: 0.82, green: 0.55, blue: 0.28),   // 棕色
        Color(red: 0.55, green: 0.27, blue: 0.07),   // 深棕
        Color(red: 0.0, green: 0.0, blue: 0.0),       // 黑
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab 选择
                Picker("选择", selection: $selectedTab) {
                    Text("色盘").tag(0)
                    Text("色环").tag(1)
                    Text("取色").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                TabView(selection: $selectedTab) {
                    // Tab 1: 24色基础色盘
                    colorPaletteTab
                        .tag(0)

                    // Tab 2: 色环选择器
                    hueRingTab
                        .tag(1)

                    // Tab 3: RGB取色器
                    rgbPickerTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // 历史颜色
                if !colorHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近使用")
                            .font(.caption)
                            .foregroundColor(.gray)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 8)], spacing: 8) {
                            ForEach(0..<colorHistory.count, id: \.self) { index in
                                Circle()
                                    .fill(colorHistory[index])
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        selectColor(colorHistory[index])
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 当前颜色预览
                HStack {
                    Text("当前:")
                        .font(.headline)
                    Circle()
                        .fill(currentTabColor)
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("选颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        let newColor = currentTabColor
                        // 添加到历史记录（使用RGB比较避免颜色对比问题）
                        if !colorHistory.contains(where: { isSameColor($0, newColor) }) {
                            colorHistory.insert(newColor, at: 0)
                            if colorHistory.count > 8 {
                                colorHistory.removeLast()
                            }
                        }
                        selectedColor = newColor
                        isPresented = false
                    }
                }
            }
        }
    }

    // 根据当前标签页返回对应颜色
    private var currentTabColor: Color {
        switch selectedTab {
        case 0: return selectedColor  // 色盘直接返回选中颜色
        case 1: return ringColor    // 色环
        case 2: return rgbColor     // RGB
        default: return selectedColor
        }
    }

    // 色盘 Tab
    private var colorPaletteTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("基础色盘")
                    .font(.headline)
                    .foregroundColor(.gray)

                // 24色网格
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 8)], spacing: 8) {
                    ForEach(0..<24, id: \.self) { index in
                        Circle()
                            .fill(basicColors[index])
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .onTapGesture {
                                selectedColor = basicColors[index]
                            }
                    }
                }
                .padding(.horizontal)

                Text("点击选择颜色")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
        }
    }

    // 色环 Tab
    private var hueRingTab: some View {
        VStack(spacing: 16) {
            ZStack {
                // 色环
                HueRingView(selectedHue: $hue, saturation: $saturation, brightness: $brightness)
                    .frame(width: 300, height: 300)

                // 中心亮度/饱和度调节
                VStack(spacing: 10) {
                    Text("饱和度")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Slider(value: $saturation, in: 0...1)
                        .frame(width: 140)
                        .tint(.orange)

                    Text("亮度")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Slider(value: $brightness, in: 0...1)
                        .frame(width: 140)
                        .tint(.yellow)
                }
            }
            .onChange(of: hue) { _ in
                ringColor = Color(hue: hue, saturation: saturation, brightness: brightness)
            }
            .onChange(of: saturation) { _ in
                ringColor = Color(hue: hue, saturation: saturation, brightness: brightness)
            }
            .onChange(of: brightness) { _ in
                ringColor = Color(hue: hue, saturation: saturation, brightness: brightness)
            }

            Spacer()
        }
        .padding(.top, 20)
    }

    // RGB取色 Tab
    private var rgbPickerTab: some View {
        VStack(spacing: 20) {
            // 颜色预览大方块
            RoundedRectangle(cornerRadius: 12)
                .fill(rgbColor)
                .frame(height: 80)
                .padding(.horizontal)

            // RGB滑块
            VStack(spacing: 12) {
                HStack {
                    Text("红")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    Slider(value: Binding(
                        get: { getRgbRed() },
                        set: { newRed in
                            rgbColor = Color(red: newRed, green: getRgbGreen(), blue: getRgbBlue())
                        }
                    ), in: 0...1)
                    .tint(.red)
                }

                HStack {
                    Text("绿")
                        .foregroundColor(.green)
                        .frame(width: 30)
                    Slider(value: Binding(
                        get: { getRgbGreen() },
                        set: { newGreen in
                            rgbColor = Color(red: getRgbRed(), green: newGreen, blue: getRgbBlue())
                        }
                    ), in: 0...1)
                    .tint(.green)
                }

                HStack {
                    Text("蓝")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    Slider(value: Binding(
                        get: { getRgbBlue() },
                        set: { newBlue in
                            rgbColor = Color(red: getRgbRed(), green: getRgbGreen(), blue: newBlue)
                        }
                    ), in: 0...1)
                    .tint(.blue)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 20)
    }

    // Helper functions
    private func updateColorFromHSB() {
        ringColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private func selectColor(_ color: Color) {
        // 根据当前标签页更新对应颜色
        switch selectedTab {
        case 0: selectedColor = color  // 色盘
        case 1:
            // 色环 - 提取HSB并更新
            var h: CGFloat = 0
            var s: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            hue = Double(h)
            saturation = s > 0 ? Double(s) : 1.0
            brightness = b > 0 ? Double(b) : 1.0
            ringColor = color
        case 2:
            rgbColor = color  // RGB
        default:
            break
        }
    }

    // 比较两个颜色是否相同（RGB比较）
    private func isSameColor(_ c1: Color, _ c2: Color) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(c1).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(c2).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
    }

    private func getRed() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(selectedColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(r)
    }

    private func getGreen() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(selectedColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(g)
    }

    private func getBlue() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(selectedColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(b)
    }

    // RGB picker 专用
    private func getRgbRed() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(rgbColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(r)
    }

    private func getRgbGreen() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(rgbColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(g)
    }

    private func getRgbBlue() -> Double {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(rgbColor).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(b)
    }
}

// 色环视图
struct HueRingView: View {
    @Binding var selectedHue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    let hueColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red
    ]

    private let ringSize: CGFloat = 300
    private let ringWidth: CGFloat = 40
    private let center: CGFloat = 150
    private let indicatorRadius: CGFloat = 130

    var body: some View {
        ZStack {
            // 色环 - 从顶部(12点钟)开始，顺时针颜色变化
            Circle()
                .trim(from: 0, to: 1)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: hueColors), center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
                )
                .frame(width: ringSize, height: ringSize)

            // 白色内圆
            Circle()
                .fill(Color.white)
                .frame(width: ringSize - ringWidth * 2 - 20, height: ringSize - ringWidth * 2 - 20)

            // 选中颜色指示器
            Circle()
                .fill(Color(hue: selectedHue, saturation: saturation, brightness: brightness))
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                .position(indicatorPosition)

            // 透明拖拽区域
            Circle()
                .fill(Color.clear)
                .frame(width: ringSize, height: ringSize)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHueFromLocation(value.location)
                        }
                )
        }
    }

    private func updateHueFromLocation(_ location: CGPoint) {
        let dx = location.x - center
        let dy = location.y - center
        let distance = sqrt(dx * dx + dy * dy)

        // 只在色环区域内响应
        let innerRadius = indicatorRadius - ringWidth / 2 - 10
        let outerRadius = indicatorRadius + ringWidth / 2 + 10
        guard distance > innerRadius && distance < outerRadius else { return }

        // atan2: 顶部=-π/2, 右=0, 底部=π/2, 左=±π
        // 转换到hue: 顶部=0, 右=0.25, 底=0.5, 左=0.75
        var angle = atan2(dy, dx)

        // 转换为hue: hue = (π/2 - angle) / 2π
        var hue = (.pi / 2 - angle) / (2 * .pi)
        if hue < 0 { hue += 1 }
        if hue > 1 { hue -= 1 }

        selectedHue = hue
    }

    private var indicatorPosition: CGPoint {
        // hue 0 → 角度-π/2 (顶部)
        // hue 0.25 → 角度0 (右)
        // hue 0.5 → 角度π/2 (底)
        let angle = -(.pi / 2) + selectedHue * 2 * .pi
        return CGPoint(
            x: center + indicatorRadius * Darwin.cos(angle),
            y: center + indicatorRadius * Darwin.sin(angle)
        )
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
