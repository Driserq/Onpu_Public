import Foundation
import SwiftData

@Model
final class LyricsJob {
    @Attribute(.unique) var id: UUID = UUID()
    var jobId: String = ""

    var title: String = ""
    var artist: String = ""
    var lyricsRaw: String = ""

    var statusRaw: String = "queued" // queued|running|succeeded|failed
    var stageRaw: String?
    var errorMessage: String?

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String, artist: String, lyricsRaw: String, jobId: String, status: String = "queued") {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.lyricsRaw = lyricsRaw
        self.jobId = jobId
        self.statusRaw = status
        self.stageRaw = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
