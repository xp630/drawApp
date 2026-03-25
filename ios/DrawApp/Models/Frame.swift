import SwiftUI

// 相框类型
enum FrameType: String, CaseIterable, Identifiable {
    case none = "无"
    case simple = "简约"
    case classic = "经典"
    case wooden = "木框"
    case colorful = "彩虹"
    case birthday = "生日"

    var id: String { rawValue }

    // 相框颜色
    var frameColors: [Color] {
        switch self {
        case .none: return []
        case .simple: return [Color.gray]
        case .classic: return [Color.black, Color(white: 0.3)]
        case .wooden: return [Color(red: 0.55, green: 0.35, blue: 0.2), Color(red: 0.65, green: 0.45, blue: 0.3)]
        case .colorful: return [.red, .orange, .yellow, .green, .blue, .purple]
        case .birthday: return [.pink, .purple, .yellow, .cyan]
        }
    }

    // 相框宽度
    var frameWidth: CGFloat {
        switch self {
        case .none: return 0
        case .simple: return 8
        case .classic: return 15
        case .wooden: return 20
        case .colorful: return 12
        case .birthday: return 18
        }
    }
}
