import SwiftUI

struct FramePickerView: View {
    @Binding var selectedFrame: FrameType
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140), spacing: 16)
                ], spacing: 16) {
                    ForEach(FrameType.allCases) { frame in
                        FrameCard(frame: frame, isSelected: selectedFrame == frame)
                            .onTapGesture {
                                selectedFrame = frame
                                isPresented = false
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("相框")
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

struct FrameCard: View {
    let frame: FrameType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            // 相框预览
            ZStack {
                // 画布背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(height: 80)

                // 相框边框
                if frame != .none {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: frame.frameColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    LinearGradient(
                                        colors: frame.frameColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: frame.frameWidth
                                )
                                .padding(4)
                        )
                        .padding(frame.frameWidth / 2)
                }
            }

            Text(frame.rawValue)
                .font(.subheadline)
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
}
