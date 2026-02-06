/**
 * Property-Based Tests for Compact Format Validator
 * 
 * Uses fast-check for property-based testing with minimum 100 iterations per test.
 */

import fc from 'fast-check';
import {
  validateCompactFormat,
  parseCompactFormatForValidation,
  sanitizeCompactFormat
} from './compact-format.js';

/**
 * Generator for valid binary pitch maps
 */
const binaryPitchMapArb = fc.array(fc.constantFrom('0', '1'), { minLength: 1, maxLength: 10 })
  .map(arr => arr.join(''));

/**
 * Generator for valid word text (kanji or hiragana)
 */
const wordTextArb = fc.oneof(
  fc.string({ minLength: 1, maxLength: 10 }).filter(s => s.trim().length > 0 && !s.includes('|') && !s.includes('_')),
  fc.constant('夏'),
  fc.constant('東京'),
  fc.constant('置いてきた'),
  fc.constant('いなせ')
);

/**
 * Generator for valid hiragana readings
 */
const hiraganaReadingArb = fc.oneof(
  fc.array(fc.constantFrom('あ', 'い', 'う', 'え', 'お', 'か', 'き', 'く', 'け', 'こ', 'な', 'つ', 'ん'), { minLength: 1, maxLength: 10 })
    .map(arr => arr.join('')),
  fc.constant('なつ'),
  fc.constant('とうきょう'),
  fc.constant('おいてきた'),
  fc.constant('いなせ')
);

/**
 * Generator for valid word segments
 */
const wordSegmentArb = fc.tuple(wordTextArb, hiraganaReadingArb, binaryPitchMapArb)
  .map(([word, reading, pitchMap]) => `${word}|${reading}|${pitchMap}`);

/**
 * Generator for valid compact format lines
 */
const compactFormatLineArb = fc.array(wordSegmentArb, { minLength: 1, maxLength: 10 })
  .map(segments => segments.join('_'));

// Feature: compact-lyrics-format, Property 1: Compact Format Structure
console.log('Running Property 1: Compact Format Structure...');

fc.assert(
  fc.property(compactFormatLineArb, (line) => {
    // For any valid compact format line, validation should pass
    const result = validateCompactFormat(line, 0);
    if (result !== true) {
      throw new Error(`Expected validation to return true for line: ${line}`);
    }
    
    // Parsing should succeed and return correct structure
    const parsed = parseCompactFormatForValidation(line);
    if (!parsed.words || parsed.words.length === 0) {
      throw new Error(`Expected parsed words array to be non-empty for line: ${line}`);
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

console.log('✅ Property 1 passed');

// Additional unit tests for specific examples
console.log('Running unit tests...');

// Test single word with kanji
try {
  const line1 = '夏|なつ|01';
  validateCompactFormat(line1, 0);
  const parsed1 = parseCompactFormatForValidation(line1);
  if (parsed1.words.length !== 1) throw new Error('Expected 1 word');
  if (parsed1.words[0].word !== '夏') throw new Error('Expected word to be 夏');
  if (parsed1.words[0].reading !== 'なつ') throw new Error('Expected reading to be なつ');
  if (parsed1.words[0].pitchMap !== '01') throw new Error('Expected pitchMap to be 01');
  console.log('✅ Single word with kanji test passed');
} catch (error) {
  console.error('❌ Single word with kanji test failed:', error);
  process.exit(1);
}

// Test multiple words
try {
  const line2 = 'いなせ|いなせ|011_だね|だね|10_夏|なつ|01';
  validateCompactFormat(line2, 0);
  const parsed2 = parseCompactFormatForValidation(line2);
  if (parsed2.words.length !== 3) throw new Error('Expected 3 words');
  console.log('✅ Multiple words test passed');
} catch (error) {
  console.error('❌ Multiple words test failed:', error);
  process.exit(1);
}

// Test invalid format (wrong number of components)
try {
  const invalidLine = '夏|なつ'; // Missing PitchMap
  validateCompactFormat(invalidLine, 0);
  console.error('❌ Should have thrown error for invalid format');
  process.exit(1);
} catch (error) {
  console.log('✅ Invalid format rejection test passed');
}

// Test sanitization
try {
  const raw = '  夏|なつ|01  ';
  const sanitized = sanitizeCompactFormat(raw);
  if (sanitized !== '夏|なつ|01') throw new Error('Expected whitespace to be trimmed');
  console.log('✅ Sanitization test passed');
} catch (error) {
  console.error('❌ Sanitization test failed:', error);
  process.exit(1);
}

console.log('\n✅ All Property 1 tests passed!');
