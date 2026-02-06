//
//  OnboardingSampleContent.swift
//  Uta
//
//  Created for Interactive Onboarding Module
//  Provides bundled public-domain Japanese text for tutorial
//

import Foundation

/// Static structure providing bundled tutorial content for onboarding
/// Uses Bashō's famous haiku as sample text to teach core app interactions
struct OnboardingSampleContent {
    /// The Japanese text to display
    let japaneseText: String
    
    /// Furigana annotations for Kanji characters (range and reading pairs)
    let furigana: [(range: Range<String.Index>, reading: String)]
    
    /// English translation of the Japanese text
    let englishTranslation: String
    
    /// Range pointing to the target Kanji character for Step 2 (long-press interaction)
    let targetKanjiRange: Range<String.Index>
    
    /// Structured lyrics data compatible with LyricsView rendering
    let lyricsData: [LyricsLine]
    
    /// Bashō's farewell poem: "Fallen sick on my journey / My dreams wander / Over withered fields"
    /// Public domain text used for onboarding tutorial
    static let bashoHaiku: OnboardingSampleContent = {
        let text = "旅に病んで\n夢は枯野を\nかけ廻る"

        // Create furigana annotations for each Kanji
        let furiganaAnnotations: [(range: Range<String.Index>, reading: String)] = [
            (text.range(of: "旅")!, "たび"),
            (text.range(of: "病")!, "や"),
            (text.range(of: "夢")!, "ゆめ"),
            (text.range(of: "枯")!, "か"),
            (text.range(of: "野")!, "の"),
            (text.range(of: "廻")!, "まわ")
        ]

        // Target Kanji for Step 2 (long-press interaction)
        let targetRange = text.range(of: "枯")!

        // Create structured lyrics data compatible with LyricsView
        // Breaking the poem into three lines with furigana and pitch accent data
        let lyricsData = [
            LyricsLine(words: [
                WordData(
                    kanji: "旅",
                    furigana: "たび",
                    mora: [
                        MoraData(text: "た", isHigh: false),
                        MoraData(text: "び", isHigh: true)
                    ],
                    kanjiFurigana: [
                        KanjiFurigana(kanji: "旅", reading: "たび")
                    ]
                ),
                WordData(
                    kanji: nil,
                    furigana: "に",
                    mora: [
                        MoraData(text: "に", isHigh: true)
                    ],
                    kanjiFurigana: []
                ),
                WordData(
                    kanji: "病",
                    furigana: "や",
                    mora: [
                        MoraData(text: "や", isHigh: false)
                    ],
                    kanjiFurigana: [
                        KanjiFurigana(kanji: "病", reading: "や")
                    ]
                ),
                WordData(
                    kanji: nil,
                    furigana: "んで",
                    mora: [
                        MoraData(text: "ん", isHigh: false),
                        MoraData(text: "で", isHigh: true)
                    ],
                    kanjiFurigana: []
                )
            ]),
            LyricsLine(words: [
                WordData(
                    kanji: "夢",
                    furigana: "ゆめ",
                    mora: [
                        MoraData(text: "ゆ", isHigh: false),
                        MoraData(text: "め", isHigh: true)
                    ],
                    kanjiFurigana: [
                        KanjiFurigana(kanji: "夢", reading: "ゆめ")
                    ]
                ),
                WordData(
                    kanji: nil,
                    furigana: "は",
                    mora: [
                        MoraData(text: "は", isHigh: true)
                    ],
                    kanjiFurigana: []
                ),
                WordData(
                    kanji: "枯野",
                    furigana: "かれの",
                    mora: [
                        MoraData(text: "か", isHigh: false),
                        MoraData(text: "れ", isHigh: true),
                        MoraData(text: "の", isHigh: true)
                    ],
                    kanjiFurigana: [
                        KanjiFurigana(kanji: "枯", reading: "か"),
                        KanjiFurigana(kanji: "野", reading: "の")
                    ]
                ),
                WordData(
                    kanji: nil,
                    furigana: "を",
                    mora: [
                        MoraData(text: "を", isHigh: true)
                    ],
                    kanjiFurigana: []
                )
            ]),
            LyricsLine(words: [
                WordData(
                    kanji: nil,
                    furigana: "かけ",
                    mora: [
                        MoraData(text: "か", isHigh: false),
                        MoraData(text: "け", isHigh: true)
                    ],
                    kanjiFurigana: []
                ),
                WordData(
                    kanji: "廻",
                    furigana: "まわ",
                    mora: [
                        MoraData(text: "ま", isHigh: false),
                        MoraData(text: "わ", isHigh: true)
                    ],
                    kanjiFurigana: [
                        KanjiFurigana(kanji: "廻", reading: "まわ")
                    ]
                ),
                WordData(
                    kanji: nil,
                    furigana: "る",
                    mora: [
                        MoraData(text: "る", isHigh: true)
                    ],
                    kanjiFurigana: []
                )
            ])
        ]

        return OnboardingSampleContent(
            japaneseText: text,
            furigana: furiganaAnnotations,
            englishTranslation: "Fallen sick on my journey\nMy dreams wander\nOver withered fields",
            targetKanjiRange: targetRange,
            lyricsData: lyricsData
        )
    }()
}
