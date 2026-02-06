import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { env } from './env.js';
const GEMINI_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models';
const GEMINI_TIMEOUT_MS = env.GEMINI_TIMEOUT_MS;
const RETRYABLE_STATUS = new Set([429, 500, 502, 503, 504]);
function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
async function loadPrompt(fileName) {
    const filePath = path.join(process.cwd(), 'prompts', fileName);
    return await readFile(filePath, 'utf8');
}
function jsonEscapeForJSONStringValue(input) {
    // Mirror the iOS behavior: turn the raw JSON into a JSON-string-safe value.
    // Equivalent to JSON.stringify(input).slice(1, -1)
    const quoted = JSON.stringify(input);
    return quoted.length >= 2 ? quoted.slice(1, -1) : input;
}
async function callGemini(bodyJson) {
    const url = `${GEMINI_ENDPOINT}/${encodeURIComponent(env.GEMINI_MODEL)}:generateContent`;
    const maxAttempts = 4;
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);
        try {
            const res = await fetch(url, {
                method: 'POST',
                headers: {
                    'x-goog-api-key': env.GEMINI_API_KEY,
                    'content-type': 'application/json'
                },
                body: bodyJson,
                signal: controller.signal
            });
            if (!res.ok) {
                const text = await res.text().catch(() => '');
                const msg = `Gemini error ${res.status}: ${text || res.statusText}`;
                if (RETRYABLE_STATUS.has(res.status) && attempt < maxAttempts) {
                    const backoffMs = Math.min(10_000, 1_000 * Math.pow(2, attempt - 1)) + Math.floor(Math.random() * 250);
                    console.warn(`[gemini] retrying (attempt=${attempt}/${maxAttempts}) status=${res.status} backoffMs=${backoffMs}`);
                    await sleep(backoffMs);
                    continue;
                }
                throw new Error(msg);
            }
            const data = await res.json();
            const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (typeof text !== 'string' || text.trim().length === 0) {
                throw new Error('Gemini returned empty response');
            }
            return text;
        }
        catch (err) {
            const isAbort = err?.name === 'AbortError';
            const isRetryableNetwork = isAbort || (typeof err?.message === 'string' && /fetch failed|ECONNRESET|ETIMEDOUT|ENOTFOUND/i.test(err.message));
            if (attempt < maxAttempts && isRetryableNetwork) {
                const backoffMs = Math.min(10_000, 1_000 * Math.pow(2, attempt - 1)) + Math.floor(Math.random() * 250);
                console.warn(`[gemini] retrying (attempt=${attempt}/${maxAttempts}) reason=${isAbort ? 'timeout' : 'network'} backoffMs=${backoffMs}`);
                await sleep(backoffMs);
                continue;
            }
            throw err;
        }
        finally {
            clearTimeout(timeout);
        }
    }
    throw new Error('Gemini call failed after retries');
}
export async function generateTranslations(inputJson) {
    let body = await loadPrompt('GeminiTranslationsBody.json');
    body = body.replace(/\{\{INPUT_JSON\}\}/g, jsonEscapeForJSONStringValue(inputJson));
    return await callGemini(body);
}
export async function generateLyricsData(inputJson, lineCount) {
    let body = await loadPrompt('GeminiLyricsDataBody.json');
    body = body.replace(/\{\{INPUT_JSON\}\}/g, jsonEscapeForJSONStringValue(inputJson));
    body = body.replace(/\{\{LINE_COUNT\}\}/g, String(lineCount));
    return await callGemini(body);
}
