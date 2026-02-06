import SwiftUI

struct PostKanjiMessageOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppStyle.Colors.onAccentText)
                .padding(.horizontal, AppStyle.Spacing.xxl)
                .padding(.vertical, AppStyle.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: AppStyle.Radii.md)
                        .fill(AppStyle.Colors.accent)
                }
                .padding(AppStyle.Spacing.xxxl)
        }
        .transition(.opacity)
    }
}

#Preview {
    PostKanjiMessageOverlay(message: "Great! One more thing to get you started..")
}
