//
//  TargetFrameKey.swift
//  Uta
//
//  PreferenceKey for capturing UI element frame coordinates during onboarding.
//  Used to dynamically position the spotlight overlay cutout around target elements.
//

import SwiftUI

/// PreferenceKey for capturing and propagating target element frame coordinates
/// during the interactive onboarding flow.
///
/// This key is used to report frame positions from target UI elements (Japanese text lines,
/// Kanji tokens) up to the OnboardingCoordinator, which then positions the SpotlightOverlay
/// cutout accordingly.
///
/// The reduce function takes the latest value, ensuring that when multiple elements
/// report frames, the most recent one is used for spotlight positioning.
struct TargetFrameKey: PreferenceKey {
    /// Default value when no frame has been reported yet
    static var defaultValue: CGRect = .zero
    
    /// Reduces multiple frame values by taking the latest (most recent) value.
    ///
    /// This ensures that when target elements change between onboarding steps,
    /// the spotlight smoothly transitions to the new target's position.
    ///
    /// - Parameters:
    ///   - value: The current accumulated frame value
    ///   - nextValue: A closure that returns the next frame value to consider
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
