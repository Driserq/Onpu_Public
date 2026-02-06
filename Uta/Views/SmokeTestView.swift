import SwiftUI
import SwiftData

struct SmokeTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    
    @State private var log: String = "Ready to test.\n"
    @State private var decodedTitle: String = ""
    @State private var decodedTranslation: String = ""
    @State private var decodedWordCount: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xl) {
                Text("SwiftData Smoke Test")
                    .font(.largeTitle)
                    .bold()
                
                // Controls
                HStack {
                    Button("1. Create & Save Song") {
                        createAndSaveSong()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("2. Load & Decode") {
                        loadAndDecodeSong()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Status Log
                Text("Logs:")
                    .font(.headline)
                Text(log)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                
                Divider()
                
                // Visual Verification
                if !decodedTitle.isEmpty {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.md) {
                        Text("Visual Verification:")
                            .font(.headline)
                        
                        Text("Title: \(decodedTitle)")
                        Text("Decoded Translation (Line 0):")
                            .foregroundStyle(.secondary)
                        Text(decodedTranslation)
                            .font(.body)
                            .padding(AppStyle.Spacing.sm)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                        
                        Text("Stats: \(decodedWordCount) words in line 0")
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(.rect(cornerRadius: AppStyle.Radii.sm))
                }
                
                // Database State
                Text("DB Count: \(songs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    
    private func createAndSaveSong() {
        appendLog("Creating dummy song...")
        
        let dummyLyricsRaw = "東京に置いてきた\n涙を"
        
        // Realistic dummy data based on RN context
        let dummyTranslations: [Int: String] = [
            0: "The tears I left behind in Tokyo",
            1: "Tears"
        ]
        
        let dummyWordsLine0: [WordData] = [
            WordData(
                kanji: "東京",
                furigana: "とうきょう",
                mora: [
                    MoraData(text: "と", isHigh: false),
                    MoraData(text: "う", isHigh: true),
                    MoraData(text: "きょ", isHigh: true),
                    MoraData(text: "う", isHigh: true)
                ]
            ),
            WordData(
                kanji: nil,
                furigana: "に",
                mora: [MoraData(text: "に", isHigh: false)]
            ),
             WordData(
                kanji: "置",
                furigana: "お",
                mora: [MoraData(text: "お", isHigh: false)]
            ),
             WordData(
                kanji: nil,
                furigana: "いてきた",
                mora: [
                    MoraData(text: "い", isHigh: true),
                    MoraData(text: "て", isHigh: true),
                    MoraData(text: "き", isHigh: true),
                    MoraData(text: "た", isHigh: false)
                ]
            )
        ]
        
        let dummyLyricsLine = LyricsLine(words: dummyWordsLine0)
        
        let newSong = Song(
            title: "Test Song \(Date().formatted(date: .omitted, time: .standard))",
            artist: "Smoke Test Artist",
            lyricsRaw: dummyLyricsRaw,
            translations: dummyTranslations,
            lyricsData: [dummyLyricsLine] // Single line for test
        )
        
        // Validation check before save
        if newSong.translationsJSON == nil || newSong.lyricsDataJSON == nil {
             appendLog("❌ FAILURE: Encoding failed in init!")
             return
        } else {
             appendLog("✅ Encoding successful. Translation JSON size: \(newSong.translationsJSON!.count) bytes")
        }
        
        modelContext.insert(newSong)
        
        do {
            try modelContext.save()
            appendLog("✅ Saved to SwiftData successfully.")
        } catch {
            appendLog("❌ FAILURE: Could not save context: \(error)")
        }
    }
    
    private func loadAndDecodeSong() {
        guard let song = songs.first else {
            appendLog("⚠️ No songs found in DB. Create one first.")
            return
        }
        
        appendLog("Loading song: \(song.title)")
        
        // Test Decoding Translations
        if let tData = song.translationsJSON {
            do {
                let decoded = try JSONDecoder().decode([Int: String].self, from: tData)
                let firstLine = decoded[0] ?? "MISSING"
                decodedTranslation = firstLine
                appendLog("✅ Translations decoded. Line 0: \"\(firstLine)\"")
            } catch {
                appendLog("❌ Translation Decode Failed: \(error)")
            }
        } else {
            appendLog("❌ Translation JSON is NIL")
        }
        
        // Test Decoding Lyrics Data
        if let lData = song.lyricsDataJSON {
            do {
                let decoded = try JSONDecoder().decode([LyricsLine].self, from: lData)
                if let firstLine = decoded.first {
                    decodedWordCount = firstLine.words.count
                    decodedTitle = song.title
                    appendLog("✅ LyricsData decoded. Line 0 has \(firstLine.words.count) words.")
                    
                    // Deep check
                    let firstWord = firstLine.words.first?.furigana ?? "N/A"
                    appendLog("   First word furigana: \(firstWord)")
                } else {
                    appendLog("⚠️ LyricsData decoded but empty.")
                }
            } catch {
                 appendLog("❌ LyricsData Decode Failed: \(error)")
            }
        } else {
             appendLog("❌ LyricsData JSON is NIL")
        }
    }
    
    private func appendLog(_ text: String) {
        print(text)
        log += "\n" + text
    }
}

#Preview {
    SmokeTestView()
        .modelContainer(for: Song.self, inMemory: true)
}
