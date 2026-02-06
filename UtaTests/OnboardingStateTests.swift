//
//  OnboardingStateTests.swift
//  UtaTests
//
//  Unit tests for OnboardingState observable class
//  Tests step transitions, completion state, and skip functionality
//

import Testing
@testable import Uta

@MainActor
struct OnboardingStateTests {
    
    // MARK: - Initial State Tests
    
    @Test("OnboardingState initializes with correct default values")
    func testInitialState() {
        let state = OnboardingState()
        
        #expect(state.currentStep == .tapToReveal, "Should start at tapToReveal step")
        #expect(state.isComplete == false, "Should not be complete initially")
        #expect(state.targetFrame == .zero, "Target frame should be zero initially")
    }
    
    // MARK: - Step Transition Tests
    
    @Test("advanceStep transitions from tapToReveal to tapArrow")
    func testAdvanceFromTapToReveal() {
        let state = OnboardingState()
        state.currentStep = .tapToReveal
        
        state.advanceStep()
        
        #expect(state.currentStep == .tapArrow,
                "Should transition to tapArrow step")
        #expect(state.isComplete == false, 
                "Should not be complete after first step")
    }
    
    @Test("advanceStep transitions from tapArrow to longPressKanji")
    func testAdvanceFromTapArrow() {
        let state = OnboardingState()
        state.currentStep = .tapArrow
        
        state.advanceStep()
        
        #expect(state.currentStep == .longPressKanji,
                "Should transition to longPressKanji step")
        #expect(state.isComplete == false,
                "Should not be complete after tapArrow step")
    }

    @Test("advanceStep transitions from longPressKanji to completed")
    func testAdvanceFromLongPressKanji() {
        let state = OnboardingState()
        state.currentStep = .longPressKanji

        state.advanceStep()

        #expect(state.currentStep == .completed,
                "Should transition to completed step")
        #expect(state.isComplete == true,
                "Should mark onboarding as complete")
    }
    
    @Test("advanceStep does nothing when already completed")
    func testAdvanceFromCompleted() {
        let state = OnboardingState()
        state.currentStep = .completed
        state.isComplete = true
        
        state.advanceStep()
        
        #expect(state.currentStep == .completed, 
                "Should remain in completed step")
        #expect(state.isComplete == true, 
                "Should remain complete")
    }
    
    @Test("advanceStep progresses through full flow")
    func testFullStepProgression() {
        let state = OnboardingState()
        
        // Start at tapToReveal
        #expect(state.currentStep == .tapToReveal)
        #expect(state.isComplete == false)
        
        // Advance to longPressKanji
        state.advanceStep()
        #expect(state.currentStep == .tapArrow)
        #expect(state.isComplete == false)

        // Advance to longPressKanji
        state.advanceStep()
        #expect(state.currentStep == .longPressKanji)
        #expect(state.isComplete == false)
        
        // Advance to completed
        state.advanceStep()
        #expect(state.currentStep == .completed)
        #expect(state.isComplete == true)
        
        // Further advances do nothing
        state.advanceStep()
        #expect(state.currentStep == .completed)
        #expect(state.isComplete == true)
    }
    
    // MARK: - Target Frame Tests
    
    @Test("targetFrame can be updated")
    func testTargetFrameUpdate() {
        let state = OnboardingState()
        
        let newFrame = CGRect(x: 10, y: 20, width: 100, height: 50)
        state.targetFrame = newFrame
        
        #expect(state.targetFrame == newFrame, 
                "Target frame should be updated")
    }
    
    @Test("targetFrame updates are independent of step changes")
    func testTargetFrameIndependentOfSteps() {
        let state = OnboardingState()
        
        let frame1 = CGRect(x: 10, y: 20, width: 100, height: 50)
        state.targetFrame = frame1
        
        state.advanceStep()
        
        #expect(state.targetFrame == frame1, 
                "Target frame should persist across step changes")
        
        let frame2 = CGRect(x: 50, y: 100, width: 200, height: 80)
        state.targetFrame = frame2
        
        #expect(state.targetFrame == frame2, 
                "Target frame should be updatable at any step")
    }
    
    // MARK: - OnboardingStep Enum Tests
    
    @Test("OnboardingStep provides correct instruction text for tapToReveal")
    func testTapToRevealInstructionText() {
        let step = OnboardingStep.tapToReveal
        #expect(step.instructionText == "Tap the Japanese line to reveal translation",
                "Should provide correct instruction for tap step")
    }
    
    @Test("OnboardingStep provides correct instruction text for longPressKanji")
    func testLongPressKanjiInstructionText() {
        let step = OnboardingStep.longPressKanji
        #expect(step.instructionText == "Long-press the Kanji to continue",
                "Should provide correct instruction for long-press step")
    }

    @Test("OnboardingStep provides correct instruction text for tapArrow")
    func testTapArrowInstructionText() {
        let step = OnboardingStep.tapArrow
        #expect(step.instructionText == "Tap arrow to highlight the next line",
                "Should provide correct instruction for arrow step")
    }
    
    @Test("OnboardingStep provides empty instruction text for completed")
    func testCompletedInstructionText() {
        let step = OnboardingStep.completed
        #expect(step.instructionText == "",
                "Should provide empty instruction for completed step")
    }
}
