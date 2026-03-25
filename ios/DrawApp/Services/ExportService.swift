import SwiftUI
import Photos

class ExportService {
    static let shared = ExportService()

    private init() {}

    // 保存图片到相册
    func saveToPhotoLibrary(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "ExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有保存照片的权限"]))
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }

    // 渲染画布内容为图片（包含线条和贴纸，不包含背景）
    func renderCanvasToImage(
        lines: [DrawingLine],
        placedStickers: [PlacedSticker],
        canvasSize: CGSize,
        backgroundColor: Color = .white,
        showFrame: Bool = false,
        frameType: FrameType = .none
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { ctx in
            // 填充背景
            UIColor(backgroundColor).setFill()
            ctx.fill(CGRect(origin: .zero, size: canvasSize))

            // 绘制线条
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

                // 素描模式转换为灰色
                let color: UIColor
                if line.isEraser {
                    color = .white
                } else {
                    color = UIColor(line.color.color)
                }
                color.setStroke()
                path.stroke()
            }

            // 绘制贴纸
            for sticker in placedStickers {
                if let image = UIImage(systemName: sticker.systemName) {
                    let size: CGFloat = 50 * sticker.scale
                    let rect = CGRect(
                        x: sticker.position.x - size / 2,
                        y: sticker.position.y - size / 2,
                        width: size,
                        height: size
                    )

                    ctx.cgContext.saveGState()
                    ctx.cgContext.translateBy(x: sticker.position.x, y: sticker.position.y)
                    ctx.cgContext.rotate(by: CGFloat(sticker.rotation) * .pi / 180)
                    ctx.cgContext.translateBy(x: -sticker.position.x, y: -sticker.position.y)

                    image.draw(in: rect)

                    ctx.cgContext.restoreGState()
                }
            }

            // 绘制相框
            if showFrame && frameType != .none {
                let frameRect = CGRect(origin: .zero, size: canvasSize)
                let framePath = UIBezierPath(roundedRect: frameRect, cornerRadius: 20)
                framePath.lineWidth = frameType.frameWidth

                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: frameType.frameColors.map { UIColor($0).cgColor } as CFArray,
                    locations: nil
                )!

                ctx.cgContext.saveGState()
                ctx.cgContext.addPath(framePath.cgPath)
                ctx.cgContext.replacePathWithStrokedPath()
                ctx.cgContext.clip()
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: canvasSize.width, y: canvasSize.height),
                    options: []
                )
                ctx.cgContext.restoreGState()
            }
        }
    }
}
