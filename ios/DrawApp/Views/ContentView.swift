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

    // 同心圆：每圈同色系，不同深浅分段
    let rings: [(hue: Color, segments: [Color], radius: CGFloat)] = [
        (.red,    [Color(red:1.0, green:0.3, blue:0.3), Color(red:0.9, green:0.2, blue:0.2), Color(red:0.7, green:0.1, blue:0.1)], 140),
        (.orange, [Color(red:1.0, green:0.55, blue:0.1), Color(red:0.9, green:0.45, blue:0.0), Color(red:0.75, green:0.35, blue:0.0)], 105),
        (.yellow, [Color(red:1.0, green:0.9, blue:0.2), Color(red:0.95, green:0.8, blue:0.1), Color(red:0.8, green:0.65, blue:0.0)], 75),
        (.green,  [Color(red:0.3, green:0.85, blue:0.3), Color(red:0.2, green:0.7, blue:0.2), Color(red:0.1, green:0.55, blue:0.1)], 50),
        (.blue,   [Color(red:0.3, green:0.5, blue:1.0), Color(red:0.2, green:0.4, blue:0.85), Color(red:0.1, green:0.3, blue:0.7)], 35),
        (.purple, [Color(red:0.8, green:0.3, blue:0.9), Color(red:0.65, green:0.2, blue:0.75), Color(red:0.5, green:0.1, blue:0.6)], 20)
    ]

    var body: some View {
        NavigationView {
            VStack {
                Text("选一个颜色")
                    .font(.title2.bold())
                    .padding(.top, 20)

                Text("点击圆环选择颜色")
                    .font(.caption)
                    .foregroundColor(.gray)

                // 同心圆颜色选择器
                ZStack {
                    ForEach(0..<rings.count, id: \.self) { ringIndex in
                        let ring = rings[ringIndex]
                        let ringRadius = ring.radius
                        let segmentAngle: Double = 360.0 / Double(ring.segments.count)

                        ForEach(0..<ring.segments.count, id: \.self) { segIndex in
                            let startAngle = Double(segIndex) * segmentAngle - 90
                            let endAngle = startAngle + segmentAngle - 5

                            Arc(startAngle: startAngle, endAngle: endAngle)
                                .stroke(
                                    ring.segments[segIndex],
                                    style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                                )
                                .frame(width: ringRadius * 2, height: ringRadius * 2)
                                .onTapGesture {
                                    selectedColor = ring.segments[segIndex]
                                    isPresented = false
                                }
                        }
                    }

                    // 中心白色圆
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == .white ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedColor = .white
                            isPresented = false
                        }
                }
                .padding(40)

                // 颜色图例
                HStack(spacing: 20) {
                    ForEach(0..<rings.count, id: \.self) { ringIndex in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(rings[ringIndex].hue)
                                .frame(width: 16, height: 16)
                            Text(ringName(ringIndex))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 10)

                // 当前颜色
                HStack {
                    Text("当前:")
                        .font(.headline)
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 2)
                        )
                }
                .padding(.top, 20)

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

    func ringName(_ index: Int) -> String {
        ["红", "橙", "黄", "绿", "蓝", "紫"][index]
    }
}

// 自定义弧形
struct Arc: Shape {
    var startAngle: Double
    var endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )

        return path
    }
}
