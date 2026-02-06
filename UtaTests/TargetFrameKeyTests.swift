//
//  TargetFrameKeyTests.swift
//  UtaTests
//
//  Unit tests for TargetFrameKey PreferenceKey
//

import XCTest
import Testing
import SwiftUI
@testable import Uta

final class TargetFrameKeyTests: XCTestCase {
    
    // MARK: - Default Value Tests
    
    func testDefaultValueIsZero() {
        // Verify that the default value is CGRect.zero
        XCTAssertEqual(TargetFrameKey.defaultValue, .zero)
    }
    
    // MARK: - Reduce Function Tests
    
    func testReduceTakesLatestValue() {
        // Given: An initial frame value
        var currentValue = CGRect(x: 10, y: 20, width: 100, height: 50)
        
        // When: A new frame value is provided
        let newFrame = CGRect(x: 50, y: 100, width: 200, height: 150)
        TargetFrameKey.reduce(value: &currentValue, nextValue: { newFrame })
        
        // Then: The current value should be replaced with the new value
        XCTAssertEqual(currentValue, newFrame)
    }
    
    func testReduceReplacesZeroWithValidFrame() {
        // Given: The default zero frame
        var currentValue = CGRect.zero
        
        // When: A valid frame is provided
        let validFrame = CGRect(x: 100, y: 200, width: 300, height: 400)
        TargetFrameKey.reduce(value: &currentValue, nextValue: { validFrame })
        
        // Then: The zero frame should be replaced
        XCTAssertEqual(currentValue, validFrame)
    }
    
    func testReduceSequenceUsesLatestFrame() {
        // Given: A sequence of frame updates
        var currentValue = CGRect.zero
        let frames = [
            CGRect(x: 0, y: 0, width: 100, height: 100),
            CGRect(x: 50, y: 50, width: 150, height: 150),
            CGRect(x: 100, y: 100, width: 200, height: 200)
        ]
        
        // When: Multiple frames are reduced in sequence
        for frame in frames {
            TargetFrameKey.reduce(value: &currentValue, nextValue: { frame })
        }
        
        // Then: The final value should be the last frame in the sequence
        XCTAssertEqual(currentValue, frames.last)
    }
    
    func testReduceWithNegativeCoordinates() {
        // Given: A frame with negative coordinates (edge case)
        var currentValue = CGRect.zero
        let negativeFrame = CGRect(x: -50, y: -100, width: 200, height: 300)
        
        // When: The negative frame is reduced
        TargetFrameKey.reduce(value: &currentValue, nextValue: { negativeFrame })
        
        // Then: The negative frame should be accepted (coordinate space may vary)
        XCTAssertEqual(currentValue, negativeFrame)
    }
    
    func testReduceWithLargeFrameValues() {
        // Given: A frame with large coordinate values
        var currentValue = CGRect.zero
        let largeFrame = CGRect(x: 10000, y: 20000, width: 5000, height: 8000)
        
        // When: The large frame is reduced
        TargetFrameKey.reduce(value: &currentValue, nextValue: { largeFrame })
        
        // Then: The large frame should be accepted
        XCTAssertEqual(currentValue, largeFrame)
    }
    
    func testReduceWithZeroDimensions() {
        // Given: A frame with zero width and height
        var currentValue = CGRect(x: 100, y: 100, width: 200, height: 200)
        let zeroSizeFrame = CGRect(x: 50, y: 50, width: 0, height: 0)
        
        // When: The zero-size frame is reduced
        TargetFrameKey.reduce(value: &currentValue, nextValue: { zeroSizeFrame })
        
        // Then: The zero-size frame should replace the current value
        XCTAssertEqual(currentValue, zeroSizeFrame)
    }
}


// MARK: - Property-Based Tests

/// Property-Based Test: Spotlight Reactivity
/// **Validates: Requirements 8.4**
///
/// This test verifies that the TargetFrameKey reduce function always returns
/// the most recent frame value, regardless of the sequence of frame updates.
/// This ensures the spotlight overlay reacts correctly to frame changes.
@Suite("TargetFrameKey Property Tests")
struct TargetFrameKeyPropertyTests {
    
    @Test("Property 3: Spotlight Reactivity - reduce returns most recent value",
          arguments: 0..<100)
    func testSpotlightReactivity(iteration: Int) async throws {
        // Generate a random sequence of CGRect frame updates
        let sequenceLength = Int.random(in: 1...20)
        var frames: [CGRect] = []
        
        for _ in 0..<sequenceLength {
            let x = CGFloat.random(in: -1000...2000)
            let y = CGFloat.random(in: -1000...2000)
            let width = CGFloat.random(in: 0...1000)
            let height = CGFloat.random(in: 0...1000)
            frames.append(CGRect(x: x, y: y, width: width, height: height))
        }
        
        // Apply the reduce function to simulate frame updates
        var currentValue = CGRect.zero
        
        for frame in frames {
            TargetFrameKey.reduce(value: &currentValue, nextValue: { frame })
        }
        
        // Verify: The final value should be the most recent (last) frame
        let expectedFrame = frames.last!
        #expect(currentValue == expectedFrame,
                "Iteration \(iteration): reduce should return the most recent frame value. " +
                "Expected \(expectedFrame), got \(currentValue)")
    }
    
    @Test("Property 3: Spotlight Reactivity - handles empty to non-empty transitions")
    func testEmptyToNonEmptyTransitions() async throws {
        // Test 100 iterations of zero frame transitioning to valid frame
        for iteration in 0..<100 {
            var currentValue = CGRect.zero
            
            // Generate random valid frame
            let x = CGFloat.random(in: 0...1000)
            let y = CGFloat.random(in: 0...1000)
            let width = CGFloat.random(in: 1...500)
            let height = CGFloat.random(in: 1...500)
            let validFrame = CGRect(x: x, y: y, width: width, height: height)
            
            // Apply reduce
            TargetFrameKey.reduce(value: &currentValue, nextValue: { validFrame })
            
            // Verify the zero frame is replaced with the valid frame
            #expect(currentValue == validFrame,
                    "Iteration \(iteration): Should replace zero frame with valid frame")
            #expect(currentValue != .zero,
                    "Iteration \(iteration): Should no longer be zero after update")
        }
    }
    
    @Test("Property 3: Spotlight Reactivity - handles rapid frame changes")
    func testRapidFrameChanges() async throws {
        // Test 100 iterations of rapid frame changes (simulating animation frames)
        for iteration in 0..<100 {
            var currentValue = CGRect.zero
            
            // Generate a sequence of frames that simulate smooth animation
            let startX = CGFloat.random(in: 0...500)
            let startY = CGFloat.random(in: 0...500)
            let endX = CGFloat.random(in: 500...1000)
            let endY = CGFloat.random(in: 500...1000)
            let width = CGFloat.random(in: 50...200)
            let height = CGFloat.random(in: 50...200)
            
            let steps = Int.random(in: 5...15)
            var frames: [CGRect] = []
            
            for step in 0...steps {
                let progress = CGFloat(step) / CGFloat(steps)
                let x = startX + (endX - startX) * progress
                let y = startY + (endY - startY) * progress
                frames.append(CGRect(x: x, y: y, width: width, height: height))
            }
            
            // Apply all frames
            for frame in frames {
                TargetFrameKey.reduce(value: &currentValue, nextValue: { frame })
            }
            
            // Verify the final frame is the last one in the sequence
            #expect(currentValue == frames.last!,
                    "Iteration \(iteration): Should end at the final frame position")
        }
    }
    
    @Test("Property 3: Spotlight Reactivity - handles edge case dimensions")
    func testEdgeCaseDimensions() async throws {
        // Test 100 iterations with edge case frame dimensions
        for iteration in 0..<100 {
            var currentValue = CGRect.zero
            
            // Generate frames with edge case dimensions
            let edgeCases: [CGRect] = [
                CGRect(x: 0, y: 0, width: 0, height: 0),  // Zero size
                CGRect(x: -100, y: -100, width: 50, height: 50),  // Negative origin
                CGRect(x: 10000, y: 10000, width: 1, height: 1),  // Large coordinates, tiny size
                CGRect(x: 0, y: 0, width: 10000, height: 10000),  // Huge size
                CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)  // Fractional values
            ]
            
            // Pick a random edge case
            let selectedFrame = edgeCases.randomElement()!
            
            // Apply reduce
            TargetFrameKey.reduce(value: &currentValue, nextValue: { selectedFrame })
            
            // Verify the edge case frame is accepted
            #expect(currentValue == selectedFrame,
                    "Iteration \(iteration): Should accept edge case frame \(selectedFrame)")
        }
    }
}
