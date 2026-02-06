import SwiftUI

struct OnboardingView: View {
    @AppStorage("backend_access_token") private var accessToken: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.xxl) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: AppStyle.Spacing.sm) {
                Text("Onpu")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(AppStyle.Colors.authTitle)
                Text("Learn Japanese through songs")
                    .font(.subheadline)
                    .foregroundStyle(AppStyle.Colors.authSubtitle)
            }

            Button("Continue with Apple", systemImage: "apple.logo") {
                accessToken = "dev"
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            .foregroundStyle(.white)
            .frame(height: 52)
            .clipShape(.rect(cornerRadius: AppStyle.Radii.md))

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top)
        .background(AppStyle.Colors.background)
    }
}

#Preview {
    OnboardingView()
}
