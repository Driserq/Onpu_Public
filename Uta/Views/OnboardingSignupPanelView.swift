import SwiftUI
import AuthenticationServices

struct OnboardingSignupPanelView: View {
    let onContinue: () -> Void
    @State private var rawNonce: String = ""
    @State private var isSigningIn: Bool = false
    @State private var errorMessage: String?

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if !newValue { errorMessage = nil }
            }
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("You’re all set")
                    .font(.title2)
                    .bold()

                Text("Continue with Apple to personalize your experience.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            HStack(spacing: AppStyle.Spacing.sm) {
                Image(systemName: "apple.logo")
                Text("Continue with Apple")
            }
            .font(.headline)
            .foregroundStyle(AppStyle.Colors.onAccentText)
            .padding(.horizontal, AppStyle.Spacing.xl)
            .padding(.vertical, AppStyle.Spacing.md)
            .frame(minHeight: 44)
            .background(AppStyle.Colors.accent)
            .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
            .overlay {
                SignInWithAppleButton(.continue) { request in
                    let nonce = AuthService.generateRandomNonce()
                    rawNonce = nonce
                    request.requestedScopes = [.email]
                    request.nonce = AuthService.sha256Hex(nonce)
                } onCompletion: { result in
                    handleSignInResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .opacity(0.02)
            }
            .opacity(isSigningIn ? 0.85 : 1.0)
            .disabled(isSigningIn)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .alert("Sign in failed", isPresented: isShowingError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unexpected Apple credential type."
                return
            }

            guard !rawNonce.isEmpty else {
                errorMessage = "Missing nonce. Please try again."
                return
            }

            isSigningIn = true
            Task { @MainActor in
                defer { isSigningIn = false }
                do {
                    try await AuthService.shared.authenticateAppleCredential(credential, rawNonce: rawNonce)
                    onContinue()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingSignupPanelView(onContinue: {})
}
