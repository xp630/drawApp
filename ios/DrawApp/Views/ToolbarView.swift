import SwiftUI

struct ToolbarView: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var showColorPicker: Bool
    @Binding var showStylePicker: Bool
    @Binding var showStickerPicker: Bool
    @Binding var showFramePicker: Bool
    @Binding var showShapePicker: Bool
    @Binding var isToolbarVisible: Bool
    @Binding var brushType: BrushType
    var selectedShapeType: ShapeType?
    var canvasStyle: CanvasStyle = .normal

    var onUndo: () -> Void
    var onExport: () -> Void

    // 当前工具状态
    private var currentToolIcon: String {
        if let shape = selectedShapeType { return shape.icon }
        return brushType.icon
    }

    private var currentToolName: String {
        ""
    }

    private var currentToolColor: Color {
        if selectedShapeType != nil { return .purple }
        return brushType.isEraser ? .blue : .orange
    }

    // MARK: - 颜色配置
    private var cardBackground: Color {
        canvasStyle == .sketch ? Color(white: 0.95) : Color.white
    }
    private var cardShadow: Color {
        canvasStyle == .sketch ? Color.black.opacity(0.05) : Color.black.opacity(0.08)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // 主内容区域 - 自适应分布
            VStack(spacing: 8) {
                // ========== 1. 绘画工具 ==========
                VStack(spacing: 8) {
                    // 颜色选择
                    Button {
                        showColorPicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedColor)
                                .frame(width: 44, height: 44)
                                .shadow(color: cardShadow, radius: 3, x: 0, y: 2)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // 画笔类型
                    HStack(spacing: 6) {
                        ForEach(BrushType.allCases, id: \.self) { type in
                            BrushTypeButton(type: type, selectedType: $brushType)
                        }
                    }

                    // 粗细滑块
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.pink.opacity(0.5))
                            .frame(width: 5, height: 5)
                        Slider(value: $lineWidth, in: 1...30, step: 1)
                            .tint(.pink)
                        Circle()
                            .fill(Color.pink.opacity(0.5))
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(cardBackground)
                        .shadow(color: cardShadow, radius: 3, x: 0, y: 2)
                )

                // ========== 2. 特效 ==========
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ToolCard(
                            icon: "star.fill",
                            iconColor: .yellow,
                            bgColor: Color.yellow.opacity(0.2)
                        ) {
                            showStickerPicker = true
                        }

                        ToolCard(
                            icon: "square.on.circle",
                            iconColor: .blue,
                            bgColor: Color.blue.opacity(0.2)
                        ) {
                            showShapePicker = true
                        }
                    }
                }

                // ========== 3. 画布 ==========
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ToolCard(
                            icon: "sparkles",
                            iconColor: .purple,
                            bgColor: Color.purple.opacity(0.2)
                        ) {
                            showStylePicker = true
                        }

                        ToolCard(
                            icon: "square.dashed",
                            iconColor: .orange,
                            bgColor: Color.orange.opacity(0.2)
                        ) {
                            showFramePicker = true
                        }
                    }
                }

                // ========== 4. 操作 ==========
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ToolCard(
                            icon: "arrow.uturn.backward",
                            iconColor: .cyan,
                            bgColor: Color.cyan.opacity(0.2)
                        ) {
                            onUndo()
                        }

                        ToolCard(
                            icon: "square.and.arrow.down",
                            iconColor: .green,
                            bgColor: Color.green.opacity(0.2)
                        ) {
                            onExport()
                        }
                    }
                }

                // 隐藏按钮
                HStack {
                    Spacer()
                    Button {
                        isToolbarVisible = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(width: 160)
        .background(canvasStyle.backgroundColor)
    }
}

struct BrushTypeButton: View {
    let type: BrushType
    @Binding var selectedType: BrushType

    var isSelected: Bool {
        selectedType == type
    }

    private var brushColor: Color {
        switch type {
        case .pencil: return Color.gray
        case .pen: return Color.blue
        case .brush: return Color.orange
        case .eraser: return Color.pink
        }
    }

    var body: some View {
        Button {
            selectedType = type
            SoundService.shared.playToolSelectSound()
        } label: {
            Image(systemName: type.icon)
                .font(.body)
                .foregroundColor(isSelected ? .white : brushColor)
                .frame(width: 34, height: 34)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(
                                LinearGradient(
                                    colors: [brushColor, brushColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: brushColor.opacity(0.4), radius: 3, x: 0, y: 2)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        }
                    }
                )
        }
    }
}

// MARK: - 工具卡片组件
struct ToolCard: View {
    let icon: String
    let iconColor: Color
    let bgColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
}
