import SwiftUI

struct OnboardingPopupOverlay: View {
    let message: String
    @State private var displayedMessage = ""
    @State private var textOpacity: Double = 0
    @State private var transitionTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            banner
                .frame(width: geometry.size.width)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height
                        - geometry.safeAreaInsets.bottom
                        - 28
                        - 12
                )
        }
        .allowsHitTesting(false)
        .onAppear {
            displayedMessage = message
            textOpacity = 0
            withAnimation(.easeInOut(duration: 0.25)) {
                textOpacity = message.isEmpty ? 0 : 1
            }
        }
        .onDisappear {
            transitionTask?.cancel()
            transitionTask = nil
        }
        .onChange(of: message) { _, newValue in
            transitionTask?.cancel()
            transitionTask = Task {
                await transitionText(to: newValue)
            }
        }
    }

    private var banner: some View {
        ZStack {
            Rectangle()
                .fill(AppStyle.Colors.accent)

            Text(displayedMessage)
                .font(.headline)
                .foregroundStyle(AppStyle.Colors.onAccentText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppStyle.Spacing.lg)
                .opacity(textOpacity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }

    @MainActor
    private func transitionText(to newValue: String) async {
        withAnimation(.easeInOut(duration: 0.25)) {
            textOpacity = 0
        }
        do {
            try await Task.sleep(for: .seconds(0.25))
        } catch {
            return
        }
        guard !Task.isCancelled else { return }
        displayedMessage = newValue
        withAnimation(.easeInOut(duration: 0.25)) {
            textOpacity = newValue.isEmpty ? 0 : 1
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground
        OnboardingPopupOverlay(message: "Tap the Japanese line to reveal translation")
    }
}
