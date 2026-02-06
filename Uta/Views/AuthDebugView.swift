import SwiftUI

struct AuthDebugView: View {
    @AppStorage("backend_access_token") private var accessToken: String = ""
    @AppStorage("backend_base_url_override") private var baseURLOverride: String = ""
    @State private var isPinging = false
    @State private var lastError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    LabeledContent("Base URL") {
                        Text(BackendClient.shared.baseURL.absoluteString)
                            .font(.footnote)
                            .multilineTextAlignment(.trailing)
                    }

                    TextField("Override base URL (Debug only)", text: $baseURLOverride)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)

                    Button("Clear override") {
                        baseURLOverride = ""
                    }
                    .disabled(baseURLOverride.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Auth") {
                    LabeledContent("Authenticated") {
                        Text(BackendClient.shared.hasSession() ? "yes" : "no")
                    }
                    LabeledContent("Token present") {
                        Text(accessToken.isEmpty ? "no" : "yes")
                    }
                    LabeledContent("Last API response") {
                        let code = BackendClient.shared.getLastStatusCode()
                        Text(code == 0 ? "(none)" : String(code))
                    }
                }

                Section {
                    Button(isPinging ? "Pinging…" : "Ping /v1/auth/me") {
                        Task { await ping() }
                    }
                    .disabled(isPinging)
                }

                if let lastError {
                    Section("Last error") {
                        Text(lastError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Auth Debug")
        }
    }

    private func ping() async {
        isPinging = true
        defer { isPinging = false }

        do {
            _ = try await BackendClient.shared.authMe()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

#Preview {
    AuthDebugView()
}
