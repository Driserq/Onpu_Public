import XCTest
import SwiftUI
@testable import Uta

/// Unit tests for DimmedBackgroundShape
/// Validates Requirements: 4.1, 4.2, 4.4
final class DimmedBackgroundShapeTests: XCTestCase {
    
    // MARK: - Path Creation Tests
    
    func testPathCreatesFullScreenRect() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect(x: 100, y: 300, width: 200, height: 100)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        // The path should contain the full container rect
        XCTAssertFalse(path.isEmpty, "Path should not be empty")
        
        // Verify the path bounds encompass the full container
        let pathBounds = path.boundingRect
        XCTAssertEqual(pathBounds.width, containerRect.width, accuracy: 0.1)
        XCTAssertEqual(pathBounds.height, containerRect.height, accuracy: 0.1)
    }
    
    func testPathIncludesCutoutArea() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect(x: 100, y: 300, width: 200, height: 100)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        // The path should include the cutout area (which will be subtracted via even-odd fill)
        let pathBounds = path.boundingRect
        XCTAssertTrue(pathBounds.contains(cutout), "Path bounds should contain the cutout area")
    }
    
    func testDefaultCornerRadius() {
        // Given
        let cutout = CGRect(x: 100, y: 300, width: 200, height: 100)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // Then
        XCTAssertEqual(shape.cornerRadius, 12, "Default corner radius should be 12")
    }
    
    func testCustomCornerRadius() {
        // Given
        let cutout = CGRect(x: 100, y: 300, width: 200, height: 100)
        let customRadius: CGFloat = 24
        let shape = DimmedBackgroundShape(cutout: cutout, cornerRadius: customRadius)
        
        // Then
        XCTAssertEqual(shape.cornerRadius, customRadius, "Custom corner radius should be preserved")
    }
    
    func testCutoutPosition() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect(x: 50, y: 100, width: 300, height: 80)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        XCTAssertEqual(shape.cutout, cutout, "Cutout should match the provided rectangle")
        XCTAssertFalse(path.isEmpty, "Path should be created successfully")
    }
    
    // MARK: - Edge Cases
    
    func testZeroCutout() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect.zero
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        XCTAssertFalse(path.isEmpty, "Path should still be created with zero cutout")
    }
    
    func testLargeCutout() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect(x: 10, y: 10, width: 380, height: 780)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        XCTAssertFalse(path.isEmpty, "Path should handle large cutouts")
    }
    
    func testCutoutOutsideContainer() {
        // Given
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutout = CGRect(x: 500, y: 900, width: 100, height: 100)
        let shape = DimmedBackgroundShape(cutout: cutout)
        
        // When
        let path = shape.path(in: containerRect)
        
        // Then
        // Path should still be created even if cutout is outside container
        XCTAssertFalse(path.isEmpty, "Path should be created even with cutout outside container")
    }
    
    func testMultipleCutoutPositions() {
        // Test various cutout positions to ensure shape works correctly
        let containerRect = CGRect(x: 0, y: 0, width: 400, height: 800)
        let cutouts = [
            CGRect(x: 0, y: 0, width: 100, height: 100),      // Top-left
            CGRect(x: 300, y: 0, width: 100, height: 100),    // Top-right
            CGRect(x: 0, y: 700, width: 100, height: 100),    // Bottom-left
            CGRect(x: 300, y: 700, width: 100, height: 100),  // Bottom-right
            CGRect(x: 150, y: 350, width: 100, height: 100)   // Center
        ]
        
        for cutout in cutouts {
            // Given
            let shape = DimmedBackgroundShape(cutout: cutout)
            
            // When
            let path = shape.path(in: containerRect)
            
            // Then
            XCTAssertFalse(path.isEmpty, "Path should be created for cutout at \(cutout)")
        }
    }
}
