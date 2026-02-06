import SwiftUI

enum AppStyle {
    enum Colors {
        static let accent = Color.appAccent
        static let accentLight = Color.appAccentLight
        static let background = Color.appBackground
        static let backgroundSecondary = Color.appBackgroundSecondary
        static let backgroundTertiary = Color.appBackgroundTertiary
        static let highlight = Color.appHighlight
        static let translationBackground = Color.appTranslationBackground
        static let warningBackground = Color.appWarningBackground
        static let pitchAccent = Color.appPitchAccent
        static let shadow = Color.appShadow
        static let shadowStrong = Color.appShadowStrong
        static let onAccentText = Color.white
        static let authTitle = Color.primary
        static let authSubtitle = Color.secondary
        static let onboardingDotActive = Color.appAccent
        static let onboardingDotInactive = Color.secondary.opacity(0.4)
    }

    enum Radii {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
}
