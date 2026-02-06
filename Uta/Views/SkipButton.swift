//
//  SkipButton.swift
//  Uta
//
//  Created for Interactive Onboarding Module
//  Provides skip functionality with confirmation alert
//

import SwiftUI

/// A button that allows users to skip the onboarding tutorial
/// Positioned in the top-trailing corner with confirmation alert
struct SkipButton: View {
    /// Binding to control the confirmation alert presentation
    @Binding var showConfirmation: Bool
    
    /// Closure to call when user confirms skip action
    let onSkip: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip") {
                    showConfirmation = true
                }
                .buttonStyle(BrandedSecondaryButtonStyle())
                .padding()
            }
            Spacer()
        }
        .alert("Skip Tutorial?", isPresented: $showConfirmation) {
            Button("Keep Learning", role: .cancel) { }
            Button("Skip Tutorial", role: .destructive) {
                onSkip()
            }
        }
    }
}

#Preview {
    SkipButton(showConfirmation: .constant(false), onSkip: {})
}
