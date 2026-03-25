import SwiftUI

struct ShapePickerView: View {
    @Binding var isPresented: Bool
    var onSelectShape: (ShapeType) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 16)
                ], spacing: 16) {
                    ForEach(ShapeType.allCases) { shape in
                        ShapeCard(shape: shape)
                            .onTapGesture {
                                onSelectShape(shape)
                                isPresented = false
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("形状")
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

struct ShapeCard: View {
    let shape: ShapeType
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 70, height: 70)

                Image(systemName: shape.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
            }

            Text(shape.rawValue)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .scaleEffect(isPressed ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// 形状工具按钮（用于工具栏）
struct ShapeButton: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "square.on.circle")
                .font(.title3)
            Text("形状")
                .font(.caption2)
        }
        .foregroundColor(.blue)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(10)
    }
}
