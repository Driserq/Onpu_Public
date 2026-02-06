import Foundation

struct KanjiData: Codable, Identifiable {
    var id: String { character }
    let character: String
    let meaning: String
    let radicals: [String]
    let mnemonic: String
    let onyomi: String?
    let kunyomi: String?
    let level: String
}

@Observable
final class KanjiService {
    static let shared = KanjiService()
    
    private(set) var kanjiMap: [String: KanjiData] = [:]
    private(set) var allKanji: [KanjiData] = []
    
    private init() {
        loadKanjiData()
    }
    
    func loadKanjiData() {
        guard let url = Bundle.main.url(forResource: "kanji-data", withExtension: "json") else {
            print("⚠️ KanjiService: kanji-data.json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([KanjiData].self, from: data)
            self.allKanji = decoded
            self.kanjiMap = Dictionary(uniqueKeysWithValues: decoded.map { ($0.character, $0) })
            print("✅ KanjiService: Loaded \(decoded.count) kanji.")
        } catch {
            print("❌ KanjiService: Failed to decode kanji-data.json: \(error)")
        }
    }
    
    func getKanji(_ char: String) -> KanjiData? {
        return kanjiMap[char]
    }
}
