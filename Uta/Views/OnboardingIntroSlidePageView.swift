import SwiftUI

struct OnboardingIntroSlidePageView: View {
    let slide: OnboardingIntroSlide

    var body: some View {
        VStack(spacing: AppStyle.Spacing.xxl) {
            Spacer()

            Image(systemName: slide.systemImage)
                .font(.system(size: 56))
                .foregroundStyle(AppStyle.Colors.accent)
                .padding(.bottom, AppStyle.Spacing.xs)

            Text(slide.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(slide.message)
                .font(.body)
                .foregroundStyle(AppStyle.Colors.authSubtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppStyle.Spacing.xxxl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppStyle.Colors.background)
    }
}

#Preview {
    OnboardingIntroSlidePageView(slide: OnboardingIntroSlide.defaults[0])
}
