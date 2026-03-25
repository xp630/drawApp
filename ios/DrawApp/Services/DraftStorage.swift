import SwiftUI
import Combine

class DraftStorage: ObservableObject {
    static let shared = DraftStorage()

    @Published var drafts: [Draft] = []

    private let fileManager = FileManager.default
    private var draftsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let drafts = documents.appendingPathComponent("Drafts", isDirectory: true)
        if !fileManager.fileExists(atPath: drafts.path) {
            try? fileManager.createDirectory(at: drafts, withIntermediateDirectories: true)
        }
        return drafts
    }

    private let userDefaultsKey = "com.drawapp.drafts"
    private let singleDraftKey = "com.drawapp.singleDraft"

    init() {
        loadDrafts()
    }

    func loadDrafts() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([Draft].self, from: data) else {
            drafts = []
            return
        }
        drafts = saved.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveDrafts() {
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    // 保存单张草稿（覆盖模式，用于非自动保存时）
    func saveSingleDraft(lines: [DrawingLine], thumbnail: UIImage) {
        // 删除旧单张草稿
        if let oldId = UserDefaults.standard.string(forKey: singleDraftKey) {
            let oldThumbURL = draftsDirectory.appendingPathComponent("\(oldId)_thumb.png")
            let oldDataURL = draftsDirectory.appendingPathComponent("\(oldId)_data.json")
            try? fileManager.removeItem(at: oldThumbURL)
            try? fileManager.removeItem(at: oldDataURL)
        }

        // 创建新草稿
        let draft = Draft()

        let thumbnailURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_thumb.png")
        let drawingDataURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_data.json")

        if let thumbData = thumbnail.pngData() {
            try? thumbData.write(to: thumbnailURL)
        }

        let drawingData = DrawingData(lines: lines)
        if let jsonData = try? JSONEncoder().encode(drawingData) {
            try? jsonData.write(to: drawingDataURL)
        }

        var savedDraft = draft
        savedDraft.thumbnailFileName = thumbnailURL.lastPathComponent
        savedDraft.drawingDataFileName = drawingDataURL.lastPathComponent

        // 保存单张草稿ID
        UserDefaults.standard.set(savedDraft.id.uuidString, forKey: singleDraftKey)

        // 更新草稿列表
        drafts = [savedDraft]
        saveDrafts()
    }

    func saveDraft(lines: [DrawingLine], thumbnail: UIImage) -> Draft {
        let draft = Draft()

        let thumbnailURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_thumb.png")
        let drawingDataURL = draftsDirectory.appendingPathComponent("\(draft.id.uuidString)_data.json")

        if let thumbData = thumbnail.pngData() {
            try? thumbData.write(to: thumbnailURL)
        }

        let drawingData = DrawingData(lines: lines)
        if let jsonData = try? JSONEncoder().encode(drawingData) {
            try? jsonData.write(to: drawingDataURL)
        }

        var savedDraft = draft
        savedDraft.thumbnailFileName = thumbnailURL.lastPathComponent
        savedDraft.drawingDataFileName = drawingDataURL.lastPathComponent

        drafts.insert(savedDraft, at: 0)
        saveDrafts()

        return savedDraft
    }

    func loadDrawingData(for draft: Draft) -> [DrawingLine] {
        let drawingDataURL = draftsDirectory.appendingPathComponent(draft.drawingDataFileName)
        guard let data = try? Data(contentsOf: drawingDataURL),
              let drawingData = try? JSONDecoder().decode(DrawingData.self, from: data) else {
            return []
        }
        return drawingData.lines
    }

    func deleteDraft(_ draft: Draft) {
        let thumbnailURL = draftsDirectory.appendingPathComponent(draft.thumbnailFileName)
        let drawingDataURL = draftsDirectory.appendingPathComponent(draft.drawingDataFileName)

        try? fileManager.removeItem(at: thumbnailURL)
        try? fileManager.removeItem(at: drawingDataURL)

        drafts.removeAll { $0.id == draft.id }
        saveDrafts()
    }

    func getThumbnailURL(for draft: Draft) -> URL {
        return draftsDirectory.appendingPathComponent(draft.thumbnailFileName)
    }
}

struct DrawingData: Codable {
    var lines: [DrawingLine]
}
