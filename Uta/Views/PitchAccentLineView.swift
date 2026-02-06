import SwiftUI

enum ReadingMode {
    case none
    case furigana
    case pitch
}

struct PitchAccentLineView: View {
    let words: [WordData]
    let mode: ReadingMode
    let onKanjiLongPress: ((String) -> Void)?

    private let stableMinHeight: CGFloat = 48
    
    // We can use a wrapping layout or a horizontal scroll depending on design.
    // RN version uses `flexWrap: 'wrap'`. SwiftUI's wrapping options:
    // 1. `Layout` protocol (Advanced, flexible)
    // 2. WrappedHStack (Custom)
    // 3. For now, let's use a simple wrapped layout logic or flow layout if available (iOS 16+ has FlowLayout in limited forms, or use a custom one).
    // Actually, standard `Text` concatenation is hard with complex views.
    // We will use a `FlowLayout` implementation for simplicity.
    
    init(
        words: [WordData],
        mode: ReadingMode,
        onKanjiLongPress: ((String) -> Void)? = nil
    ) {
        self.words = words
        self.mode = mode
        self.onKanjiLongPress = onKanjiLongPress
    }

    var body: some View {
        FlowLayout(alignment: .leading, spacing: 2) {
            ForEach(words) { word in
                WordView(
                    word: word,
                    mode: mode,
                    onKanjiLongPress: onKanjiLongPress
                )
            }
        }
        .padding(.top, 24) // Always reserve space for furigana - prevents layout shift
        .frame(minHeight: stableMinHeight, alignment: .bottom)
    }
}

struct WordView: View {
    let word: WordData
    let mode: ReadingMode
    let onKanjiLongPress: ((String) -> Void)?
    
    private var hasKanji: Bool {
        word.kanji != nil
    }
    
    private var mainText: String {
        word.kanji ?? word.furigana
    }

    private var canInteractWithKanji: Bool {
        onKanjiLongPress != nil
    }

    @ViewBuilder
    private func surfaceText(_ text: String) -> some View {
        if canInteractWithKanji {
            KanjiPressableText(
                text: text,
                onKanjiLongPress: onKanjiLongPress
            )
        } else {
            Text(text)
        }
    }
    
    var body: some View {
        Group {
            switch mode {
            case .furigana:
                if hasKanji {
                    if !word.kanjiFurigana.isEmpty {
                        KanjiFuriganaOverlayWordView(
                            surface: word.kanji ?? "",
                            ruby: word.kanjiFurigana,
                            onKanjiLongPress: onKanjiLongPress
                        )
                    } else {
                        // Overlay approach - furigana floats above without spreading characters
                        surfaceText(mainText)
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .fixedSize()
                            .overlay(alignment: .top) {
                                Text(word.furigana)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                    .offset(y: -8)
                                    .allowsHitTesting(false)
                            }
                    }
                } else {
                    // English/kana words - use surfaceText for consistent rendering with .none mode
                    surfaceText(mainText)
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .fixedSize()
                }

            case .pitch:
                // Handle English words (empty mora array)
                if word.mora.isEmpty {
                    surfaceText(mainText)
                        .font(.title3)
                        .foregroundStyle(.primary)
                } else {
                    VStack(spacing: 0) {
                        if hasKanji {
                            PitchMoraRow(mora: word.mora, isFurigana: true)
                        }

                        if !hasKanji {
                            PitchMoraRow(mora: word.mora, isFurigana: false)
                        } else {
                            surfaceText(mainText)
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                    }
                }

            case .none:
                surfaceText(mainText)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .fixedSize()
            }
        }
        .padding(.bottom, 4)
    }
}

private struct KanjiPressableText: View {
    let text: String
    let onKanjiLongPress: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                if ch.isKanjiCharacter {
                    let kanji = String(ch)
                    Text(kanji)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            LongPressGesture(minimumDuration: 0.35)
                                .onEnded { _ in
                                    onKanjiLongPress?(kanji)
                                }
                        )
                } else {
                    Text(String(ch))
                }
            }
        }
    }
}

private struct KanjiFuriganaOverlayWordView: View {
    let surface: String
    let ruby: [KanjiFurigana]
    let onKanjiLongPress: ((String) -> Void)?

    private struct Segment: Hashable {
        var text: String
        var isKanji: Bool
        var reading: String?
    }

    private let segments: [Segment]

    init(
        surface: String,
        ruby: [KanjiFurigana],
        onKanjiLongPress: ((String) -> Void)? = nil
    ) {
        self.surface = surface
        self.ruby = ruby
        self.onKanjiLongPress = onKanjiLongPress

        var idx = 0
        self.segments = surface.map { ch in
            if ch.isKanjiCharacter {
                let reading = idx < ruby.count ? ruby[idx].reading : ""
                idx += 1
                return Segment(text: String(ch), isKanji: true, reading: reading)
            } else {
                return Segment(text: String(ch), isKanji: false, reading: nil)
            }
        }
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            ForEach(runs(from: segments), id: \.self) { run in
                switch run {
                case .kana(let text):
                    Text(text)
                        .font(.title3)
                        .foregroundStyle(.primary)
                case .kanji(let surface, let reading):
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        ForEach(Array(surface), id: \.self) { ch in
                            if ch.isKanjiCharacter {
                                let kanji = String(ch)
                                Text(kanji)
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .highPriorityGesture(
                                        LongPressGesture(minimumDuration: 0.35)
                                            .onEnded { _ in
                                                onKanjiLongPress?(kanji)
                                            }
                                    )
                            } else {
                                Text(String(ch))
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    // Overlay does NOT affect sizing => no spacing shifts.
                    .overlay(alignment: .top) {
                        Text(reading)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                            .offset(y: -8)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    private enum Run: Hashable {
        case kana(String)
        case kanji(surface: String, reading: String)
    }

    private func runs(from segments: [Segment]) -> [Run] {
        var result: [Run] = []
        var i = 0

        while i < segments.count {
            if segments[i].isKanji {
                var surface = ""
                var reading = ""
                while i < segments.count, segments[i].isKanji {
                    surface += segments[i].text
                    reading += segments[i].reading ?? ""
                    i += 1
                }
                result.append(.kanji(surface: surface, reading: reading))
            } else {
                var text = ""
                while i < segments.count, !segments[i].isKanji {
                    text += segments[i].text
                    i += 1
                }
                result.append(.kana(text))
            }
        }

        return result
    }
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

struct PitchMoraRow: View {
    let mora: [MoraData]
    let isFurigana: Bool
    
    // Constants for drawing
    private let strokeWidth: CGFloat = 1.5
    private let strokeColor: Color = .red
    
    // Height logic matches RN: High vs Low relative Y
    // Furigana is small, Main text is big.
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(mora.enumerated()), id: \.offset) { index, item in
                MoraCell(
                    text: item.text,
                    isHigh: item.isHigh,
                    nextIsHigh: index < mora.count - 1 ? mora[index + 1].isHigh : nil,
                    isFurigana: isFurigana
                )
            }
        }
    }
}

struct MoraCell: View {
    let text: String
    let isHigh: Bool
    let nextIsHigh: Bool? // Nil if last mora
    let isFurigana: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Pitch Line Overlay
            PitchLineCanvas(isHigh: isHigh, nextIsHigh: nextIsHigh)
                .frame(height: 6) // Fixed height for the line area
                .padding(.bottom, 2)
            
            // Text
            Text(text)
                .font(isFurigana ? .caption2 : .title3)
                .fixedSize() // Prevent truncation
        }
    }
}

struct PitchLineCanvas: View {
    let isHigh: Bool
    let nextIsHigh: Bool?
    
    var body: some View {
        Canvas { context, size in
            let lineWidth: CGFloat = 1.5
            let color = Color.appPitchAccent
            
            // Coordinates
            // Local frame: (0,0) is top-left
            // High pitch line: Y = 1
            // Low pitch line: Y = size.height - 1
            
            let highY: CGFloat = 1
            let lowY: CGFloat = size.height - 1
            
            let currentY = isHigh ? highY : lowY
            
            // 1. Draw Horizontal Line (Roof)
            // It should cover the width of this mora
            let start = CGPoint(x: 0, y: currentY)
            let end = CGPoint(x: size.width, y: currentY)
            
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
            
            // 2. Draw Vertical Connection (Wall) to next mora
            if let nextHigh = nextIsHigh, nextHigh != isHigh {
                let nextY = nextHigh ? highY : lowY
                
                // Draw vertical line at the right edge
                var vPath = Path()
                vPath.move(to: CGPoint(x: size.width, y: currentY))
                vPath.addLine(to: CGPoint(x: size.width, y: nextY))
                
                context.stroke(vPath, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}

// Simple FlowLayout helper
struct FlowLayout: Layout {
    var alignment: Alignment = .leading
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = generateRows(maxWidth: proposal.width ?? 0, subviews: subviews)
        
        var totalHeight: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            totalHeight += rowHeight + spacing
        }
        return CGSize(width: proposal.width ?? 0, height: max(0, totalHeight - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = generateRows(maxWidth: bounds.width, subviews: subviews)
        
        var yOffset = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var xOffset = bounds.minX
            
            for view in row {
                let viewSize = view.sizeThatFits(.unspecified)
                // Align to bottom of the row to match text baseline roughly
                let yPos = yOffset + (rowHeight - viewSize.height) 
                view.place(at: CGPoint(x: xOffset, y: yPos), proposal: .unspecified)
                xOffset += viewSize.width + spacing
            }
            
            yOffset += rowHeight + spacing
        }
    }
    
    private func generateRows(maxWidth: CGFloat, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = []
        var currentRow: [LayoutSubview] = []
        var currentWidth: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if currentWidth + viewSize.width > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentWidth = 0
            }
            
            currentRow.append(view)
            currentWidth += viewSize.width + spacing
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}
