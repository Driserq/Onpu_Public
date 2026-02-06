/**
 * Compact Format Validator
 * 
 * Validates and sanitizes compact format strings from Gemini AI.
 * Format: Word|Reading|PitchMap|KanjiReadings joined by underscore (_)
 * 
 * Requirements: 2.1, 2.4, 6.1, 6.2, 6.4, 6.6
 */

/**
 * Parsed word segment structure
 */
export interface ParsedWordSegment {
  word: string;
  reading: string;
  pitchMap: string;
  kanjiReadings?: string; // Optional 4th component
}

/**
 * Parsed compact format structure
 */
export interface ParsedCompactFormat {
  words: ParsedWordSegment[];
}

/**
 * Sanitize compact format output (strip whitespace, validate structure)
 * @param raw - Raw output from Gemini
 * @returns Sanitized compact format string
 */
export function sanitizeCompactFormat(raw: string): string {
  // Strip leading/trailing whitespace from each line
  return raw.trim();
}

/**
 * Parse compact format to verify structure (for validation)
 * @param compactStr - Compact format string
 * @returns Parsed structure or throws error
 */
export function parseCompactFormatForValidation(compactStr: string): ParsedCompactFormat {
  const words: ParsedWordSegment[] = [];
  
  // Split on underscore to get word segments
  const segments = compactStr.split('_');
  
  for (const segment of segments) {
    if (!segment.trim()) {
      continue; // Skip empty segments
    }
    
    // Split on pipe to get components (use -1 limit to preserve empty strings)
    const parts = segment.split('|');
    
    // Allow 3 parts (legacy/fallback) or 4 parts (new format with KanjiReadings)
    if (parts.length < 3 || parts.length > 4) {
      throw new Error(
        `Invalid segment format: "${segment}". Expected 3 or 4 pipe-separated components, got ${parts.length}`
      );
    }
    
    const word = parts[0];
    const reading = parts[1];
    const pitchMap = parts[2];
    const kanjiReadings = parts.length === 4 ? parts[3] : undefined;
    
    // Word must always be present
    if (!word) {
      throw new Error(
        `Invalid segment: "${segment}". Word component must be non-empty`
      );
    }
    
    // Reading and PitchMap can be empty for English/romaji words
    // Both must be empty together, or both must be non-empty
    if ((reading === '' && pitchMap !== '') || (reading !== '' && pitchMap === '')) {
      throw new Error(
        `Invalid segment: "${segment}". Reading and PitchMap must both be empty (for English) or both be non-empty`
      );
    }
    
    words.push({ word, reading, pitchMap, kanjiReadings });
  }
  
  if (words.length === 0) {
    throw new Error('No valid word segments found in compact format string');
  }
  
  return { words };
}

/**
 * Check if a string contains only binary digits (0 and 1)
 */
function isBinaryString(str: string): boolean {
  return /^[01]+$/.test(str);
}

/**
 * Check if a string is primarily hiragana
 */
function isPrimarilyHiragana(str: string): boolean {
  // Hiragana range: \u3040-\u309F
  const hiraganaCount = (str.match(/[\u3040-\u309F]/g) || []).length;
  return hiraganaCount > 0 && hiraganaCount >= str.length * 0.7;
}

/**
 * Count mora in a hiragana reading string
 * This is a simplified estimation based on small kana detection
 */
function estimateMoraCount(reading: string): number {
  let count = 0;
  const chars = Array.from(reading);
  
  for (let i = 0; i < chars.length; i++) {
    const char = chars[i];
    const nextChar = i + 1 < chars.length ? chars[i + 1] : null;
    
    // Small kana that combine with previous character
    const smallKana = ['ゃ', 'ゅ', 'ょ', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ', 'ゎ', 'っ'];
    
    if (nextChar && smallKana.includes(nextChar)) {
      // Current char + next small kana = 1 mora
      count++;
      i++; // Skip next character
    } else if (!smallKana.includes(char)) {
      // Regular character = 1 mora
      count++;
    }
    // If current char is small kana but wasn't caught above, skip it
  }
  
  return count;
}

/**
 * Validate compact format string from Gemini
 * @param compactStr - Compact format string
 * @param lineNumber - Line number for error reporting
 * @returns true if valid, throws error otherwise
 */
export function validateCompactFormat(compactStr: string, lineNumber: number): boolean {
  try {
    // Parse the structure
    const parsed = parseCompactFormatForValidation(compactStr);
    
    // Validate each word segment
    for (const word of parsed.words) {
      // Skip validation for English words (empty reading and pitchMap)
      if (word.reading === '' && word.pitchMap === '') {
        continue; // Valid English word format
      }
      
      // Validate PitchMap is binary
      if (!isBinaryString(word.pitchMap)) {
        throw new Error(
          `Line ${lineNumber}: PitchMap "${word.pitchMap}" contains non-binary characters. Must be only 0 and 1.`
        );
      }
      
      // Warn if Reading is not primarily hiragana (but don't fail)
      if (!isPrimarilyHiragana(word.reading)) {
        console.warn(
          `[compact-format] Line ${lineNumber}: Reading "${word.reading}" is not primarily hiragana`
        );
      }
      
      // Note: We no longer warn about mora count mismatches because:
      // 1. Gemini's mora counting is linguistically correct (っ, ー, ぅ are separate mora)
      // 2. Our simple algorithm can't match Gemini's sophisticated phonological analysis
      // 3. The iOS parser trusts Gemini's PitchMap length as authoritative
    }
    
    return true;
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Line ${lineNumber}: ${error.message}`);
    }
    throw error;
  }
}
