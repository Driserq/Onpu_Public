//
//  OnboardingSampleContentTests.swift
//  UtaTests
//
//  Unit tests for OnboardingSampleContent structure
//

import Testing
@testable import Uta

struct OnboardingSampleContentTests {
    
    // MARK: - Basic Structure Tests
    
    @Test("bashoHaiku has non-empty Japanese text")
    func testBashoHaikuHasJapaneseText() {
        let content = OnboardingSampleContent.bashoHaiku
        #expect(!content.japaneseText.isEmpty, "Japanese text should not be empty")
        #expect(content.japaneseText == "旅に病んで\n夢は枯野を\nかけ廻る", "Japanese text should match Bashō's poem")
    }
    
    @Test("bashoHaiku has populated furigana array")
    func testBashoHaikuHasFurigana() {
        let content = OnboardingSampleContent.bashoHaiku
        #expect(!content.furigana.isEmpty, "Furigana array should not be empty")
        #expect(content.furigana.count == 6, "Should have furigana for 6 Kanji characters")
        
        // Verify each furigana annotation has valid range and reading
        for (range, reading) in content.furigana {
            #expect(!reading.isEmpty, "Furigana reading should not be empty")
            #expect(range.lowerBound < range.upperBound, "Furigana range should be valid")
            
            // Verify the range points to a valid substring in the Japanese text
            let substring = String(content.japaneseText[range])
            #expect(!substring.isEmpty, "Furigana range should point to valid substring")
        }
    }
    
    @Test("bashoHaiku has non-empty English translation")
    func testBashoHaikuHasEnglishTranslation() {
        let content = OnboardingSampleContent.bashoHaiku
        #expect(!content.englishTranslation.isEmpty, "English translation should not be empty")
        #expect(content.englishTranslation.contains("journey"), "Translation should mention 'journey'")
    }
    
    @Test("targetKanjiRange points to valid substring (枯)")
    func testTargetKanjiRangeIsValid() {
        let content = OnboardingSampleContent.bashoHaiku
        
        // Verify range is valid
        #expect(content.targetKanjiRange.lowerBound < content.targetKanjiRange.upperBound,
                "Target Kanji range should be valid")
        
        // Verify it points to the 枯 character
        let targetKanji = String(content.japaneseText[content.targetKanjiRange])
        #expect(targetKanji == "枯", "Target Kanji should be 枯 (ka)")
        
        // Verify the range is within the Japanese text bounds
        #expect(content.targetKanjiRange.upperBound <= content.japaneseText.endIndex,
                "Target range should be within text bounds")
    }
    
    // MARK: - LyricsData Structure Tests
    
    @Test("bashoHaiku has populated lyricsData")
    func testBashoHaikuHasLyricsData() {
        let content = OnboardingSampleContent.bashoHaiku
        #expect(!content.lyricsData.isEmpty, "Lyrics data should not be empty")
        #expect(content.lyricsData.count == 3, "Should have three lines for the poem")

        for line in content.lyricsData {
            #expect(!line.words.isEmpty, "Line should have words")
        }
    }
    
    @Test("lyricsData words have valid structure")
    func testLyricsDataWordsStructure() {
        let content = OnboardingSampleContent.bashoHaiku
        let words = content.lyricsData.flatMap { $0.words }

        // Verify each word has required data
        for word in words {
            #expect(!word.furigana.isEmpty, "Each word should have furigana")
            #expect(!word.mora.isEmpty, "Each word should have mora data")

            // If word has kanji, it should have kanjiFurigana
            if word.kanji != nil {
                #expect(!word.kanjiFurigana.isEmpty,
                       "Words with kanji should have kanjiFurigana annotations")
            }
        }
    }
    
    @Test("lyricsData contains target Kanji (枯)")
    func testLyricsDataContainsTargetKanji() {
        let content = OnboardingSampleContent.bashoHaiku
        let words = content.lyricsData.flatMap { $0.words }
        
        // Find the word containing 枯
        let hasTargetKanji = words.contains { word in
            word.kanji?.contains("枯") == true
        }
        
        #expect(hasTargetKanji, "Lyrics data should contain the target Kanji 枯")
    }
    
    @Test("furigana annotations match lyricsData kanjiFurigana")
    func testFuriganaConsistency() {
        let content = OnboardingSampleContent.bashoHaiku
        
        // Verify that the furigana annotations are consistent with kanjiFurigana in lyricsData
        let kanjiFuriganaFromLyrics = content.lyricsData.flatMap { $0.words }
            .flatMap { $0.kanjiFurigana }
        
        #expect(kanjiFuriganaFromLyrics.count == content.furigana.count,
                "Number of furigana annotations should match kanjiFurigana entries")
        
        // Verify each Kanji in furigana array appears in kanjiFurigana
        for (range, reading) in content.furigana {
            let kanji = String(content.japaneseText[range])
            let matchingEntry = kanjiFuriganaFromLyrics.first { $0.kanji == kanji }
            
            #expect(matchingEntry != nil, "Kanji \(kanji) should appear in kanjiFurigana")
            if let entry = matchingEntry {
                #expect(entry.reading == reading, 
                       "Reading for \(kanji) should match: expected \(reading), got \(entry.reading)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("bashoHaiku is compatible with LyricsView requirements")
    func testLyricsViewCompatibility() {
        let content = OnboardingSampleContent.bashoHaiku
        
        // Verify structure matches what LyricsView expects
        #expect(!content.lyricsData.isEmpty, "Should have lyrics lines")
        
        for line in content.lyricsData {
            #expect(!line.words.isEmpty, "Each line should have words")
            
            for word in line.words {
                // Verify WordData structure is complete
                #expect(!word.furigana.isEmpty, "Word should have furigana")
                #expect(!word.mora.isEmpty, "Word should have mora for pitch accent")
                
                // Verify mora data is valid
                for mora in word.mora {
                    #expect(!mora.text.isEmpty, "Mora text should not be empty")
                }
            }
        }
    }
}
