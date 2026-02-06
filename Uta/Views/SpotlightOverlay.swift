import OSLog
import SwiftUI

/// Container view that combines all spotlight overlay components into a cohesive tutorial overlay.
/// Layers the dimmed background, pulse ring, and instruction text to create the spotlight effect.
///
/// Hit Testing Behavior:
/// - Dimmed areas block user interaction (allowsHitTesting true on filled regions)
/// - Cutout area allows pass-through gestures to underlying UI (even-odd fill creates "hole")
/// - Uses contentShape with eoFill to make hit testing respect the visual cutout
///
/// Requirements: 4.1, 4.2, 4.4, 4.5, 9.1, 9.2, 10.3
struct SpotlightOverlay: View {
    /// The frame of the UI element to highlight
    let targetFrame: CGRect
    
    /// The current onboarding step
    let step: OnboardingStep
    
    /// Corner radius for the cutout and pulse ring
    private let cornerRadius: CGFloat = 12

    private let logger = Logger(subsystem: "Uta", category: "Onboarding")
    
    /// Creates a spotlight overlay
    /// - Parameters:
    ///   - targetFrame: The frame of the UI element to highlight
    ///   - step: The current onboarding step
    init(targetFrame: CGRect, step: OnboardingStep) {
        self.targetFrame = targetFrame
        self.step = step
    }
    
    var body: some View {
        GeometryReader { geometry in
            let resolvedFrame = resolvedTargetFrame(in: geometry.size)
            ZStack {
                // Dimmed background with cutout hole
                // Uses even-odd fill for visual appearance and contentShape for hit testing
                DimmedBackgroundShape(cutout: resolvedFrame, cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                    .contentShape(DimmedBackgroundShape(cutout: resolvedFrame, cornerRadius: cornerRadius), eoFill: true)
                    .allowsHitTesting(true) // Blocks interaction on dimmed areas, allows pass-through in cutout
                    .ignoresSafeArea()
                
                // Pulse ring animation around the cutout
                PulseRing(frame: resolvedFrame, cornerRadius: cornerRadius)
                
                // Instruction text positioned above or below cutout
                InstructionText(step: step, cutoutFrame: resolvedFrame)
            }
            .animation(.easeInOut(duration: 0.3), value: resolvedFrame)
        }
    }

    private func resolvedTargetFrame(in size: CGSize) -> CGRect {
        guard isValid(frame: targetFrame), size.width > 0, size.height > 0 else {
            logger.warning("Invalid spotlight frame: \(String(describing: targetFrame))")
            let maxWidth = max(1, size.width - 40)
            let maxHeight = max(1, size.height - 40)
            let width = min(max(160, size.width * 0.6), maxWidth)
            let height = min(max(64, size.height * 0.12), maxHeight)
            let x = (size.width - width) / 2
            let y = (size.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }

        return targetFrame
    }

    private func isValid(frame: CGRect) -> Bool {
        frame.width > 1
            && frame.height > 1
            && frame.origin.x.isFinite
            && frame.origin.y.isFinite
            && frame.size.width.isFinite
            && frame.size.height.isFinite
    }
}

#Preview("Step 1 - Tap to Reveal") {
    let targetFrame = CGRect(x: 50, y: 400, width: 300, height: 100)
    
    SpotlightOverlay(
        targetFrame: targetFrame,
        step: .tapToReveal
    )
}

#Preview("Step 2 - Long Press Kanji") {
    let targetFrame = CGRect(x: 150, y: 300, width: 100, height: 50)
    
    SpotlightOverlay(
        targetFrame: targetFrame,
        step: .longPressKanji
    )
}

#Preview("Completed - No Overlay") {
    let targetFrame = CGRect(x: 50, y: 400, width: 300, height: 100)
    
    SpotlightOverlay(
        targetFrame: targetFrame,
        step: .completed
    )
}

#Preview("Animating Frame Change") {
    struct AnimatedPreview: View {
        @State private var useFirstFrame = true
        
        let frame1 = CGRect(x: 50, y: 200, width: 300, height: 100)
        let frame2 = CGRect(x: 150, y: 500, width: 100, height: 50)
        
        var body: some View {
            ZStack {
                // Sample content
                VStack(spacing: 40) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 300, height: 100)
                        .position(x: 200, y: 250)
                    
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 100, height: 50)
                        .position(x: 200, y: 525)
                }
                
                SpotlightOverlay(
                    targetFrame: useFirstFrame ? frame1 : frame2,
                    step: useFirstFrame ? .tapToReveal : .longPressKanji
                )
                
                // Toggle button
                VStack {
                    Spacer()
                    Button("Toggle Frame") {
                        useFirstFrame.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
    }
    
    return AnimatedPreview()
}

#Preview("With Real Content Background") {
    let targetFrame = CGRect(x: 50, y: 300, width: 300, height: 80)
    
    ZStack {
        // Simulated lyrics content
        VStack(spacing: 20) {
            Text("古池や蛙飛びこむ水の音")
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.2))
                .clipShape(.rect(cornerRadius: 8))
            
            Text("An old pond / A frog jumps in / The sound of water")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
        
        SpotlightOverlay(
            targetFrame: targetFrame,
            step: .tapToReveal
        )
    }
}
