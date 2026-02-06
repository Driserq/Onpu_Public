import SwiftUI

struct BrandedPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppStyle.Colors.onAccentText)
            .padding(.horizontal, AppStyle.Spacing.xl)
            .padding(.vertical, AppStyle.Spacing.md)
            .frame(minHeight: 44)
            .background(AppStyle.Colors.accent)
            .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct BrandedSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppStyle.Colors.accent)
            .padding(.horizontal, AppStyle.Spacing.xl)
            .padding(.vertical, AppStyle.Spacing.md)
            .frame(minHeight: 44)
            .background(AppStyle.Colors.background)
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.Radii.md)
                    .stroke(AppStyle.Colors.accent, lineWidth: 1.5)
            }
            .clipShape(.rect(cornerRadius: AppStyle.Radii.md))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}
