import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: MainTabView.Tab
    @Binding var selectedSong: Song?

    @Query(sort: \Song.createdAt, order: .reverse) private var recentSongs: [Song]
    @State private var showingAddSong = false
    #if DEBUG
    @State private var showingAuthDebug = false
    #endif
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.xxl) {
                    // Welcome Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: AppStyle.Spacing.sm) {
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Ready to learn some Japanese?")
                                .font(.subheadline)
                                .foregroundStyle(AppStyle.Colors.authSubtitle)
                        }
                        Spacer()
                        #if DEBUG
                        Button {
                            showingAuthDebug = true
                        } label: {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.title3)
                                .foregroundStyle(AppStyle.Colors.authSubtitle)
                                .padding(AppStyle.Spacing.sm)
                                .background(AppStyle.Colors.backgroundSecondary)
                                .clipShape(.circle)
                        }
                        .accessibilityLabel("Auth Debug")
                        #endif
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Action
                    Button(action: { showingAddSong = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add New Song")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.Colors.accent)
                        .foregroundStyle(AppStyle.Colors.onAccentText)
                        .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
                    }
                    .padding(.horizontal)
                    
                    // Recent Songs Section
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.lg) {
                        Text("Recent Songs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if recentSongs.isEmpty {
                            ContentUnavailableView(
                                "No songs yet",
                                systemImage: "music.note",
                                description: Text("Add your first song to get started")
                            )
                            .frame(height: 200)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppStyle.Spacing.lg) {
                                    ForEach(recentSongs.prefix(5)) { song in
                                        Button {
                                            selectedSong = song
                                            selectedTab = .library
                                        } label: {
                                            RecentSongCard(song: song)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSong) {
                AddSongView()
            }
            #if DEBUG
            .sheet(isPresented: $showingAuthDebug) {
                AuthDebugView()
            }
            #endif
        }
    }
}

struct RecentSongCard: View {
    let song: Song
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.md) {
            Circle()
                .fill(AppStyle.Colors.accentLight)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(AppStyle.Colors.accent)
                )
            
            VStack(alignment: .leading, spacing: AppStyle.Spacing.xs) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140, height: 160)
        .padding()
        .background(AppStyle.Colors.background)
        .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
        .shadow(color: AppStyle.Colors.shadow, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home), selectedSong: .constant(nil))
        .modelContainer(for: Song.self, inMemory: true)
}
