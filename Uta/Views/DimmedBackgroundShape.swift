import SwiftUI

/// A custom Shape that creates a dimmed full-screen overlay with a cutout hole.
/// Uses the even-odd fill rule to create a "spotlight" effect where the cutout area is transparent.
///
/// Hit Testing:
/// When used with .contentShape(eoFill: true), this shape enables proper hit testing behavior:
/// - Filled (dimmed) regions block interaction
/// - Cutout (transparent) region allows pass-through to underlying UI
///
/// Requirements: 4.1, 4.2, 4.4, 9.1, 9.2
struct DimmedBackgroundShape: Shape {
    /// The rectangular area to cut out from the dimmed background
    let cutout: CGRect
    
    /// Corner radius for the cutout hole to create a rounded appearance
    let cornerRadius: CGFloat
    
    /// Creates a dimmed background shape with a cutout hole
    /// - Parameters:
    ///   - cutout: The rectangular area to cut out (spotlight area)
    ///   - cornerRadius: Corner radius for the cutout (default: 12)
    init(cutout: CGRect, cornerRadius: CGFloat = 12) {
        self.cutout = cutout
        self.cornerRadius = cornerRadius
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create the full-screen rectangle
        path.addRect(rect)
        
        // Create the cutout hole with rounded corners
        // Using even-odd fill rule, this will subtract the cutout from the full rect
        path.addRoundedRect(
            in: cutout,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        return path
    }
}

#Preview("Centered Cutout") {
    DimmedBackgroundShape(
        cutout: CGRect(x: 100, y: 300, width: 200, height: 100)
    )
    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
    .ignoresSafeArea()
}

#Preview("Top Cutout") {
    DimmedBackgroundShape(
        cutout: CGRect(x: 50, y: 100, width: 300, height: 80)
    )
    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
    .ignoresSafeArea()
}

#Preview("Large Corner Radius") {
    DimmedBackgroundShape(
        cutout: CGRect(x: 100, y: 300, width: 200, height: 100),
        cornerRadius: 24
    )
    .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
    .ignoresSafeArea()
}
