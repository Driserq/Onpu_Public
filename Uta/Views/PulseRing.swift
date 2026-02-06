import SwiftUI

/// An animated pulse ring that draws attention to the spotlight cutout area.
/// The ring scales and fades in a continuous loop to create a pulsing effect.
///
/// Requirements: 4.3, 10.2
struct PulseRing: View {
    /// The frame around which to draw the pulse ring
    let frame: CGRect
    
    /// Corner radius matching the cutout shape
    let cornerRadius: CGFloat
    
    /// Animation state for the pulse effect
    @State private var isAnimating = false
    
    /// Creates a pulse ring around the specified frame
    /// - Parameters:
    ///   - frame: The rectangular area to pulse around
    ///   - cornerRadius: Corner radius matching the cutout (default: 12)
    init(frame: CGRect, cornerRadius: CGFloat = 12) {
        self.frame = frame
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.appAccent, lineWidth: 3)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .scaleEffect(isAnimating ? 1.15 : 1.0)
            .opacity(isAnimating ? 0.0 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview("Centered Pulse") {
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        PulseRing(frame: CGRect(x: 100, y: 300, width: 200, height: 100))
    }
}

#Preview("Top Pulse") {
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        PulseRing(frame: CGRect(x: 50, y: 100, width: 300, height: 80))
    }
}

#Preview("Large Pulse") {
    ZStack {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        PulseRing(frame: CGRect(x: 50, y: 200, width: 300, height: 200))
    }
}

#Preview("With Dimmed Background") {
    let cutoutFrame = CGRect(x: 100, y: 300, width: 200, height: 100)
    
    ZStack {
        DimmedBackgroundShape(cutout: cutoutFrame)
            .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
            .ignoresSafeArea()
        
        PulseRing(frame: cutoutFrame)
    }
}
