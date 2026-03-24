import SwiftUI

struct ToolbarView: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var showDraftBox: Bool
    @Binding var showColorPicker: Bool
    @Binding var isToolbarVisible: Bool
    @Binding var brushType: BrushType

    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // 顶部标题
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("画板工具")
                    .font(.headline)
            }
            .padding(.top, 10)

            Divider()

            // 颜色选择
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.pink)
                    Text("颜色")
                        .font(.subheadline.bold())
                    Spacer()
                }

                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 2)
                            )
                        Text("选择颜色")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }

            // 画笔类型
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "pencil.tip")
                        .foregroundColor(.blue)
                    Text("画笔")
                        .font(.subheadline.bold())
                    Spacer()
                }

                HStack(spacing: 8) {
                    ForEach(BrushType.allCases, id: \.self) { type in
                        BrushTypeButton(type: type, selectedType: $brushType)
                    }
                }
            }

            // 画笔粗细
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "lineweight")
                        .foregroundColor(.purple)
                    Text("粗细")
                        .font(.subheadline.bold())
                    Spacer()
                }

                HStack(spacing: 16) {
                    BrushSizeButton(width: 3, selectedWidth: $lineWidth, label: "细")
                    BrushSizeButton(width: 8, selectedWidth: $lineWidth, label: "中")
                    BrushSizeButton(width: 15, selectedWidth: $lineWidth, label: "粗")
                }
            }

            Divider()

            // 功能按钮
            VStack(spacing: 12) {
                ToolButton(
                    icon: isEraser ? "eraser.fill" : "eraser",
                    label: "橡皮擦",
                    color: isEraser ? .blue : .primary,
                    bgColor: isEraser ? Color.blue.opacity(0.15) : Color.white
                ) {
                    isEraser.toggle()
                }

                ToolButton(
                    icon: "trash",
                    label: "清空画布",
                    color: .red,
                    bgColor: Color.white
                ) {
                    onClear()
                }

                ToolButton(
                    icon: "folder",
                    label: "草稿箱",
                    color: .orange,
                    bgColor: Color.white
                ) {
                    showDraftBox = true
                }
            }

            Spacer()

            // 关闭按钮
            Button {
                isToolbarVisible = false
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("隐藏工具栏")
                        .font(.subheadline)
                }
                .foregroundColor(.gray)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(20)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(UIColor.systemGray6))
    }
}

struct BrushTypeButton: View {
    let type: BrushType
    @Binding var selectedType: BrushType

    var isSelected: Bool {
        selectedType == type
    }

    var body: some View {
        Button {
            selectedType = type
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                Text(type.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(10)
        }
    }
}

struct BrushSizeButton: View {
    let width: CGFloat
    @Binding var selectedWidth: CGFloat
    let label: String

    var isSelected: Bool {
        selectedWidth == width
    }

    var body: some View {
        Button {
            selectedWidth = width
        } label: {
            VStack(spacing: 4) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray)
                    .frame(width: min(width * 2, 28), height: min(width * 2, 28))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct ToolButton: View {
    let icon: String
    let label: String
    let color: Color
    let bgColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(12)
            .background(bgColor)
            .cornerRadius(12)
        }
    }
}
