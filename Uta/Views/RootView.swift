import SwiftUI

struct RootView: View {
    @AppStorage("backend_access_token") private var accessToken: String = ""
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false

    var body: some View {
        if !isOnboardingComplete {
            OnboardingCoordinator(isOnboardingComplete: $isOnboardingComplete)
        } else {
            MainTabView(initialTab: .home)
        }
    }
}

#Preview {
    RootView()
}
