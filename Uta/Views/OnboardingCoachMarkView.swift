import SwiftUI

struct OnboardingCoachMarkView: View {
    let targetFrame: CGRect
    let step: OnboardingStep
    let overrideText: String?
    let showDebug: Bool

    private let cardPadding: CGFloat = 16
    private let arrowSize: CGSize = CGSize(width: 18, height: 10)
    private let minimumSpace: CGFloat = 120

    @State private var cardSize: CGSize = .zero

    init(
        targetFrame: CGRect,
        step: OnboardingStep,
        overrideText: String? = nil,
        showDebug: Bool = false
    ) {
        self.targetFrame = targetFrame
        self.step = step
        self.overrideText = overrideText
        self.showDebug = showDebug
    }

    var body: some View {
        GeometryReader { geometry in
            let position = coachMarkPosition(in: geometry.size)
            let isAbove = position.y < targetFrame.minY

            ZStack {
                if showDebug {
                    Rectangle()
                        .stroke(Color.appAccent, lineWidth: 1.5)
                        .frame(width: targetFrame.width, height: targetFrame.height)
                        .position(x: targetFrame.midX, y: targetFrame.midY)
                }

                VStack(spacing: 0) {
                    if isAbove {
                        coachMarkCard
                        coachMarkArrow(isAbove: false)
                    } else {
                        coachMarkArrow(isAbove: true)
                        coachMarkCard
                    }
                }
                .position(position)
                .animation(.easeInOut(duration: 0.3), value: targetFrame)
            }
        }
        .allowsHitTesting(false)
    }

    private var coachMarkCard: some View {
        Text(overrideText ?? step.instructionText)
            .font(.headline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent.opacity(0.4), lineWidth: 1)
                    }
            }
            .padding(.horizontal, cardPadding)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: CoachMarkCardSizeKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(CoachMarkCardSizeKey.self) { size in
                cardSize = size
            }
    }

    private func coachMarkArrow(isAbove: Bool) -> some View {
        Triangle()
            .fill(Color.appAccent)
            .frame(width: arrowSize.width, height: arrowSize.height)
            .rotationEffect(isAbove ? .degrees(180) : .degrees(0))
            .offset(y: isAbove ? -2 : 2)
    }

    private func coachMarkPosition(in size: CGSize) -> CGPoint {
        let spaceAbove = targetFrame.minY
        let spaceBelow = size.height - targetFrame.maxY
        let midX = targetFrame.midX

        let clampedX = max(cardPadding + cardSize.width / 2,
                           min(size.width - cardPadding - cardSize.width / 2, midX))

        let aboveY = targetFrame.minY - 12 - cardSize.height / 2
        let belowY = targetFrame.maxY + 12 + cardSize.height / 2

        if spaceAbove >= minimumSpace, aboveY > 0 {
            return CGPoint(x: clampedX, y: aboveY)
        }

        if spaceBelow >= minimumSpace, belowY < size.height {
            return CGPoint(x: clampedX, y: belowY)
        }

        let preferAbove = spaceAbove > spaceBelow
        let fallbackY = preferAbove ? max(cardPadding + cardSize.height / 2, aboveY)
            : min(size.height - cardPadding - cardSize.height / 2, belowY)
        return CGPoint(x: clampedX, y: fallbackY)
    }
}

private struct CoachMarkCardSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.appBackground
        OnboardingCoachMarkView(
            targetFrame: CGRect(x: 120, y: 400, width: 140, height: 40),
            step: .tapToReveal
        )
    }
}
