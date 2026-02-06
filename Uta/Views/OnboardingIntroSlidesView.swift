import SwiftUI
import UIKit

struct OnboardingIntroSlidesView: View {
    let slides: [OnboardingIntroSlide]
    @Binding var currentIndex: Int
    let onNext: () -> Void

    init(slides: [OnboardingIntroSlide], currentIndex: Binding<Int>, onNext: @escaping () -> Void) {
        self.slides = slides
        self._currentIndex = currentIndex
        self.onNext = onNext
        let pageControl = UIPageControl.appearance()
        pageControl.currentPageIndicatorTintColor = UIColor(AppStyle.Colors.onboardingDotActive)
        pageControl.pageIndicatorTintColor = UIColor(AppStyle.Colors.onboardingDotInactive)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(slides.enumerated(), id: \.element.id) { index, slide in
                    OnboardingIntroSlidePageView(slide: slide)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .animation(.easeInOut(duration: 0.35), value: currentIndex)

            HStack {
                Spacer()
                Button("Next") {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        onNext()
                    }
                }
                .buttonStyle(BrandedPrimaryButtonStyle())
            }
            .padding(AppStyle.Spacing.lg)
            .background(AppStyle.Colors.background)
        }
        .background(AppStyle.Colors.background)
    }
}

#Preview {
    OnboardingIntroSlidesView(
        slides: OnboardingIntroSlide.defaults,
        currentIndex: .constant(0),
        onNext: {}
    )
}
