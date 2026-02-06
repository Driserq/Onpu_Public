/**
 * Property 2: PitchMap Binary Validation
 * 
 * Feature: compact-lyrics-format, Property 2: PitchMap Binary Validation
 * Validates: Requirements 2.4, 6.4
 */

import fc from 'fast-check';
import { validateCompactFormat } from './compact-format.js';

console.log('Running Property 2: PitchMap Binary Validation...');

// Generator for valid binary pitch maps
const validBinaryPitchMapArb = fc.array(fc.constantFrom('0', '1'), { minLength: 1, maxLength: 10 })
  .map(arr => arr.join(''));

// Feature: compact-lyrics-format, Property 2: PitchMap binary validation
fc.assert(
  fc.property(validBinaryPitchMapArb, (pitchMap) => {
    // For any valid binary PitchMap, validation should pass
    const line = `test|てすと|${pitchMap}`;
    const result = validateCompactFormat(line, 0);
    if (result !== true) {
      throw new Error(`Expected validation to return true for binary PitchMap: ${pitchMap}`);
    }
  }),
  { numRuns: 100 }
);

console.log('✅ Property 2 (valid binary) passed');

// Test that non-binary PitchMaps are rejected
console.log('Testing non-binary PitchMap rejection...');

const invalidPitchMaps = ['abc', '012', '2', 'high', 'low', '0a1', ''];

for (const invalidPitchMap of invalidPitchMaps) {
  try {
    const line = `test|てすと|${invalidPitchMap}`;
    validateCompactFormat(line, 0);
    console.error(`❌ Should have rejected invalid PitchMap: ${invalidPitchMap}`);
    process.exit(1);
  } catch (error) {
    // Expected to throw
    if (error instanceof Error && error.message.includes('non-binary')) {
      // Good, it was rejected for the right reason
    } else if (invalidPitchMap === '') {
      // Empty PitchMap is caught by the "non-empty" check
    } else {
      console.error(`❌ Wrong error for invalid PitchMap ${invalidPitchMap}:`, error);
      process.exit(1);
    }
  }
}

console.log('✅ Non-binary PitchMap rejection tests passed');

// Property test with random invalid characters
console.log('Testing random invalid PitchMaps...');

const invalidCharArb = fc.string({ minLength: 1, maxLength: 5 })
  .filter(s => {
    // Must not be valid binary, must not contain pipes or underscores, must not be empty after trim
    return !/^[01]+$/.test(s) && !s.includes('|') && !s.includes('_') && s.trim().length > 0;
  });

fc.assert(
  fc.property(invalidCharArb, (invalidPitchMap) => {
    const line = `test|てすと|${invalidPitchMap}`;
    try {
      validateCompactFormat(line, 0);
      throw new Error(`Should have rejected invalid PitchMap: ${invalidPitchMap}`);
    } catch (error) {
      // Expected to throw - either for non-binary or for empty component
      if (error instanceof Error && (error.message.includes('non-binary') || error.message.includes('non-empty'))) {
        // Good
        return true;
      }
      throw error;
    }
  }),
  { numRuns: 100 }
);


console.log('✅ Random invalid PitchMap tests passed');

console.log('\n✅ All Property 2 tests passed!');
