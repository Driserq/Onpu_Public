import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Binding var selectedSong: Song?

    let isOnboardingActive: Bool
    let onboardingTargetJobTitle: String?
    @Binding var showCoachMark: Bool
    let onOnboardingSongTap: (() -> Void)?
    let onOnboardingAddTap: (() -> Void)?

    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @Query(sort: \LyricsJob.createdAt, order: .reverse) private var jobs: [LyricsJob]
    @State private var searchText = ""
    @State private var showingAddSong = false

    @State private var longpollTask: Task<Void, Never>?
    @State private var resumeTask: Task<Void, Never>?
    @State private var lastSeenUpdatedAtMs: Int = 0
    @AppStorage("backend_last_recent_check_ms") private var lastRecentCheckMs: Double = 0

    @State private var pendingDeleteSong: Song?
    @State private var pendingRemoveJob: LyricsJob?
    @State private var pendingRetryJob: LyricsJob?


    private var jobSignature: String {
        jobs.map(\.jobId).sorted().joined(separator: ",")
    }
    
    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText) ||
                song.lyricsRaw.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !jobs.isEmpty {
                    Section("Processing") {
                        ForEach(jobs) { job in
                            ProcessingJobRowView(
                                title: job.title,
                                artist: job.artist,
                                statusText: displayStatus(for: job),
                                statusRaw: job.statusRaw,
                                errorMessage: job.errorMessage,
                                isActive: job.statusRaw == "queued" || job.statusRaw == "running"
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if job.statusRaw == "failed" || job.statusRaw == "missing" {
                                    Button {
                                        pendingRetryJob = job
                                    } label: {
                                        Label("Retry", systemImage: "arrow.clockwise")
                                    }
                                    .tint(.blue)
                                }

                                Button(role: .destructive) {
                                    pendingRemoveJob = job
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                ForEach(filteredSongs) { song in
                    Button {
                        selectedSong = song
                        if isOnboardingActive, showCoachMark {
                            showCoachMark = false
                            onOnboardingSongTap?()
                        }
                    } label: {
                        SongRow(song: song)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            song.isFavorite.toggle()
                        } label: {
                            Label(song.isFavorite ? "Unfavorite" : "Favorite", systemImage: song.isFavorite ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            pendingDeleteSong = song
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Library")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search songs...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: handleAddSongTap) {
                        Image(systemName: "plus")
                    }
                    .disabled(isOnboardingActive && onOnboardingAddTap == nil)
                }
            }
            .sheet(isPresented: $showingAddSong) {
                AddSongView()
            }
            .navigationDestination(item: $selectedSong) { song in
                LyricsView(song: song)
            }
            .task(id: jobSignature) {
                await refreshAndStartLongpollIfNeeded()
            }
            .onChange(of: scenePhase) { _, newValue in
                if newValue == .active {
                    resumeTask?.cancel()
                    resumeTask = Task { await resumeCatchup() }
                }
            }
            .onDisappear {
                longpollTask?.cancel()
                longpollTask = nil
                resumeTask?.cancel()
                resumeTask = nil
            }
            .onChange(of: jobs) { _, newValue in
                updateOnboardingCoachVisibility(jobs: newValue)
            }
            .onChange(of: songs) { _, newValue in
                updateOnboardingCoachVisibility(songs: newValue)
            }
            .onAppear {
                updateOnboardingCoachVisibility(jobs: jobs)
                updateOnboardingCoachVisibility(songs: songs)
            }
            .overlay {
                ZStack {
                    if songs.isEmpty {
                        ContentUnavailableView(
                            "No Songs",
                            systemImage: "music.note.list",
                            description: Text("Songs you add will appear here")
                        )
                    } else if filteredSongs.isEmpty {
                        ContentUnavailableView.search
                    }

                    if pendingDeleteSong != nil || pendingRemoveJob != nil || pendingRetryJob != nil {
                        confirmationOverlay
                    }
                }
            }
        }
    }

    private var confirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    pendingDeleteSong = nil
                    pendingRemoveJob = nil
                    pendingRetryJob = nil
                }

            VStack(spacing: 12) {
                Text(pendingDeleteSong != nil ? "Delete Song?" : (pendingRetryJob != nil ? "Retry Job?" : "Remove Job?"))
                    .font(.headline)

                Text(pendingDeleteSong != nil
                     ? "This will permanently delete this song from your library."
                     : (pendingRetryJob != nil
                        ? "This will resubmit the lyrics to the backend and replace the job."
                        : "This will remove this queued/failed job from the list."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        pendingDeleteSong = nil
                        pendingRemoveJob = nil
                        pendingRetryJob = nil
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        if let song = pendingDeleteSong {
                            deleteSong(song)
                        }
                        if let job = pendingRemoveJob {
                            deleteJob(job)
                        }
                        if let job = pendingRetryJob {
                            Task { await retryJob(job) }
                        }
                        pendingDeleteSong = nil
                        pendingRemoveJob = nil
                        pendingRetryJob = nil
                    } label: {
                        Text("Confirm")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(16)
            .frame(maxWidth: 320)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 20)
            .padding(24)
        }
        .transition(.opacity)
    }

    private func handleAddSongTap() {
        if isOnboardingActive, let onOnboardingAddTap {
            onOnboardingAddTap()
        } else {
            showingAddSong = true
        }
    }

    @MainActor
    private func retryJob(_ job: LyricsJob) async {
        do {
            let created = try await BackendClient.shared.createJob(title: job.title, artist: job.artist, lyrics: job.lyricsRaw)
            job.jobId = created.jobId
            job.statusRaw = created.status
            job.errorMessage = nil
            job.updatedAt = Date()
        } catch {
            job.statusRaw = "failed"
            job.errorMessage = String(describing: error)
            job.updatedAt = Date()
        }
    }
    
    private func deleteSong(_ song: Song) {
        withAnimation {
            modelContext.delete(song)
        }
    }

    private func deleteJob(_ job: LyricsJob) {
        withAnimation {
            modelContext.delete(job)
        }
    }

    @MainActor
    private func refreshAndStartLongpollIfNeeded() async {
        await refreshJobsOnce()
        startLongpollIfNeeded()
    }

    @MainActor
    private func refreshJobsOnce() async {
        for job in jobs {
            if job.statusRaw == "missing" { continue }

            // Only refresh non-terminal statuses.
            if job.statusRaw == "succeeded" || job.statusRaw == "failed" {
                continue
            }

            do {
                let status = try await BackendClient.shared.getJob(jobId: job.jobId)
                job.statusRaw = status.status
                job.stageRaw = status.stage
                job.errorMessage = status.error
                job.updatedAt = Date()
                if let updatedAt = status.updatedAt {
                    lastSeenUpdatedAtMs = max(lastSeenUpdatedAtMs, updatedAt)
                }

                if status.status == "succeeded", let result = status.result {
                    try finalize(job: job, result: result)
                }
            } catch {
                if case BackendClientError.httpError(404, _) = error {
                    job.statusRaw = "missing"
                    job.errorMessage = "Job not found on backend (Redis restart/expired)."
                    job.updatedAt = Date()
                }
            }
        }
    }

    @MainActor
    private func startLongpollIfNeeded() {
        longpollTask?.cancel()
        longpollTask = nil

        let hasPending = jobs.contains { $0.statusRaw == "queued" || $0.statusRaw == "running" }
        guard hasPending else { return }

        let startSince = lastSeenUpdatedAtMs
        longpollTask = Task {
            await longpollLoop(startSinceMs: startSince)
        }
    }

    private func longpollLoop(startSinceMs: Int) async {
        var sinceMs = startSinceMs
        while !Task.isCancelled {
            let hasPendingLocal = await MainActor.run {
                jobs.contains { $0.statusRaw == "queued" || $0.statusRaw == "running" }
            }
            if !hasPendingLocal { return }

            do {
                let resp = try await BackendClient.shared.longpollPendingJobs(timeoutSeconds: 20, sinceMs: sinceMs, limit: 50)
                if Task.isCancelled { return }

                if let maxUpdated = resp.changes.map(\.updatedAt).max() {
                    sinceMs = max(sinceMs, maxUpdated)
                    await MainActor.run {
                        lastSeenUpdatedAtMs = max(lastSeenUpdatedAtMs, maxUpdated)
                    }
                }

                // If server claims no pending jobs, reconcile local state by refreshing pending jobs once.
                if resp.hasPending == false {
                    await refreshJobsOnce()
                }

                if resp.changes.isEmpty {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }

                for change in resp.changes {
                    if Task.isCancelled { return }

                    await MainActor.run {
                        guard let job = jobs.first(where: { $0.jobId == change.jobId }) else { return }
                        job.statusRaw = change.status
                        job.stageRaw = change.stage
                        job.errorMessage = change.error
                        job.updatedAt = Date()
                    }

                    // Only fetch full job payload when needed (e.g. succeeded -> needs result).
                    if change.status == "succeeded" || change.status == "failed" {
                        await refreshJobIfPresent(jobId: change.jobId)
                    }
                }
            } catch {
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func refreshJobIfPresent(jobId: String) async {
        do {
            let status = try await BackendClient.shared.getJob(jobId: jobId)
            await MainActor.run {
                guard let job = jobs.first(where: { $0.jobId == jobId }) else { return }
                job.statusRaw = status.status
                job.stageRaw = status.stage
                job.errorMessage = status.error
                job.updatedAt = Date()
            }
            if status.status == "succeeded", let result = status.result {
                await MainActor.run {
                    guard let job = jobs.first(where: { $0.jobId == jobId }) else { return }
                    try? finalize(job: job, result: result)
                }
            }
        } catch {
            if case BackendClientError.httpError(404, _) = error {
                await MainActor.run {
                    guard let job = jobs.first(where: { $0.jobId == jobId }) else { return }
                    job.statusRaw = "missing"
                    job.errorMessage = "Job not found on backend (Redis restart/expired)."
                    job.updatedAt = Date()
                }
            }
        }
    }

    private func displayStatus(for job: LyricsJob) -> String {
        switch job.statusRaw {
        case "queued":
            return "Queued…"
        case "running":
            return displayStage(for: job) ?? "Processing…"
        case "succeeded":
            return "Done"
        case "failed":
            return "Failed"
        case "missing":
            return "Expired"
        default:
            return job.statusRaw
        }
    }

    private func displayStage(for job: LyricsJob) -> String? {
        guard let stage = job.stageRaw, !stage.isEmpty else { return nil }
        switch stage {
        case "translating":
            return "Translating…"
        case "lyrics_data":
            return "Drawing pitch lines…"
        case "finalizing":
            return "Finalizing…"
        default:
            return stage
        }
    }

    private func resumeCatchup() async {
        let sinceMs = Int(lastRecentCheckMs)
        let nowMs = Int(Date().timeIntervalSince1970 * 1000)
        do {
            let recent = try await BackendClient.shared.getRecentJobs(sinceMs: sinceMs, limit: 50)
            await MainActor.run {
                lastRecentCheckMs = Double(nowMs)
                if let maxUpdated = recent.changes.map(\.updatedAt).max() {
                    lastSeenUpdatedAtMs = max(lastSeenUpdatedAtMs, maxUpdated)
                }
            }
            for change in recent.changes {
                if Task.isCancelled { return }
                await refreshJobIfPresent(jobId: change.jobId)
            }
        } catch {
            // Ignore transient resume errors.
        }
    }

    @MainActor
    private func finalize(job: LyricsJob, result: LyricsJobResultPayload) throws {
        #if DEBUG
        print("[finalize] jobId=\(job.jobId)")
        #endif
        // Convert translations keys to Int
        var translations: [Int: String] = [:]
        for (k, v) in result.translations {
            if let i = Int(k) { translations[i] = v }
        }

        // Convert lyricsData dict to ordered array, handling both compact and verbose formats
        let orderedLines: [LyricsLine] = result.lyricsData
            .compactMap { (k, v) -> (Int, LyricsLine)? in
                guard let i = Int(k) else { return nil }
                
                // Handle both compact and verbose formats
                let line: LyricsLine
                switch v {
                case .compact(let compactStr):
                    // Parse compact format
                    do {
                        line = try parseCompactFormat(compactStr)
                        #if DEBUG
                        print("[finalize] parsed compact format for line \(i): \(compactStr)")
                        #endif
                    } catch {
                        print("[finalize] ERROR: Failed to parse compact format for line \(i): \(error.localizedDescription)")
                        print("[finalize] Compact string was: \(compactStr)")
                        // Skip this line on error
                        return nil
                    }
                case .verbose(let lyricsLine):
                    // Use verbose format directly
                    line = lyricsLine
                    #if DEBUG
                    print("[finalize] using verbose format for line \(i)")
                    #endif
                }
                
                return (i, line)
            }
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }

        let song = Song(
            title: job.title,
            artist: job.artist,
            lyricsRaw: job.lyricsRaw,
            translations: translations,
            lyricsData: orderedLines
        )
        modelContext.insert(song)

        Task {
            // Best-effort ACK with retries handled on next launch if needed.
            try? await BackendClient.shared.ackJob(jobId: job.jobId)
        }

        deleteJob(job)
    }
}

private extension LibraryView {
    func updateOnboardingCoachVisibility(jobs: [LyricsJob]) {
        guard isOnboardingActive, let onboardingTargetJobTitle else { return }
        let hasJob = jobs.contains { $0.title == onboardingTargetJobTitle }
        if hasJob {
            showCoachMark = false
        }
    }

    func updateOnboardingCoachVisibility(songs: [Song]) {
        guard isOnboardingActive, let onboardingTargetJobTitle else { return }
        if songs.contains(where: { $0.title == onboardingTargetJobTitle }) {
            showCoachMark = true
        }
    }
}

extension LibraryView {
    init(
        selectedSong: Binding<Song?>,
        isOnboardingActive: Bool = false,
        onboardingTargetJobTitle: String? = nil,
        showCoachMark: Binding<Bool> = .constant(false),
        onOnboardingSongTap: (() -> Void)? = nil,
        onOnboardingAddTap: (() -> Void)? = nil
    ) {
        self._selectedSong = selectedSong
        self.isOnboardingActive = isOnboardingActive
        self.onboardingTargetJobTitle = onboardingTargetJobTitle
        self._showCoachMark = showCoachMark
        self.onOnboardingSongTap = onOnboardingSongTap
        self.onOnboardingAddTap = onOnboardingAddTap
    }
}

struct SongRow: View {
    let song: Song
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.appAccentLight)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(Color.appAccent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if song.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibraryView(selectedSong: .constant(nil))
        .modelContainer(for: [Song.self, LyricsJob.self], inMemory: true)
}
