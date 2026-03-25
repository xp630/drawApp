import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // 渐变背景 - 圆形
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.3),    // 红橙
                            Color(red: 1.0, green: 0.5, blue: 0.6),    // 粉
                            Color(red: 0.7, green: 0.4, blue: 0.9),    // 紫
                            Color(red: 0.4, green: 0.6, blue: 1.0)     // 蓝
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 300)

            // 中心白色心形
            Image(systemName: "heart.fill")
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .white.opacity(0.3), radius: 10)

            // 顶部装饰 - 画笔
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .offset(x: 60, y: -80)
                .rotationEffect(.degrees(30))
        }
    }
}

#Preview {
    AppIconView()
        .frame(width: 400, height: 400)
}

    