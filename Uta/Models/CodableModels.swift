import Foundation

// MARK: - Codable Structs for JSON Blobs

struct LyricsLine: Codable {
    var words: [WordData]

    init(words: [WordData]) {
        self.words = words
    }

    // Be tolerant to model output differences: treat missing/null "words" as empty.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.words = (try? container.decodeIfPresent([WordData].self, forKey: .words)) ?? []
    }
}

struct WordData: Codable, Identifiable {
    var id = UUID()
    var kanji: String?
    var furigana: String
    var mora: [MoraData]
    var kanjiFurigana: [KanjiFurigana]

    init(id: UUID = UUID(), kanji: String?, furigana: String, mora: [MoraData], kanjiFurigana: [KanjiFurigana] = []) {
        self.id = id
        self.kanji = kanji
        self.furigana = furigana
        self.mora = mora
        self.kanjiFurigana = kanjiFurigana
    }

    // Tolerant decoding: if Gemini omits fields, don’t crash the whole request.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.kanji = try? container.decodeIfPresent(String.self, forKey: .kanji)
        self.furigana = (try? container.decodeIfPresent(String.self, forKey: .furigana)) ?? ""
        self.mora = (try? container.decodeIfPresent([MoraData].self, forKey: .mora)) ?? []
        self.kanjiFurigana = (try? container.decodeIfPresent([KanjiFurigana].self, forKey: .kanjiFurigana)) ?? []
    }
    
    // Custom coding keys to match the JSON format if needed, 
    // but default mapping should work fine with the RN format 
    // provided we match the property names.
    // RN format: { "kanji": "...", "furigana": "...", "mora": [...] }
}

struct KanjiFurigana: Codable, Hashable {
    var kanji: String
    var reading: String
}

struct MoraData: Codable {
    var text: String
    var isHigh: Bool
}
