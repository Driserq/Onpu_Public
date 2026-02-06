import SwiftUI

struct OnboardingInterludeView: View {
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("And here's how you use the app.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBackgroundTertiary)
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.appAccent)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.linear(duration: 2.0), value: progress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .onAppear {
            progress = 1
            Task {
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    return
                }
                onFinished()
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    OnboardingInterludeView(onFinished: {})
}
