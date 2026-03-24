import SwiftUI

struct ToolbarView: View {
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var isEraser: Bool
    @Binding var showDraftBox: Bool
    @Binding var showColorPicker: Bool
    @Binding var isToolbarVisible: Bool

    var onClear: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
                    .font(.caption)
                    .foregroundColor(.gray)

                Button {
                    showColorPicker = true
                } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedColor)
                        .frame(width: 50, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // 画笔粗细
            VStack(alignment: .leading, spacing: 8) {
                Text("画笔")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    BrushSizeButton(width: 3, selectedWidth: $lineWidth)
                    BrushSizeButton(width: 8, selectedWidth: $lineWidth)
                    BrushSizeButton(width: 15, selectedWidth: $lineWidth)
                }
            }

            // 橡皮擦
            Button {
                isEraser.toggle()
            } label: {
                VStack {
                    Image(systemName: isEraser ? "eraser.fill" : "eraser")
                        .font(.title2)
                    Text("橡皮")
                        .font(.caption)
                }
                .foregroundColor(isEraser ? .blue : .primary)
                .frame(width: 60, height: 60)
                .background(isEraser ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }

            // 清空
            Button {
                onClear()
            } label: {
                VStack {
                    Image(systemName: "trash")
                        .font(.title2)
                    Text("清空")
                        .font(.caption)
                }
                .foregroundColor(.red)
                .frame(width: 60, height: 60)
            }

            // 草稿箱
            Button {
                showDraftBox = true
            } label: {
                VStack {
                    Image(systemName: "folder")
                        .font(.title2)
                    Text("草稿箱")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
            }

            Spacer()

            // 关闭工具栏
            Button {
                isToolbarVisible = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(UIColor.systemGray6))
    }
}

struct BrushSizeButton: View {
    let width: CGFloat
    @Binding var selectedWidth: CGFloat

    var isSelected: Bool {
        selectedWidth == width
    }

    var body: some View {
        Button {
            selectedWidth = width
        } label: {
            Circle()
                .fill(isSelected ? Color.blue : Color.gray)
                .frame(width: min(width * 2, 30), height: min(width * 2, 30))
        }
    }
}
