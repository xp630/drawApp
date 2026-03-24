import SwiftUI

struct ContentView: View {
    @State private var lines: [DrawingLine] = []
    @State private var currentColor: Color = .black
    @State private var lineWidth: CGFloat = 3
    @State private var isEraser: Bool = false
    @State private var isToolbarVisible: Bool = true
    @State private var showDraftBox: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showClearConfirm: Bool = false
    @State private var brushType: BrushType = .pen
    @StateObject private var draftStorage = DraftStorage.shared

    private let autoSaveInterval: TimeInterval = 30

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 画布区域
                CanvasView(
                    lines: $lines,
                    currentColor: $currentColor,
                    lineWidth: $lineWidth,
                    isEraser: $isEraser,
                    brushType: $brushType,
                    onSaveThumbnail: { image in
                        _ = draftStorage.saveDraft(lines: lines, thumbnail: image)
                    }
                )

                // 工具栏
                if isToolbarVisible {
                    HStack(spacing: 0) {
                        ToolbarView(
                            selectedColor: $currentColor,
                            lineWidth: $lineWidth,
                            isEraser: $isEraser,
                            showDraftBox: $showDraftBox,
                            showColorPicker: $showColorPicker,
                            isToolbarVisible: $isToolbarVisible,
                            brushType: $brushType,
                            onClear: {
                                showClearConfirm = true
                            },
                            onUndo: {
                                if !lines.isEmpty {
                                    lines.removeLast()
                                }
                            }
                        )

                        Spacer()
                    }
                }

                // 打开工具栏按钮
                if !isToolbarVisible {
                    VStack {
                        HStack {
                            Button {
                                isToolbarVisible = true
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showDraftBox) {
            DraftBoxView(
                isPresented: $showDraftBox,
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
        .alert("清空画布", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                lines = []
            }
        } message: {
            Text("确定要清空画布吗？此操作无法撤销。")
        }
        .onAppear {
            startAutoSave()
        }
    }

    private func startAutoSave() {
        Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { _ in
            saveThumbnail()
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
    }
}

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Binding var isPresented: Bool
    @State private var brightness: Double = 1.0

    // 蛋糕12切片颜色：红粉橙黄浅绿绿青天蓝蓝深紫紫棕
    let cakeColors: [(name: String, r: Double, g: Double, b: Double)] = [
        ("红", 1.0, 0.25, 0.25),
        ("粉", 1.0, 0.55, 0.6),
        ("橙", 1.0, 0.5, 0.1),
        ("黄", 1.0, 0.9, 0.15),
        ("浅绿", 0.5, 0.9, 0.5),
        ("绿", 0.25, 0.7, 0.25),
        ("青", 0.2, 0.75, 0.75),
        ("天蓝", 0.4, 0.6, 0.95),
        ("蓝", 0.2, 0.4, 0.85),
        ("深紫", 0.45, 0.15, 0.7),
        ("紫", 0.65, 0.2, 0.8),
        ("棕", 0.55, 0.35, 0.15)
    ]

    let layers = 8

    var body: some View {
        NavigationView {
            VStack {
                Text("选一个颜色")
                    .font(.title2.bold())
                    .padding(.top, 20)

                Text("点击蛋糕切片选择颜色")
                    .font(.caption)
                    .foregroundColor(.gray)

                // 蛋糕颜色选择器
                ZStack {
                    // 中心白点
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)

                    // 12个扇形切片
                    ForEach(0..<12, id: \.self) { sliceIndex in
                        CakeSlice(
                            sliceIndex: sliceIndex,
                            color: cakeColors[sliceIndex],
                            nextColor: sliceIndex < 11 ? cakeColors[sliceIndex + 1] : cakeColors[0],
                            layers: layers,
                            maxRadius: 150.0
                        )
                        .onTapGesture {
                            let lightness = 1.0 - (Double(layers / 2)) / Double(layers)
                            let color = cakeColors[sliceIndex]
                            selectedColor = Color(
                                red: color.r * lightness,
                                green: color.g * lightness,
                                blue: color.b * lightness
                            ).opacity(brightness)
                            isPresented = false
                        }
                    }
                }
                .padding(40)

                // 切片颜色标签
                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { index in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color(red: cakeColors[index].r, green: cakeColors[index].g, blue: cakeColors[index].b))
                                .frame(width: 14, height: 14)
                            Text(cakeColors[index].name)
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 5)

                // 当前颜色
                HStack {
                    Text("当前:")
                        .font(.headline)
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        )
                }
                .padding(.top, 15)

                // 亮度滑块
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sun.min")
                            .foregroundColor(.gray)
                        Slider(value: $brightness, in: 0.3...1.0)
                            .tint(Color.orange)
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                    }
                    Text("亮度: \(Int(brightness * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
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

// 蛋糕扇形切片 - 带渐变
struct CakeSlice: View {
    let sliceIndex: Int
    let color: (name: String, r: Double, g: Double, b: Double)
    let nextColor: (name: String, r: Double, g: Double, b: Double)?
    let layers: Int
    let maxRadius: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let sliceAngle: Double = 30.0 // 360/12 = 30度每瓣
            let startAngle = Double(sliceIndex) * sliceAngle - 90
            let endAngle = startAngle + sliceAngle

            ZStack {
                ForEach(0..<layers, id: \.self) { layerIndex in
                    let innerRadius = CGFloat(layerIndex) * maxRadius / CGFloat(layers) + 15
                    let outerRadius = CGFloat(layerIndex + 1) * maxRadius / CGFloat(layers) + 15
                    let lightness = 1.0 - (Double(layerIndex) * 0.75 / Double(layers))

                    // 当前颜色的渐变
                    let currentColor = Color(
                        red: color.r * lightness,
                        green: color.g * lightness,
                        blue: color.b * lightness
                    )

                    if let next = nextColor {
                        // 与下一个颜色的渐变
                        let nextLightness = 1.0 - (Double(layerIndex) * 0.75 / Double(layers))
                        let gradientColor = Color(
                            red: next.r * nextLightness,
                            green: next.g * nextLightness,
                            blue: next.b * nextLightness
                        )

                        // 渐变扇形
                        GradientPieSlice(
                            center: center,
                            innerRadius: innerRadius,
                            outerRadius: outerRadius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            color1: currentColor,
                            color2: gradientColor
                        )
                    } else {
                        // 纯色扇形（最后一个颜色）
                        PieSlice(
                            center: center,
                            innerRadius: innerRadius,
                            outerRadius: outerRadius,
                            startAngle: startAngle,
                            endAngle: endAngle
                        )
                        .fill(currentColor)
                    }
                }
            }
        }
    }
}

// 渐变扇形
struct GradientPieSlice: View {
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let color1: Color
    let color2: Color

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.size
            let midAngle = (startAngle + endAngle) / 2

            ZStack {
                // 左半边
                PieSlice(
                    center: center,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    startAngle: startAngle,
                    endAngle: midAngle
                )
                .fill(color1)

                // 右半边（渐变到下一个颜色）
                PieSlice(
                    center: center,
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    startAngle: midAngle,
                    endAngle: endAngle
                )
                .fill(
                    LinearGradient(
                        colors: [color1, color2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
    }
}

// 扇形
struct PieSlice: Shape {
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let innerStart = CGPoint(
            x: center.x + innerRadius * cos(CGFloat(startAngle) * .pi / 180),
            y: center.y + innerRadius * sin(CGFloat(startAngle) * .pi / 180)
        )

        let outerStart = CGPoint(
            x: center.x + outerRadius * cos(CGFloat(startAngle) * .pi / 180),
            y: center.y + outerRadius * sin(CGFloat(startAngle) * .pi / 180)
        )

        let outerEnd = CGPoint(
            x: center.x + outerRadius * cos(CGFloat(endAngle) * .pi / 180),
            y: center.y + outerRadius * sin(CGFloat(endAngle) * .pi / 180)
        )

        let innerEnd = CGPoint(
            x: center.x + innerRadius * cos(CGFloat(endAngle) * .pi / 180),
            y: center.y + innerRadius * sin(CGFloat(endAngle) * .pi / 180)
        )

        path.move(to: innerStart)
        path.addLine(to: outerStart)
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.addLine(to: innerEnd)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: .degrees(endAngle),
            endAngle: .degrees(startAngle),
            clockwise: true
        )
        path.closeSubpath()

        return path
    }
}
