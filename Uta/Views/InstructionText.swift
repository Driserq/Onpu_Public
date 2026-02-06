import SwiftUI

/// Displays instructional text for the current onboarding step.
/// Automatically positions above or below the spotlight cutout based on available space.
///
/// Requirements: 5.5, 6.2
struct InstructionText: View {
    /// The current onboarding step
    let step: OnboardingStep
    
    /// The frame of the spotlight cutout
    let cutoutFrame: CGRect
    
    /// Padding from the cutout edge
    private let cutoutPadding: CGFloat = 24
    
    /// Minimum space required above/below cutout to position text there
    private let minimumSpace: CGFloat = 100
    
    /// Creates an instruction text view
    /// - Parameters:
    ///   - step: The current onboarding step
    ///   - cutoutFrame: The frame of the spotlight cutout
    init(
        step: OnboardingStep,
        cutoutFrame: CGRect
    ) {
        self.step = step
        self.cutoutFrame = cutoutFrame
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !step.instructionText.isEmpty {
                Text(step.instructionText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                    .position(instructionPosition(in: geometry.size))
            }
        }
    }
    
    /// Calculates the optimal position for the instruction text
    /// Places text above cutout if there's enough space, otherwise below
    private func instructionPosition(in size: CGSize) -> CGPoint {
        let spaceAbove = cutoutFrame.minY
        let spaceBelow = size.height - cutoutFrame.maxY
        
        // Prefer positioning above the cutout
        if spaceAbove >= minimumSpace {
            return CGPoint(
                x: size.width / 2,
                y: cutoutFrame.minY - cutoutPadding - 50 // Approximate text height
            )
        } else if spaceBelow >= minimumSpace {
            // Position below if not enough space above
            return CGPoint(
                x: size.width / 2,
                y: cutoutFrame.maxY + cutoutPadding + 50
            )
        } else {
            // Fallback: center horizontally, position in larger space
            let y = spaceAbove > spaceBelow
                ? cutoutFrame.minY - cutoutPadding - 50
                : cutoutFrame.maxY + cutoutPadding + 50
            return CGPoint(x: size.width / 2, y: y)
        }
    }
}

#Preview("Above Cutout") {
    let cutoutFrame = CGRect(x: 50, y: 400, width: 300, height: 100)
    
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        DimmedBackgroundShape(cutout: cutoutFrame)
            .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        
        PulseRing(frame: cutoutFrame)
        
        InstructionText(
            step: .tapToReveal,
            cutoutFrame: cutoutFrame
        )
    }
}

#Preview("Below Cutout") {
    let cutoutFrame = CGRect(x: 50, y: 100, width: 300, height: 100)
    
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        DimmedBackgroundShape(cutout: cutoutFrame)
            .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        
        PulseRing(frame: cutoutFrame)
        
        InstructionText(
            step: .tapToReveal,
            cutoutFrame: cutoutFrame
        )
    }
}

#Preview("Long Press Step") {
    let cutoutFrame = CGRect(x: 150, y: 400, width: 100, height: 50)
    
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        DimmedBackgroundShape(cutout: cutoutFrame)
            .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        
        PulseRing(frame: cutoutFrame)
        
        InstructionText(
            step: .longPressKanji,
            cutoutFrame: cutoutFrame
        )
    }
}

#Preview("Completed Step - No Text") {
    let cutoutFrame = CGRect(x: 50, y: 400, width: 300, height: 100)
    
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        InstructionText(
            step: .completed,
            cutoutFrame: cutoutFrame
        )
    }
}
