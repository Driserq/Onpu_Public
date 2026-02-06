import SwiftData
import Foundation

@Model
final class Song {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var artist: String = ""
    var lyricsRaw: String = "" // For search and display
    var createdAt: Date = Date()
    var isFavorite: Bool = false
    
    // Stored as JSON Data (CloudKit-friendly blobs)
    // We use .externalStorage as a hint for large blobs
    @Attribute(.externalStorage) var translationsJSON: Data?
    @Attribute(.externalStorage) var lyricsDataJSON: Data?
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        lyricsRaw: String,
        translations: [Int: String],
        lyricsData: [LyricsLine]
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.lyricsRaw = lyricsRaw
        self.createdAt = Date()
        self.isFavorite = false
        
        // Encode JSON Blobs immediately
        do {
            let encoder = JSONEncoder()
            self.translationsJSON = try encoder.encode(translations)
            self.lyricsDataJSON = try encoder.encode(lyricsData)
        } catch {
            print("CRITICAL ERROR: Failed to encode Song data during init: \(error)")
            // In a real app we might want to throw or handle this more gracefully,
            // but for now logging is essential.
            self.translationsJSON = nil
            self.lyricsDataJSON = nil
        }
    }
}
