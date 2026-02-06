import SwiftUI
import SwiftData

struct MainTabView: View {
    enum Tab: Hashable {
        case home
        case library
        case dictionary
    }

    @State private var selectedTab: Tab
    @State private var selectedSong: Song?
    private let onTabSelection: ((Tab) -> Void)?
    private let isLibraryOnboardingActive: Bool
    private let onLibraryAddTap: (() -> Void)?

    init(
        initialTab: Tab = .home,
        onTabSelection: ((Tab) -> Void)? = nil,
        isLibraryOnboardingActive: Bool = false,
        onLibraryAddTap: (() -> Void)? = nil
    ) {
        self._selectedTab = State(initialValue: initialTab)
        self.onTabSelection = onTabSelection
        self.isLibraryOnboardingActive = isLibraryOnboardingActive
        self.onLibraryAddTap = onLibraryAddTap
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, selectedSong: $selectedSong)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            LibraryView(
                selectedSong: $selectedSong,
                isOnboardingActive: isLibraryOnboardingActive,
                onOnboardingAddTap: onLibraryAddTap
            )
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(Tab.library)
            
            DictionaryView()
                .tabItem {
                    Label("Dictionary", systemImage: "character.book.closed.fill")
                }
                .tag(Tab.dictionary)
        }
        .onChange(of: selectedTab) { _, newValue in
            onTabSelection?(newValue)
        }
        .accentColor(Color.appAccent)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Song.self, inMemory: true)
}
