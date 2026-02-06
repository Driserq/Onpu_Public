export function stripCodeFences(input) {
    return input
        .replace(/```json\s*/g, '')
        .replace(/```\s*/g, '')
        .trim();
}
export function normalizeIsHigh(input) {
    // Matches the Swift sanitization behavior.
    return input
        .replace(/"isHigh"\s*:\s*low\b/g, '"isHigh":false')
        .replace(/"isHigh"\s*:\s*high\b/g, '"isHigh":true')
        .replace(/"isHigh"\s*:\s*"low"/g, '"isHigh":false')
        .replace(/"isHigh"\s*:\s*"high"/g, '"isHigh":true');
}
