import SwiftUI

struct DictionaryView: View {
    let isOnboardingActive: Bool
    let onboardingCoachText: String
    let onOnboardingKanjiTap: (() -> Void)?
    let onOnboardingKanjiModalDismiss: (() -> Void)?
    @State private var searchText = ""
    @State private var selectedKanji: KanjiData?
    @State private var collapsedLevels: Set<String> = []
    @State private var showOnboardingCoachMark: Bool = true
    
    // Load data from service
    var allKanji: [KanjiData] {
        KanjiService.shared.allKanji
    }
    
    var filteredKanji: [KanjiData] {
        if searchText.isEmpty {
            return allKanji
        }
        return allKanji.filter { k in
            k.character.localizedCaseInsensitiveContains(searchText) ||
            k.meaning.localizedCaseInsensitiveContains(searchText) ||
            (k.onyomi?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (k.kunyomi?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var groupedByLevel: [(level: String, items: [KanjiData])] {
        let grouped = Dictionary(grouping: allKanji, by: { $0.level })
        let order = ["N5", "N4", "N3", "N2", "N1"]
        let ordered = order.compactMap { lvl -> (String, [KanjiData])? in
            guard let items = grouped[lvl], !items.isEmpty else { return nil }
            return (lvl, items)
        }
        let remaining = grouped
            .filter { !order.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
        return ordered + remaining
    }
    
    // Grid Layout
    let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 16)
    ]
    
    init(
        isOnboardingActive: Bool = false,
        onboardingCoachText: String = "",
        onOnboardingKanjiTap: (() -> Void)? = nil,
        onOnboardingKanjiModalDismiss: (() -> Void)? = nil
    ) {
        self.isOnboardingActive = isOnboardingActive
        self.onboardingCoachText = onboardingCoachText
        self.onOnboardingKanjiTap = onOnboardingKanjiTap
        self.onOnboardingKanjiModalDismiss = onOnboardingKanjiModalDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    if searchText.isEmpty {
                        LazyVStack(spacing: 16) {
                        ForEach(groupedByLevel, id: \.level) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(section.level)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Button {
                                            if collapsedLevels.contains(section.level) {
                                                collapsedLevels.remove(section.level)
                                            } else {
                                                collapsedLevels.insert(section.level)
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .foregroundStyle(Color.appAccent)
                                                .rotationEffect(collapsedLevels.contains(section.level) ? .degrees(-90) : .degrees(0))
                                                .animation(.easeInOut(duration: 0.15), value: collapsedLevels.contains(section.level))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    if !collapsedLevels.contains(section.level) {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(section.items) { kanji in
                                                KanjiTileButton(kanji: kanji) {
                                                    selectedKanji = kanji
                                                    if isOnboardingActive, showOnboardingCoachMark {
                                                        showOnboardingCoachMark = false
                                                        onOnboardingKanjiTap?()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredKanji) { kanji in
                                KanjiTileButton(kanji: kanji) {
                                    selectedKanji = kanji
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Dictionary")
                .background(Color.appBackgroundGrouped)
                .searchable(text: $searchText, prompt: "Search Meaning or Reading")
                .sheet(item: $selectedKanji, onDismiss: {
                    if isOnboardingActive {
                        onOnboardingKanjiModalDismiss?()
                    }
                }) { kanji in
                    KanjiModalView(data: kanji)
                }
                .overlay {
                    if filteredKanji.isEmpty {
                        ContentUnavailableView.search
                    }
                }

                if isOnboardingActive, showOnboardingCoachMark {
                    OnboardingPopupOverlay(message: onboardingCoachText)
                }
            }
        }
    }
}

private struct KanjiTileButton: View {
    let kanji: KanjiData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(kanji.character)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.primary)

                Text(kanji.meaning.components(separatedBy: ",").first ?? kanji.meaning)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DictionaryView()
}
