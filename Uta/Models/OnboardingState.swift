//
//  OnboardingState.swift
//  Uta
//
//  Created for Interactive Onboarding Module
//  Manages state for the first-launch tutorial system
//

import Foundation
import SwiftUI

/// Represents the current step in the onboarding flow
enum OnboardingStep {
    case tapToReveal
    case tapArrow
    case longPressKanji
    case completed
    
    /// Instruction text to display for each step
    var instructionText: String {
        switch self {
        case .tapToReveal:
            return "Tap the Japanese line to reveal translation"
        case .tapArrow:
            return "Tap arrow to highlight the next line"
        case .longPressKanji:
            return "Long-press the Kanji to continue"
        case .completed:
            return ""
        }
    }
}

/// Observable state manager for the interactive onboarding tutorial
/// Tracks current step, completion status, and target UI element frames
@MainActor
@Observable
final class OnboardingState {
    /// Current step in the onboarding flow
    var currentStep: OnboardingStep = .tapToReveal
    
    /// Whether the user has completed the onboarding tutorial
    var isComplete: Bool = false
    
    /// Frame coordinates of the current target UI element for spotlight highlighting
    var targetFrame: CGRect = .zero
    
    /// Advances to the next step in the onboarding flow
    /// Transitions: tapToReveal → tapArrow → longPressKanji → completed
    func advanceStep() {
        switch currentStep {
        case .tapToReveal:
            currentStep = .tapArrow
        case .tapArrow:
            currentStep = .longPressKanji
        case .longPressKanji:
            currentStep = .completed
            isComplete = true
        case .completed:
            // Already completed, no further action
            break
        }
    }
    
}
