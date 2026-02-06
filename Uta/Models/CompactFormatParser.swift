import Foundation

// MARK: - Compact Format Parser
// Parses compact format strings: Word|Reading|PitchMap joined by underscore
// Format: "夏|なつ|01_が|が|0"
// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 5.1

/// Errors that can occur during compact format parsing
enum CompactFormatError: Error, LocalizedError {
    case invalidSegmentFormat(segment: String, expected: String)
    case invalidPitchMap(pitchMap: String, reason: String)
    case invalidReading(reading: String, reason: String)
    case emptyInput
    
    var errorDescription: String? {
        switch self {
        case .invalidSegmentFormat(let segment, let expected):
            return "Invalid segment format: '\(segment)'. Expected: \(expected)"
        case .invalidPitchMap(let pitchMap, let reason):
            return "Invalid PitchMap '\(pitchMap)': \(reason)"
        case .invalidReading(let reading, let reason):
            return "Invalid reading '\(reading)': \(reason)"
        case .emptyInput:
            return "Empty input string"
        }
    }
}

/// Detect if a string is compact format or JSON
/// - Parameter data: Response data string
/// - Returns: true if compact format, false if JSON
func isCompactFormat(_ data: String) -> Bool {
    let trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
    // Compact format contains pipes and no JSON braces
    return trimmed.contains("|") && !trimmed.contains("{") && !trimmed.contains("[")
}

/// Parse compact format string to LyricsLine
/// - Parameter compactStr: Compact format string (e.g., "夏|なつ|01_が|が|0")
/// - Returns: LyricsLine with parsed WordData array
/// - Throws: CompactFormatError if format is invalid
func parseCompactFormat(_ compactStr: String) throws -> LyricsLine {
    let trimmed = compactStr.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !trimmed.isEmpty else {
        throw CompactFormatError.emptyInput
    }
    
    // Split on underscore to get word segments
    let segments = trimmed.split(separator: "_").map(String.init)
    
    var words: [WordData] = []
    
    for segment in segments {
        let word = try parseWordSegment(segment)
        words.append(word)
    }
    
    return LyricsLine(words: words)
}

/// Parse a single word segment to WordData
/// - Parameter segment: Word segment (e.g., "夏|なつ|01|なつ" or "君の手|きみのて|0111|きみ,て")
/// - Returns: WordData struct
/// - Throws: CompactFormatError if segment is invalid
func parseWordSegment(_ segment: String) throws -> WordData {
    // Split on pipe to get components (preserving empty strings)
    let parts = segment.components(separatedBy: "|")
    
    // Support both 3-part (legacy) and 4-part (new) formats
    guard parts.count >= 3 && parts.count <= 4 else {
        throw CompactFormatError.invalidSegmentFormat(
            segment: segment,
            expected: "Word|Reading|PitchMap[|KanjiReadings] (3 or 4 pipe-separated components)"
        )
    }
    
    let word = parts[0]
    let reading = parts[1]
    let pitchMap = parts[2]
    // Optional 4th component: comma-separated readings for each kanji
    let kanjiReadingsRaw = parts.count == 4 ? parts[3] : ""
    
    // Word must always be present
    guard !word.isEmpty else {
        throw CompactFormatError.invalidSegmentFormat(
            segment: segment,
            expected: "Word component must not be empty"
        )
    }
    
    // Handle English/romaji words (empty reading and empty pitchMap)
    if reading.isEmpty && pitchMap.isEmpty {
        return WordData(
            kanji: nil,
            furigana: word,  // Display the English word as-is
            mora: [],        // No mora data for English words
            kanjiFurigana: []
        )
    }
    
    // For Japanese words, both reading and pitchMap must be non-empty
    guard !reading.isEmpty else {
        throw CompactFormatError.invalidReading(reading: reading, reason: "Reading cannot be empty for Japanese words")
    }
    
    guard !pitchMap.isEmpty else {
        throw CompactFormatError.invalidPitchMap(pitchMap: pitchMap, reason: "PitchMap cannot be empty for Japanese words")
    }
    
    // Validate PitchMap is binary
    guard pitchMap.allSatisfy({ $0 == "0" || $0 == "1" }) else {
        throw CompactFormatError.invalidPitchMap(
            pitchMap: pitchMap,
            reason: "Must contain only '0' and '1' characters"
        )
    }
    
    // Extract mora from reading
    let mora = try extractMora(reading: reading, pitchMap: pitchMap)
    
    // Determine kanji field
    // If word differs from reading, it contains kanji
    let kanji: String? = (word != reading) ? word : nil
    
    // Process Kanji Readings
    var kanjiFurigana: [KanjiFurigana] = []
    
    if let kanjiText = kanji {
        // If we have explicit kanji readings from the new format
        if !kanjiReadingsRaw.isEmpty {
            let readingsList = kanjiReadingsRaw.components(separatedBy: ",")
            var readingIndex = 0
            
            for char in kanjiText {
                if char.isKanjiCharacter {
                    if readingIndex < readingsList.count {
                        let r = readingsList[readingIndex]
                        kanjiFurigana.append(KanjiFurigana(kanji: String(char), reading: r))
                        readingIndex += 1
                    }
                }
            }
        }
    }
    
    return WordData(
        kanji: kanji,
        furigana: reading,
        mora: mora,
        kanjiFurigana: kanjiFurigana
    )
}

private extension Character {
    var isKanjiCharacter: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0xF900...0xFAFF:
                return true
            default:
                return false
            }
        }
    }
}

/// Extract mora from hiragana reading based on Japanese phonology
/// - Parameters:
///   - reading: Hiragana reading string
///   - pitchMap: Binary pitch map string
/// - Returns: Array of MoraData
/// - Throws: CompactFormatError if reading is empty or pitchMap is invalid
func extractMora(reading: String, pitchMap: String) throws -> [MoraData] {
    // Trust Gemini's PitchMap length as the authoritative mora count
    // Gemini understands Japanese phonology better than our simple algorithm
    let targetMoraCount = pitchMap.count
    
    guard targetMoraCount > 0 else {
        throw CompactFormatError.invalidPitchMap(pitchMap: pitchMap, reason: "Empty PitchMap")
    }
    
    let chars = Array(reading)
    guard !chars.isEmpty else {
        throw CompactFormatError.invalidReading(reading: reading, reason: "Empty reading")
    }
    
    // First pass: estimate mora using our algorithm
    var estimatedMora: [String] = []
    var i = 0
    
    while i < chars.count {
        let currentChar = chars[i]
        
        // Check if next character is a small kana (but NOT っ - it's a separate mora for pitch)
        if i + 1 < chars.count && isSmallKanaForCombining(chars[i + 1]) {
            // Combine current + next as single mora
            let moraText = String(currentChar) + String(chars[i + 1])
            estimatedMora.append(moraText)
            i += 2
        } else {
            // Single character mora (including っ, ー which are separate mora)
            let moraText = String(currentChar)
            estimatedMora.append(moraText)
            i += 1
        }
    }
    
    // If our estimate matches Gemini's count, use it directly
    if estimatedMora.count == targetMoraCount {
        return estimatedMora.enumerated().map { index, text in
            MoraData(text: text, isHigh: pitchMap[pitchMap.index(pitchMap.startIndex, offsetBy: index)] == "1")
        }
    }
    
    // If counts don't match, trust Gemini and use character-by-character splitting
    // This handles edge cases like special contracted sounds
    #if DEBUG
    print("[CompactFormatParser] Mora count mismatch for '\(reading)': estimated \(estimatedMora.count), PitchMap has \(targetMoraCount). Using character-based splitting.")
    #endif
    
    // Strategy: Split reading character-by-character
    var moraArray: [MoraData] = []
    
    for (index, char) in chars.enumerated() {
        // Get pitch value: use PitchMap if available, otherwise default to low (0)
        let isHigh: Bool
        if index < targetMoraCount {
            isHigh = pitchMap[pitchMap.index(pitchMap.startIndex, offsetBy: index)] == "1"
        } else {
            // Safety: extend with low pitch for any extra characters beyond PitchMap
            isHigh = false
        }
        moraArray.append(MoraData(text: String(char), isHigh: isHigh))
    }
    
    // If PitchMap is longer than characters (shouldn't happen, but be safe)
    // We've already processed all characters, so nothing more to do
    
    return moraArray
}

/// Check if a character is a small kana that combines with preceding character
/// Note: っ (small tsu) is NOT included because it's a separate mora for pitch accent
/// - Parameter char: Character to check
/// - Returns: true if small kana that combines, false otherwise
private func isSmallKanaForCombining(_ char: Character) -> Bool {
    let smallKana: Set<Character> = [
        "ゃ", "ゅ", "ょ",  // Small ya, yu, yo
        "ぁ", "ぃ", "ぅ", "ぇ", "ぉ",  // Small vowels
        "ゎ"  // Small wa
        // Note: っ (small tsu) is NOT here - it's a separate mora for pitch accent
    ]
    return smallKana.contains(char)
}
