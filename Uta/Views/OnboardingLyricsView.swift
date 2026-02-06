//
//  OnboardingLyricsView.swift
//  Uta
//
//  Simplified lyrics view for onboarding that displays sample content
//  without requiring SwiftData persistence
//

import SwiftUI

/// Simplified lyrics view for onboarding that displays bundled sample content.
/// This view reuses the core rendering logic from LyricsView but operates on
/// static sample data rather than persisted Song objects.
///
/// Requirements: 1.4, 3.4, 5.2, 11.1
struct OnboardingLyricsView: View {
    let sampleContent: OnboardingSampleContent
    @Binding var showTranslation: Bool
    
    @State private var readingMode: ReadingMode = .furigana
    
    var body: some View {
        let translationLines = sampleContent.englishTranslation
            .split(separator: "\n")
            .map(String.init)

        VStack(spacing: 0) {
            // Top toolbar (simplified for onboarding)
            HStack {
                Spacer()
                
                Text("Bashō Haiku")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
            .background(Color.appBackground)
            .shadow(color: Color.appShadow, radius: 2, x: 0, y: 1)
            
            // Content - single line for onboarding
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sampleContent.lyricsData.enumerated()), id: \.offset) { index, line in
                        VStack(alignment: .leading, spacing: 12) {
                            // Japanese Line with furigana
                            PitchAccentLineView(
                                words: line.words,
                                mode: readingMode,
                                onKanjiLongPress: { _ in }
                            )
                            
                            // Translation - controlled by showTranslation binding
                            if showTranslation {
                                Text(translationLines.indices.contains(index) ? translationLines[index] : "")
                                    .font(.body)
                                    .foregroundStyle(.blue)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appTranslationBackground)
                                    .clipShape(.rect(cornerRadius: 8))
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview("Translation Hidden") {
    OnboardingLyricsView(
        sampleContent: OnboardingSampleContent.bashoHaiku,
        showTranslation: .constant(false)
    )
}

#Preview("Translation Visible") {
    OnboardingLyricsView(
        sampleContent: OnboardingSampleContent.bashoHaiku,
        showTranslation: .constant(true)
    )
}
