import SwiftUI
import SwiftData

struct LyricsView: View {
    @Bindable var song: Song

    private let directLyricsLines: [LyricsLine]?
    private let directTranslations: [Int: String]?
    private let isOnboardingActive: Bool
    private let onboardingStep: OnboardingStep
    private let onboardingTargetLineIndex: Int
    private let onboardingTargetKanji: String?
    @Binding private var onboardingShowTranslation: Bool
    private let onOnboardingLineTap: (() -> Void)?
    private let onOnboardingNextArrowTap: (() -> Void)?
    private let onOnboardingKanjiLongPress: (() -> Void)?
    private let onOnboardingKanjiModalDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLineIndex: Int?
    @State private var readingMode: ReadingMode = .none
    @State private var viewMode: ViewMode = .block
    @State private var kanjiForModal: KanjiData?

    @State private var scrollToIndex: Int?
    
    enum ViewMode {
        case block
        case parallel
    }
    
    // Decoded data (Lazy loaded)
    @State private var lyricsLines: [LyricsLine] = []
    @State private var translations: [Int: String] = [:]

    init(
        song: Song,
        isOnboardingActive: Bool = false,
        onboardingStep: OnboardingStep = .tapToReveal,
        onboardingTargetLineIndex: Int = 0,
        onboardingTargetKanji: String? = nil,
        onboardingShowTranslation: Binding<Bool> = .constant(false),
        onOnboardingLineTap: (() -> Void)? = nil,
        onOnboardingNextArrowTap: (() -> Void)? = nil,
        onOnboardingKanjiLongPress: (() -> Void)? = nil,
        onOnboardingKanjiModalDismiss: (() -> Void)? = nil
    ) {
        self._song = Bindable(wrappedValue: song)
        self.directLyricsLines = nil
        self.directTranslations = nil
        self.isOnboardingActive = isOnboardingActive
        self.onboardingStep = onboardingStep
        self.onboardingTargetLineIndex = onboardingTargetLineIndex
        self.onboardingTargetKanji = onboardingTargetKanji
        self._onboardingShowTranslation = onboardingShowTranslation
        self.onOnboardingLineTap = onOnboardingLineTap
        self.onOnboardingNextArrowTap = onOnboardingNextArrowTap
        self.onOnboardingKanjiLongPress = onOnboardingKanjiLongPress
        self.onOnboardingKanjiModalDismiss = onOnboardingKanjiModalDismiss
        self._readingMode = State(initialValue: isOnboardingActive ? .furigana : .none)
        self._viewMode = State(initialValue: .block)
    }

    init(
        lyricsLines: [LyricsLine],
        translations: [Int: String],
        isOnboardingActive: Bool = true,
        onboardingStep: OnboardingStep = .tapToReveal,
        onboardingTargetLineIndex: Int = 0,
        onboardingTargetKanji: String? = nil,
        onboardingShowTranslation: Binding<Bool> = .constant(false),
        onOnboardingLineTap: (() -> Void)? = nil,
        onOnboardingNextArrowTap: (() -> Void)? = nil,
        onOnboardingKanjiLongPress: (() -> Void)? = nil,
        onOnboardingKanjiModalDismiss: (() -> Void)? = nil
    ) {
        let placeholderSong = Song(
            title: "Onboarding",
            artist: "",
            lyricsRaw: lyricsLines.first?.words.map { $0.kanji ?? $0.furigana }.joined() ?? "",
            translations: translations,
            lyricsData: lyricsLines
        )
        self._song = Bindable(wrappedValue: placeholderSong)
        self.directLyricsLines = lyricsLines
        self.directTranslations = translations
        self.isOnboardingActive = isOnboardingActive
        self.onboardingStep = onboardingStep
        self.onboardingTargetLineIndex = onboardingTargetLineIndex
        self.onboardingTargetKanji = onboardingTargetKanji
        self._onboardingShowTranslation = onboardingShowTranslation
        self.onOnboardingLineTap = onOnboardingLineTap
        self.onOnboardingNextArrowTap = onOnboardingNextArrowTap
        self.onOnboardingKanjiLongPress = onOnboardingKanjiLongPress
        self.onOnboardingKanjiModalDismiss = onOnboardingKanjiModalDismiss
        self._readingMode = State(initialValue: .furigana)
        self._viewMode = State(initialValue: .block)
    }
    
    var body: some View {
        let shouldHandleOnboardingTap = isOnboardingActive && onboardingStep == .tapToReveal

        VStack(spacing: 0) {
            // Top toolbar (custom)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .padding(8)
                        .foregroundStyle(AppStyle.Colors.accent)
                }

                Spacer()

                Button(action: {
                    withAnimation { viewMode = viewMode == .block ? .parallel : .block }
                }) {
                    Image(systemName: viewMode == .block ? "rectangle.split.2x1" : "rectangle.grid.1x2")
                        .padding(8)
                        .background(viewMode == .parallel ? AppStyle.Colors.accentLight : Color.clear)
                        .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                }
                .disabled(isOnboardingActive)

                Button(action: {
                    withAnimation {
                        readingMode = (readingMode == .furigana) ? .none : .furigana
                    }
                }) {
                    Image(systemName: "textformat.size")
                        .padding(8)
                        .background(readingMode == .furigana ? AppStyle.Colors.accentLight : Color.clear)
                        .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                }
                .disabled(isOnboardingActive)

                Button(action: {
                    withAnimation {
                        readingMode = (readingMode == .pitch) ? .none : .pitch
                    }
                }) {
                    Image(systemName: "waveform.path.ecg")
                        .padding(8)
                        .background(readingMode == .pitch ? AppStyle.Colors.accentLight : Color.clear)
                        .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                }
                .disabled(isOnboardingActive)
            }
            .padding()
            .background(AppStyle.Colors.background)
            .shadow(color: AppStyle.Colors.shadow, radius: 2, x: 0, y: 1)

            // Content
            if viewMode == .block {
                BlockModeView(
                    lines: lyricsLines,
                    translations: translations,
                    selectedLineIndex: $selectedLineIndex,
                    scrollToIndex: $scrollToIndex,
                    readingMode: readingMode,
                    onKanjiLongPress: handleKanjiLongPress,
                    onOnboardingLineTap: onOnboardingLineTap,
                    shouldHandleOnboardingTap: shouldHandleOnboardingTap,
                    onboardingTargetLineIndex: onboardingTargetLineIndex
                )
            } else {
                ParallelModeView(
                    lines: lyricsLines,
                    translations: translations,
                    selectedLineIndex: $selectedLineIndex,
                    scrollToIndex: $scrollToIndex,
                    readingMode: readingMode,
                    onKanjiLongPress: handleKanjiLongPress,
                    onOnboardingLineTap: onOnboardingLineTap,
                    shouldHandleOnboardingTap: shouldHandleOnboardingTap,
                    onboardingTargetLineIndex: onboardingTargetLineIndex
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            BottomLineNavBar(
                selectedLineIndex: $selectedLineIndex,
                lineCount: lyricsLines.count,
                onNavigate: { nextIndex in
                    // All three happen simultaneously now - no layout shifts
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedLineIndex = nextIndex
                        scrollToIndex = nextIndex
                    }
                },
                onNextArrowTap: {
                    onOnboardingNextArrowTap?()
                }
            )
        }
        .onAppear {
            decodeData()
            if isOnboardingActive {
                updateTranslationVisibility(isVisible: onboardingShowTranslation)
            }
        }
        .onChange(of: onboardingShowTranslation) { _, newValue in
            updateTranslationVisibility(isVisible: newValue)
        }
        .sheet(item: $kanjiForModal) { data in
            KanjiModalView(data: data)
        }
        .onChange(of: kanjiForModal == nil) { wasNil, isNil in
            guard isOnboardingActive else { return }
            guard !wasNil, isNil else { return }
            onOnboardingKanjiModalDismiss?()
        }
    }
    
    private func updateTranslationVisibility(isVisible: Bool) {
        guard isOnboardingActive else { return }
        if isVisible {
            selectedLineIndex = onboardingTargetLineIndex
            scrollToIndex = onboardingTargetLineIndex
        } else {
            selectedLineIndex = nil
        }
    }

    private func decodeData() {
        if let directLyricsLines, let directTranslations {
            lyricsLines = directLyricsLines
            translations = directTranslations
            return
        }

        if let tData = song.translationsJSON {
            translations = (try? JSONDecoder().decode([Int: String].self, from: tData)) ?? [:]
        }

        if let lData = song.lyricsDataJSON {
            lyricsLines = (try? JSONDecoder().decode([LyricsLine].self, from: lData)) ?? []
        }
    }
    
    private func handleKanjiLongPress(char: String) {
        if isOnboardingActive,
           onboardingStep == .longPressKanji {
            onOnboardingKanjiLongPress?()
        }

        if let data = KanjiService.shared.getKanji(char) {
            kanjiForModal = data
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

private struct BottomLineNavBar: View {
    @Binding var selectedLineIndex: Int?
    let lineCount: Int
    let onNavigate: (Int) -> Void
    let onNextArrowTap: (() -> Void)?

    private var isEnabled: Bool {
        selectedLineIndex != nil && lineCount > 0
    }

    var body: some View {
        HStack {
            Button {
                guard let i = selectedLineIndex else { return }
                onNavigate(max(0, i - 1))
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appAccent)
            }
            .disabled(!isEnabled)

            Spacer()

            Button {
                guard let i = selectedLineIndex else { return }
                onNavigate(min(max(0, lineCount - 1), i + 1))
                onNextArrowTap?()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appAccent)
            }
            .disabled(!isEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .opacity(isEnabled ? 1 : 0.3)
    }
}

// MARK: - Block Mode
struct BlockModeView: View {
    let lines: [LyricsLine]
    let translations: [Int: String]
    @Binding var selectedLineIndex: Int?
    @Binding var scrollToIndex: Int?
    let readingMode: ReadingMode
    let onKanjiLongPress: (String) -> Void
    let onOnboardingLineTap: (() -> Void)?
    let shouldHandleOnboardingTap: Bool
    let onboardingTargetLineIndex: Int
    
    // Translation mode: once user taps a line, all translations show (dimmed/highlighted)
    // This prevents layout shifts during arrow navigation
    private var isTranslationModeActive: Bool {
        selectedLineIndex != nil
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.md) {
                        // Japanese Line
                        PitchAccentLineView(
                            words: line.words,
                            mode: readingMode,
                            onKanjiLongPress: onKanjiLongPress
                        )
                        
                        // Translation - only visible when translation mode is active
                        if isTranslationModeActive {
                            Text(translations[index] ?? "No translation")
                                .font(.body)
                                .foregroundStyle(selectedLineIndex == index ? Color.blue : Color.blue.opacity(0.3))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedLineIndex == index ? AppStyle.Colors.translationBackground : AppStyle.Colors.translationBackground.opacity(0.3))
                                .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                                .animation(.easeInOut(duration: 0.15), value: selectedLineIndex)
                        }
                    }
                    .padding(.vertical, AppStyle.Spacing.sm)
                    .id(index)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            if selectedLineIndex == index {
                                // Tap same line = exit translation mode
                                selectedLineIndex = nil
                            } else {
                                // Tap new line = enter/switch translation mode
                                selectedLineIndex = index
                                scrollToIndex = index
                            }
                        }

                        if shouldHandleOnboardingTap && index == onboardingTargetLineIndex {
                            onOnboardingLineTap?()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: scrollToIndex) { _, newValue in
                guard let newValue else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    proxy.scrollTo(newValue, anchor: .top)
                }
            }
        }
    }
}

// MARK: - Parallel Mode
struct ParallelModeView: View {
    let lines: [LyricsLine]
    let translations: [Int: String]
    @Binding var selectedLineIndex: Int?
    @Binding var scrollToIndex: Int?
    let readingMode: ReadingMode
    let onKanjiLongPress: (String) -> Void
    let onOnboardingLineTap: (() -> Void)?
    let shouldHandleOnboardingTap: Bool
    let onboardingTargetLineIndex: Int

    @StateObject private var scrollSync = ScrollSyncGroup()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { jpProxy in
                ScrollViewReader { enProxy in
                    VStack(spacing: 0) {
                        // Top Half: Japanese
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppStyle.Spacing.lg) {
                                ScrollViewIntrospector(pane: .jp, group: scrollSync)
                                    .frame(width: 0, height: 0)
                                    .allowsHitTesting(false)

                                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                    PitchAccentLineView(
                                        words: line.words,
                                        mode: readingMode,
                                        onKanjiLongPress: onKanjiLongPress
                                    )
                                    .padding()
                                    .background(selectedLineIndex == index ? AppStyle.Colors.highlight : Color.clear)
                                    .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                                    .id(index)
                                    .onTapGesture {
                                        // For tap in parallel mode: immediate response
                                        selectedLineIndex = index
                                        scrollToIndex = index

                                        if shouldHandleOnboardingTap && index == onboardingTargetLineIndex {
                                            onOnboardingLineTap?()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .frame(height: geometry.size.height * 0.5)

                        Divider()

                        // Bottom Half: English
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppStyle.Spacing.lg) {
                                ScrollViewIntrospector(pane: .en, group: scrollSync)
                                    .frame(width: 0, height: 0)
                                    .allowsHitTesting(false)

                                ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                                    Text(translations[index] ?? "...")
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(selectedLineIndex == index ? AppStyle.Colors.highlight : Color.clear)
                                        .clipShape(.rect(cornerRadius: AppStyle.Radii.xs))
                                        .id(index)
                                        .onTapGesture {
                                            // For tap in parallel mode: immediate response
                                            selectedLineIndex = index
                                            scrollToIndex = index
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    .onChange(of: scrollToIndex) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            jpProxy.scrollTo(newValue, anchor: .top)
                            enProxy.scrollTo(newValue, anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Kanji Modal
struct KanjiModalView: View {
    let data: KanjiData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Big Character
                    Text(data.character)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                        .padding(.top, 20)
                    
                    // Meaning
                    VStack(spacing: 8) {
                        Text("MEANING")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text(data.meaning)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }
                    
                    Divider()
                    
                    // Readings
                    HStack(alignment: .top, spacing: 40) {
                        if let onyomi = data.onyomi {
                            VStack(spacing: 4) {
                                Text("ON'YOMI")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Text(onyomi)
                                    .font(.headline)
                            }
                        }
                        
                        if let kunyomi = data.kunyomi {
                            VStack(spacing: 4) {
                                Text("KUN'YOMI")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Text(kunyomi)
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(AppStyle.Colors.backgroundTertiary)
                    .clipShape(.rect(cornerRadius: AppStyle.Radii.sm))
                    
                    // Mnemonic
                    VStack(spacing: 8) {
                        Text("MEMORY AID")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text(data.mnemonic)
                            .font(.body)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(AppStyle.Colors.warningBackground)
                            .clipShape(.rect(cornerRadius: AppStyle.Radii.sm))
                    }
                    .padding(.horizontal)
                    
                    // Radicals
                    VStack(spacing: 8) {
                        Text("RADICALS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(alignment: .center, spacing: 8) {
                            ForEach(data.radicals, id: \.self) { radical in
                                Text(radical)
                                    .font(.callout)
                                    .padding(.horizontal, AppStyle.Spacing.md)
                                    .padding(.vertical, 6)
                                    .background(AppStyle.Colors.translationBackground)
                                    .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Kanji Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
