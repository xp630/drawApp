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

    // 每行同色系：红、橙、黄、绿、蓝、紫，每行3个深浅
    let colorPalette: [[Color]] = [
        [Color(red:0.95, green:0.3, blue:0.3), Color(red:0.8, green:0.2, blue:0.2), Color(red:0.6, green:0.1, blue:0.1)],
        [Color(red:1.0, green:0.55, blue:0.1), Color(red:0.85, green:0.4, blue:0.0), Color(red:0.65, green:0.25, blue:0.0)],
        [Color(red:1.0, green:0.9, blue:0.2), Color(red:0.9, green:0.75, blue:0.1), Color(red:0.75, green:0.6, blue:0.0)],
        [Color(red:0.25, green:0.85, blue:0.25), Color(red:0.15, green:0.65, blue:0.15), Color(red:0.05, green:0.5, blue:0.05)],
        [Color(red:0.25, green:0.45, blue:0.95), Color(red:0.15, green:0.35, blue:0.8), Color(red:0.05, green:0.25, blue:0.65)],
        [Color(red:0.75, green:0.25, blue:0.85), Color(red:0.6, green:0.15, blue:0.7), Color(red:0.45, green:0.05, blue:0.55)]
    ]

    let hueNames = ["红", "橙", "黄", "绿", "蓝", "紫"]

    var body: some View {
        NavigationView {
            VStack {
                Text("选一个颜色")
                    .font(.title2)
                    .padding(.top, 30)

                VStack(spacing: 16) {
                    ForEach(0..<colorPalette.count, id: \.self) { row in
                        HStack(spacing: 12) {
                            Text(hueNames[row])
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(width: 30, alignment: .leading)

                            ForEach(0..<colorPalette[row].count, id: \.self) { col in
                                let color = colorPalette[row][col]
                                Circle()
                                    .fill(color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                        isPresented = false
                                    }
                            }
                        }
                    }
                }
                .padding()

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
