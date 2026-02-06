import SwiftUI
import SwiftData

struct AddSongView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let prefilledTitle: String?
    let prefilledArtist: String?
    let prefilledLyrics: String?
    let onboardingMessage: String?
    let onOnboardingSave: (() -> Void)?
    
    @State private var title = ""
    @State private var artist = ""
    @State private var lyrics = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    init(
        prefilledTitle: String? = nil,
        prefilledArtist: String? = nil,
        prefilledLyrics: String? = nil,
        onboardingMessage: String? = nil,
        onOnboardingSave: (() -> Void)? = nil
    ) {
        self.prefilledTitle = prefilledTitle
        self.prefilledArtist = prefilledArtist
        self.prefilledLyrics = prefilledLyrics
        self.onboardingMessage = onboardingMessage
        self.onOnboardingSave = onOnboardingSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Song Details")) {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                }
                
                Section(header: Text("Lyrics")) {
                    TextEditor(text: $lyrics)
                        .frame(minHeight: 200)
                        .font(.body)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        processAndSave()
                    }
                    .disabled(title.isEmpty || lyrics.isEmpty || isProcessing)
                    .bold()
                }
            }
            .overlay {
                ZStack {
                    if isProcessing {
                        ZStack {
                            Color.black.opacity(0.4).ignoresSafeArea()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .controlSize(.large)
                                    .tint(.white)
                                Text("Submitting...")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding(32)
                            .background(Color.appBackgroundTertiary.opacity(0.9))
                            .clipShape(.rect(cornerRadius: 16))
                        }
                    }

                    if let onboardingMessage {
                        OnboardingPopupOverlay(message: onboardingMessage)
                    }
                }
            }
            .alert("Lyrics processing failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .onAppear {
            if let prefilledTitle {
                title = prefilledTitle
            }
            if let prefilledArtist {
                artist = prefilledArtist
            }
            if let prefilledLyrics {
                lyrics = prefilledLyrics
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func processAndSave() {
        hideKeyboard()

        // Start Processing
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
                let trimmedLyrics = lyrics.trimmingCharacters(in: .whitespacesAndNewlines)

                #if DEBUG
                // In DEBUG, allow dev-bypass auth (set BackendClient.backend_dev_token) so you can test without Sign in with Apple.
                #endif

                let created = try await BackendClient.shared.createJob(
                    title: trimmedTitle,
                    artist: trimmedArtist,
                    lyrics: trimmedLyrics
                )

                let job = LyricsJob(
                    title: trimmedTitle,
                    artist: trimmedArtist,
                    lyricsRaw: trimmedLyrics,
                    jobId: created.jobId,
                    status: created.status
                )

                await MainActor.run {
                    modelContext.insert(job)
                    isProcessing = false
                    dismiss()
                    onOnboardingSave?()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false

                    errorMessage = "Failed to submit lyrics: \(error.localizedDescription)"

                    if errorMessage != nil {
                        showErrorAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    AddSongView()
}
