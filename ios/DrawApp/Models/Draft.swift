import Foundation

struct Draft: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var thumbnailFileName: String
    var drawingDataFileName: String

    init(id: UUID = UUID(), createdAt: Date = Date(), updatedAt: Date = Date(), thumbnailFileName: String = "", drawingDataFileName: String = "") {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailFileName = thumbnailFileName
        self.drawingDataFileName = drawingDataFileName
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}
