//
//  OnboardingCoordinator.swift
//  Uta
//
//  Created for Interactive Onboarding Module
//  Main orchestration view that manages the tutorial flow
//

import SwiftUI

/// Main orchestration view that manages the interactive onboarding tutorial flow.
/// Coordinates between LyricsView and popup overlays to guide users
/// through core app interactions using real UI components.
///
/// Requirements: 2.1, 5.2, 6.4
struct OnboardingCoordinator: View {
    /// Observable state managing the onboarding flow
    @State private var state = OnboardingState()
    
    /// Controls whether the English translation is visible in LyricsView
    /// Initially false for Step 1 (tap to reveal)
    @State private var showTranslation = false

    @State private var showFallbackNext = false

    @State private var showIntroSlides = true

    @State private var introIndex = 0

    @State private var showInterlude = false

    @State private var showMainTabs = false

    @State private var currentTab: MainTabView.Tab = .home

    @State private var didVisitLibrary = false

    @State private var didTapAdd = false

    @State private var showPostKanjiMessage = false

    @State private var showSignupPanel = false

    @State private var bannerHidden = false

    @State private var showAddSongSheet = false

    @State private var showLibraryLock = false

    @State private var showLibraryCoach = false

    @State private var didLongPressTargetKanji = false
    
    /// Binding to communicate completion status back to RootView
    /// When set to true, RootView will route to the main app interface
    @Binding var isOnboardingComplete: Bool

    private let targetKanji = "枯"
    private let targetLineIndex = 0
    private let libraryCoachText = "Tap your new song to open it"

    private let onboardingTitle = "Bashō Haiku"
    private let onboardingArtist = "Matsuo Bashō"
    private let onboardingLyrics = "旅に病んで\n夢は枯野を\nかけ廻る"

    private let introSlides = OnboardingIntroSlide.defaults

    private var sampleTranslations: [Int: String] {
        let lines = OnboardingSampleContent.bashoHaiku.englishTranslation
            .split(separator: "\n")
            .map(String.init)
        return Dictionary(uniqueKeysWithValues: lines.enumerated().map { ($0.offset, $0.element) })
    }

    private var bannerMessage: String {
        if showMainTabs {
            if showAddSongSheet {
                return ""
            }

            if !didVisitLibrary {
                return "Tap the Library tab to continue"
            }

            guard !didTapAdd else { return "" }

            if currentTab == .library {
                return "Tap Add to add the example song"
            }

            return "Return to Library to tap Add"
        }

        if showLibraryLock {
            return showLibraryCoach ? libraryCoachText : ""
        }

        if !showIntroSlides, !showInterlude {
            return state.currentStep.instructionText
        }

        return ""
    }
    
    var body: some View {
        ZStack {
            if showIntroSlides {
                OnboardingIntroSlidesView(
                    slides: introSlides,
                    currentIndex: $introIndex,
                    onNext: handleIntroNext
                )
                .transition(.opacity)
            }

            if showInterlude {
                OnboardingInterludeView(onFinished: handleInterludeFinished)
                    .transition(.opacity)
            }

            if showMainTabs {
                MainTabView(
                    initialTab: .home,
                    onTabSelection: handleMainTabSelection,
                    isLibraryOnboardingActive: true,
                    onLibraryAddTap: handleLibraryAddTap
                )
                    .sheet(isPresented: $showAddSongSheet, onDismiss: handleAddSongDismiss) {
                        AddSongView(
                            prefilledTitle: onboardingTitle,
                            prefilledArtist: onboardingArtist,
                            prefilledLyrics: onboardingLyrics,
                            onboardingMessage: "Tap Save to run the example",
                            onOnboardingSave: handleOnboardingSave
                        )
                    }
                    .transition(.opacity)
            }

            if showLibraryLock {
                LibraryView(
                    selectedSong: .constant(nil),
                    isOnboardingActive: true,
                    onboardingTargetJobTitle: onboardingTitle,
                    showCoachMark: $showLibraryCoach,
                    onOnboardingSongTap: handleLibrarySongTap
                )
                .transition(.opacity)
            }

            if !showIntroSlides, !showInterlude, !showMainTabs, !showLibraryLock {
                ZStack {
                    LyricsView(
                        lyricsLines: OnboardingSampleContent.bashoHaiku.lyricsData,
                        translations: sampleTranslations,
                        isOnboardingActive: true,
                        onboardingStep: state.currentStep,
                        onboardingTargetLineIndex: targetLineIndex,
                        onboardingTargetKanji: targetKanji,
                        onboardingShowTranslation: $showTranslation,
                        onOnboardingLineTap: handleOnboardingLineTap,
                        onOnboardingNextArrowTap: handleOnboardingNextArrowTap,
                        onOnboardingKanjiLongPress: handleOnboardingKanjiLongPress,
                        onOnboardingKanjiModalDismiss: handleOnboardingKanjiModalDismiss
                    )

                    if state.currentStep != .completed {
                        if showFallbackNext {
                            VStack {
                                Spacer()
                                Button("Next") {
                                    handleFallbackNext()
                                }
                                .buttonStyle(BrandedPrimaryButtonStyle())
                                .padding(.horizontal)
                                .padding(.bottom, 144)
                            }
                        }
                    }
                }
                .overlay {
                    if showPostKanjiMessage {
                        PostKanjiMessageOverlay(message: "Great! One more thing to get you started..")
                            .transition(.opacity)
                    }
                }
                .overlay {
                    if showSignupPanel {
                        OnboardingSignupPanelView(onContinue: completeOnboarding)
                            .transition(.move(edge: .trailing))
                    }
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if !showIntroSlides, !showInterlude, !showAddSongSheet, !bannerHidden {
                OnboardingPopupOverlay(message: bannerMessage)
            }
        }
    }

    private func handleOnboardingLineTap() {
        guard state.currentStep == .tapToReveal else { return }
        showTranslation = true
        didLongPressTargetKanji = false
        state.advanceStep()
        showFallbackNext = false
    }

    private func handleOnboardingNextArrowTap() {
        guard state.currentStep == .tapArrow else { return }
        state.advanceStep()
    }

    private func handleOnboardingKanjiLongPress() {
        guard state.currentStep == .longPressKanji else { return }
        didLongPressTargetKanji = true
    }

    private func handleOnboardingKanjiModalDismiss() {
        guard state.currentStep == .longPressKanji, didLongPressTargetKanji else { return }
        showFallbackNext = true
    }

    private func handleFallbackNext() {
        switch state.currentStep {
        case .tapToReveal:
            break
        case .tapArrow:
            break
        case .longPressKanji:
            state.advanceStep()
            startPostKanjiSequence()
        case .completed:
            break
        }
        showFallbackNext = false
    }

    private func handleIntroNext() {
        if introIndex < introSlides.count - 1 {
            introIndex += 1
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                showIntroSlides = false
                showInterlude = true
            }
        }
    }

    private func handleInterludeFinished() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showInterlude = false
            showMainTabs = true
            currentTab = .home
            didVisitLibrary = false
            didTapAdd = false
            bannerHidden = false
        }
    }

    private func handleMainTabSelection(_ tab: MainTabView.Tab) {
        guard showMainTabs else { return }
        currentTab = tab
        if tab == .library {
            didVisitLibrary = true
        }
    }

    private func handleLibraryAddTap() {
        guard showMainTabs, didVisitLibrary else { return }
        didTapAdd = true
        showAddSongSheet = true
    }

    private func handleAddSongDismiss() {
        guard showMainTabs, !showLibraryLock else { return }
        didTapAdd = false
    }

    private func handleOnboardingSave() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showAddSongSheet = false
            showMainTabs = false
            showLibraryLock = true
            showLibraryCoach = false
        }
    }

    private func handleLibrarySongTap() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showLibraryCoach = false
            showLibraryLock = false
            state.currentStep = .tapToReveal
            bannerHidden = false
        }
    }

    private func startPostKanjiSequence() {
        showPostKanjiMessage = false
        showSignupPanel = false
        withAnimation(.easeInOut(duration: 0.25)) {
            bannerHidden = true
        }
        Task {
            do {
                try await Task.sleep(for: .seconds(0.25))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showPostKanjiMessage = true
            }
            do {
                try await Task.sleep(for: .seconds(1.4))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                showPostKanjiMessage = false
            }
            withAnimation(.easeInOut(duration: 0.35)) {
                showSignupPanel = true
            }
        }
    }

    private func completeOnboarding() {
        isOnboardingComplete = true
    }

    
}

#Preview("Initial State") {
    OnboardingCoordinator(isOnboardingComplete: .constant(false))
}

#Preview("With Binding Test") {
    struct PreviewWrapper: View {
        @State private var isComplete = false
        
        var body: some View {
            VStack {
                if isComplete {
                    Text("Onboarding Complete!")
                        .font(.title)
                        .foregroundStyle(.green)
                } else {
                    OnboardingCoordinator(isOnboardingComplete: $isComplete)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
