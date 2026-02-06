import SwiftUI

/// Centralized color definitions for the app
/// All colors should be referenced from here to maintain consistency
extension Color {
    
    // MARK: - Brand Colors
    
    /// Primary brand color (pink accent)
    static let appAccent = Color.pink
    
    /// Accent color with light opacity for backgrounds
    static let appAccentLight = Color.pink.opacity(0.1)
    
    // MARK: - Background Colors
    
    /// Primary background for main content areas
    static let appBackground = Color(.systemBackground)
    
    /// Secondary background for grouped content
    static let appBackgroundGrouped = Color(.systemGroupedBackground)
    
    /// Tertiary background for nested elements
    static let appBackgroundSecondary = Color(.secondarySystemBackground)
    
    /// Light gray background for subtle containers
    static let appBackgroundTertiary = Color(.systemGray6)
    
    // MARK: - Selection & Highlight Colors
    
    /// Selected line highlight (red tint)
    static let appHighlight = Color.red.opacity(0.18)
    
    /// Translation background (blue tint)
    static let appTranslationBackground = Color.blue.opacity(0.1)
    
    /// Warning/alert background (yellow tint)
    static let appWarningBackground = Color.yellow.opacity(0.2)
    
    // MARK: - Pitch Accent Colors
    
    /// Pitch accent line color (red)
    static let appPitchAccent = Color.red
    
    // MARK: - UI Element Colors
    
    /// Shadow color for elevated elements
    static let appShadow = Color.black.opacity(0.05)
    
    /// Stronger shadow for prominent elements
    static let appShadowStrong = Color.black.opacity(0.1)
}
