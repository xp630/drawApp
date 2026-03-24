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

    var body: some View {
        NavigationView {
            VStack {
                Text("选一个颜色")
                    .font(.title2)
                    .padding(.top, 40)

                // 同心圆颜色选择器
                ZStack {
                    // 外圈 - 红色系
                    Circle()
                        .fill(Color.red)
                        .frame(width: 280, height: 280)
                        .onTapGesture {
                            selectedColor = .red
                            isPresented = false
                        }

                    // 第二圈 - 橙色系
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 220, height: 220)
                        .onTapGesture {
                            selectedColor = .orange
                            isPresented = false
                        }

                    // 第三圈 - 黄色系
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 160, height: 160)
                        .onTapGesture {
                            selectedColor = .yellow
                            isPresented = false
                        }

                    // 第四圈 - 绿色系
                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                        .onTapGesture {
                            selectedColor = .green
                            isPresented = false
                        }

                    // 中心 - 蓝色
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == .blue ? Color.white : Color.clear, lineWidth: 3)
                        )
                        .onTapGesture {
                            selectedColor = .blue
                            isPresented = false
                        }
                }
                .padding(.top, 40)

                // 当前颜色提示
                HStack {
                    Text("当前:")
                        .font(.headline)
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.top, 30)

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
