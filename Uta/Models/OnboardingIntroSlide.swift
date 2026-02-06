import Foundation

struct OnboardingIntroSlide: Identifiable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let systemImage: String

    init(id: UUID = UUID(), title: String, message: String, systemImage: String) {
        self.id = id
        self.title = title
        self.message = message
        self.systemImage = systemImage
    }
}

extension OnboardingIntroSlide {
    static let defaults: [OnboardingIntroSlide] = [
        OnboardingIntroSlide(
            title: "Welcome to Onpu",
            message: "Learn Japanese through songs with real lyrics and helpful guidance.",
            systemImage: "music.note.list"
        ),
        OnboardingIntroSlide(
            title: "Tap to reveal",
            message: "Tap a Japanese line to show the English translation.",
            systemImage: "hand.tap"
        ),
        OnboardingIntroSlide(
            title: "Long‑press Kanji",
            message: "Press a character to open the dictionary and learn more.",
            systemImage: "character.book.closed"
        )
    ]
}
