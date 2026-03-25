import SwiftUI

// 彩虹颜色数组
let rainbowColors: [Color] = [
    .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink
]

// 贴纸类型
struct Sticker: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let systemName: String  // SF Symbol 名称
    var scale: CGFloat = 1.0
    var rotation: Double = 0
    var colorIndex: Int = 0  // 彩虹颜色索引

    var rainbowColor: Color {
        rainbowColors[colorIndex % rainbowColors.count]
    }

    static let allStickers: [Sticker] = [
        // 星星系列 - 彩虹色
        Sticker(name: "星星", systemName: "star.fill", colorIndex: 0),
        Sticker(name: "星星2", systemName: "star.leadinghalf.filled", colorIndex: 1),
        Sticker(name: "五角星", systemName: "star.circle.fill", colorIndex: 2),

        // 爱心系列
        Sticker(name: "爱心", systemName: "heart.fill", colorIndex: 3),
        Sticker(name: "心形", systemName: "heart.circle.fill", colorIndex: 4),

        // 动物系列
        Sticker(name: "猫", systemName: "cat.fill", colorIndex: 5),
        Sticker(name: "狗", systemName: "dog.fill", colorIndex: 6),
        Sticker(name: "兔子", systemName: "hare.fill", colorIndex: 7),
        Sticker(name: "鸟", systemName: "bird.fill", colorIndex: 0),
        Sticker(name: "蝴蝶", systemName: "ladybug.fill", colorIndex: 1),
        Sticker(name: "蜗牛", systemName: "bug.fill", colorIndex: 2),

        // 表情系列
        Sticker(name: "笑脸", systemName: "face.smiling.fill", colorIndex: 3),
        Sticker(name: "星星眼", systemName: "star.leadinghalf.filled", colorIndex: 4),
        Sticker(name: "爱心眼", systemName: "heart.fill", colorIndex: 5),

        // 自然系列
        Sticker(name: "彩虹", systemName: "rainbow", colorIndex: 0),
        Sticker(name: "太阳", systemName: "sun.max.fill", colorIndex: 1),
        Sticker(name: "月亮", systemName: "moon.fill", colorIndex: 2),
        Sticker(name: "云", systemName: "cloud.fill", colorIndex: 3),

        // 物品系列
        Sticker(name: "礼物", systemName: "gift.fill", colorIndex: 4),
        Sticker(name: "气球", systemName: "balloon.fill", colorIndex: 5),
        Sticker(name: "蛋糕", systemName: "birthday.cake.fill", colorIndex: 6),
        Sticker(name: "皇冠", systemName: "crown.fill", colorIndex: 7),
    ]
}

// 画布上的贴纸实例
struct PlacedSticker: Identifiable, Equatable, Codable {
    let id: UUID
    let stickerName: String
    let systemName: String
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var colorIndex: Int

    var rainbowColor: Color {
        rainbowColors[colorIndex % rainbowColors.count]
    }

    init(sticker: Sticker, position: CGPoint) {
        self.id = UUID()
        self.stickerName = sticker.name
        self.systemName = sticker.systemName
        self.position = position
        self.scale = 1.0
        self.rotation = 0
        self.colorIndex = sticker.colorIndex
    }
}
