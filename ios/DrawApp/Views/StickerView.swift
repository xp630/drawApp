import SwiftUI

struct StickerView: View {
    @Binding var isPresented: Bool
    var onSelectSticker: (Sticker) -> Void

    let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Sticker.allStickers) { sticker in
                        StickerItemView(sticker: sticker)
                            .onTapGesture {
                                onSelectSticker(sticker)
                                isPresented = false
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("贴纸")
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

struct StickerItemView: View {
    let sticker: Sticker
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 4) {
            // 使用渐变让贴纸本身呈彩虹色
            Image(systemName: sticker.systemName)
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    sticker.rainbowColor.opacity(0.3),
                                    sticker.rainbowColor.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                )
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// 贴纸选择按钮（用于工具栏）
struct StickerButton: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.title3)
            Text("贴纸")
                .font(.caption2)
        }
        .foregroundColor(.orange)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
    }
}
