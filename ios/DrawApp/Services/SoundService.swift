import AVFoundation
import AudioToolbox

class SoundService {
    static let shared = SoundService()

    private var soundID: SystemSoundID = 0

    private init() {}

    // 画画时的声音 - 使用系统点击声
    func playDrawSound() {
        // 轻柔的点击声
        AudioServicesPlaySystemSound(1104) // Tink
    }

    // 选择颜色时的声音
    func playSelectSound() {
        // 确认声
        AudioServicesPlaySystemSound(1105) // Pop
    }

    // 选择工具时的声音
    func playToolSelectSound() {
        // 切换声
        AudioServicesPlaySystemSound(1106) //延迟
    }

    // 撤销时的声音
    func playUndoSound() {
        // 后退声
        AudioServicesPlaySystemSound(1107)
    }

    // 清空画布时的声音
    func playClearSound() {
        // 删除声
        AudioServicesPlaySystemSound(1103)
    }

    // 添加贴纸时的声音
    func playStickerSound() {
        // 上升声
        AudioServicesPlaySystemSound(1101)
    }

    // 导出成功时的声音
    func playExportSuccessSound() {
        // 成功声
        AudioServicesPlaySystemSound(1025)
    }
}
