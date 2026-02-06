/**
 * Property 3: Multiple Word Structure Validation
 * 
 * Feature: compact-lyrics-format, Property 3: Multiple Word Structure
 * Validates: Requirements 2.5, 6.2
 */

import fc from 'fast-check';
import { validateCompactFormat, parseCompactFormatForValidation } from './compact-format.js';

console.log('Running Property 3: Multiple Word Structure Validation...');

// Generator for valid word segments
const wordSegmentArb = fc.tuple(
  fc.string({ minLength: 1, maxLength: 5 }).filter(s => !s.includes('|') && !s.includes('_') && s.trim().length > 0),
  fc.array(fc.constantFrom('あ', 'い', 'う', 'え', 'お', 'か', 'き', 'な', 'つ'), { minLength: 1, maxLength: 5 }).map(arr => arr.join('')),
  fc.array(fc.constantFrom('0', '1'), { minLength: 1, maxLength: 5 }).map(arr => arr.join(''))
).map(([word, reading, pitchMap]) => `${word}|${reading}|${pitchMap}`);

// Generator for multiple word lines
const multipleWordsArb = fc.array(wordSegmentArb, { minLength: 2, maxLength: 5 })
  .map(segments => segments.join('_'));

// Feature: compact-lyrics-format, Property 3: Multiple word structure
fc.assert(
  fc.property(multipleWordsArb, (line) => {
    // For any line with multiple words (joined by underscores), validation should pass
    const result = validateCompactFormat(line, 0);
    if (result !== true) {
      throw new Error(`Expected validation to return true for multi-word line: ${line}`);
    }
    
    // Parse and verify structure
    const parsed = parseCompactFormatForValidation(line);
    
    // Should have multiple words
    if (parsed.words.length < 2) {
      throw new Error(`Expected at least 2 words, got ${parsed.words.length}`);
    }
    
    // Each word should have 3 components
    for (const word of parsed.words) {
      if (!word.word || !word.reading || !word.pitchMap) {
        throw new Error(`Expected all word components to be non-empty: ${JSON.stringify(word)}`);
      }
    }
  }),
  { numRuns: 100 }
);

console.log('✅ Property 3 (multiple words) passed');

// Unit tests for specific examples
console.log('Running unit tests for multiple words...');

// Test 2 words
try {
  const line1 = '夏|なつ|01_が|が|0';
  validateCompactFormat(line1, 0);
  const parsed1 = parseCompactFormatForValidation(line1);
  if (parsed1.words.length !== 2) throw new Error('Expected 2 words');
  if (parsed1.words[0].word !== '夏') throw new Error('Expected first word to be 夏');
  if (parsed1.words[1].word !== 'が') throw new Error('Expected second word to be が');
  console.log('✅ Two words test passed');
} catch (error) {
  console.error('❌ Two words test failed:', error);
  process.exit(1);
}

// Test 3 words
try {
  const line2 = 'いなせ|いなせ|011_だね|だね|10_夏|なつ|01';
  validateCompactFormat(line2, 0);
  const parsed2 = parseCompactFormatForValidation(line2);
  if (parsed2.words.length !== 3) throw new Error('Expected 3 words');
  console.log('✅ Three words test passed');
} catch (error) {
  console.error('❌ Three words test failed:', error);
  process.exit(1);
}

// Test 5 words
try {
  const line3 = '東京|とうきょう|0111_に|に|0_行く|いく|01_の|の|0_だ|だ|0';
  validateCompactFormat(line3, 0);
  const parsed3 = parseCompactFormatForValidation(line3);
  if (parsed3.words.length !== 5) throw new Error('Expected 5 words');
  console.log('✅ Five words test passed');
} catch (error) {
  console.error('❌ Five words test failed:', error);
  process.exit(1);
}

// Test that each segment must have 3 components
console.log('Testing invalid multi-word structures...');

try {
  const invalidLine = '夏|なつ|01_が|が'; // Second word missing PitchMap
  validateCompactFormat(invalidLine, 0);
  console.error('❌ Should have rejected line with incomplete word segment');
  process.exit(1);
} catch (error) {
  console.log('✅ Incomplete word segment rejection test passed');
}

try {
  const invalidLine2 = '夏|なつ_が|が|0'; // First word missing PitchMap
  validateCompactFormat(invalidLine2, 0);
  console.error('❌ Should have rejected line with incomplete word segment');
  process.exit(1);
} catch (error) {
  console.log('✅ Incomplete first word segment rejection test passed');
}

console.log('\n✅ All Property 3 tests passed!');
