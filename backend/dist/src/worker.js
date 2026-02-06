import { Worker } from 'bullmq';
import { env } from './env.js';
import { redis, redisPub } from './redis.js';
import { jobMetaKey, jobResultKey, jobsPendingKey, jobsRecentKey, userJobEventsChannel } from './keys.js';
import { generateLyricsData, generateTranslations } from './gemini.js';
import { normalizeIsHigh, stripCodeFences } from './sanitize.js';
import { createHash } from 'node:crypto';
const RESULT_TTL_SECONDS = 24 * 60 * 60;
const META_TTL_SECONDS = 24 * 60 * 60;
const RECENT_WINDOW_SECONDS = 24 * 60 * 60;
const RECENT_MAX_SIZE = 500;
console.log(`[worker] starting redisUrl=${env.REDIS_URL}`);
console.log(`[worker] gemini model=${env.GEMINI_MODEL} timeoutMs=${env.GEMINI_TIMEOUT_MS}`);
console.log(`[worker] gemini key sha256=${createHash('sha256').update(env.GEMINI_API_KEY).digest('hex').slice(0, 12)}`);
try {
    const pong = await redis.ping();
    console.log(`[worker] redis ping: ${pong}`);
}
catch (err) {
    console.error('[worker] redis ping failed:', err?.message ?? err);
    process.exit(1);
}
async function publish(userId, change) {
    await redisPub.publish(userJobEventsChannel(userId), JSON.stringify(change));
}
function linesFromLyrics(lyrics) {
    return lyrics
        .trim()
        .split(/\r?\n/)
        .map((l) => l.trimEnd())
        .filter((l) => l.length > 0);
}
function toInputDict(lines) {
    const dict = {};
    for (let i = 0; i < lines.length; i++)
        dict[i] = lines[i];
    return dict;
}
export const worker = new Worker('lyrics-jobs', async (job) => {
    const { jobId, userId, lyrics } = job.data;
    const metaKey = jobMetaKey(jobId);
    try {
        console.log(`[worker] picked up job ${jobId} (user=${userId})`);
        await redis.hset(metaKey, {
            status: 'running',
            userId,
            updatedAt: Date.now().toString()
        });
        const runningUpdatedAt = Date.now();
        await redis.zadd(jobsPendingKey(userId), runningUpdatedAt, jobId);
        await publish(userId, { jobId, status: 'running', updatedAt: runningUpdatedAt });
        const lines = linesFromLyrics(lyrics);
        const inputJson = JSON.stringify(toInputDict(lines));
        console.log(`[worker] calling gemini for job ${jobId} (lines=${lines.length})`);
        const [translationsRaw, lyricsDataRaw] = await Promise.all([
            generateTranslations(inputJson),
            generateLyricsData(inputJson, lines.length)
        ]);
        const translationsClean = stripCodeFences(translationsRaw);
        let lyricsDataClean = stripCodeFences(lyricsDataRaw);
        lyricsDataClean = normalizeIsHigh(lyricsDataClean);
        let translations;
        let lyricsData;
        try {
            translations = JSON.parse(translationsClean);
        }
        catch (e) {
            throw new Error(`Failed to parse translations JSON: ${e?.message ?? e}. Snippet=${translationsClean.slice(0, 500)}`);
        }
        try {
            lyricsData = JSON.parse(lyricsDataClean);
        }
        catch (e) {
            throw new Error(`Failed to parse lyricsData JSON: ${e?.message ?? e}. Snippet=${lyricsDataClean.slice(0, 500)}`);
        }
        const result = { translations, lyricsData };
        await redis.set(jobResultKey(jobId), JSON.stringify(result), 'EX', RESULT_TTL_SECONDS);
        await redis.hset(metaKey, {
            status: 'succeeded',
            updatedAt: Date.now().toString()
        });
        await redis.expire(metaKey, META_TTL_SECONDS);
        const succeededUpdatedAt = Date.now();
        await redis.zrem(jobsPendingKey(userId), jobId);
        const recentKey = jobsRecentKey(userId);
        await redis.zadd(recentKey, succeededUpdatedAt, jobId);
        await redis.zremrangebyscore(recentKey, 0, succeededUpdatedAt - RECENT_WINDOW_SECONDS * 1000);
        const recentSize = await redis.zcard(recentKey);
        if (recentSize > RECENT_MAX_SIZE) {
            await redis.zremrangebyrank(recentKey, 0, recentSize - RECENT_MAX_SIZE - 1);
        }
        await publish(userId, { jobId, status: 'succeeded', updatedAt: succeededUpdatedAt });
        console.log(`[worker] completed job ${jobId}`);
    }
    catch (err) {
        const message = err?.message || 'Unknown error';
        console.error(`[worker] failed job ${jobId}: ${message}`);
        await redis.hset(metaKey, {
            status: 'failed',
            error: message,
            updatedAt: Date.now().toString()
        });
        await redis.expire(metaKey, META_TTL_SECONDS);
        const failedUpdatedAt = Date.now();
        await redis.zrem(jobsPendingKey(userId), jobId);
        const recentKey = jobsRecentKey(userId);
        await redis.zadd(recentKey, failedUpdatedAt, jobId);
        await redis.zremrangebyscore(recentKey, 0, failedUpdatedAt - RECENT_WINDOW_SECONDS * 1000);
        const recentSize = await redis.zcard(recentKey);
        if (recentSize > RECENT_MAX_SIZE) {
            await redis.zremrangebyrank(recentKey, 0, recentSize - RECENT_MAX_SIZE - 1);
        }
        await publish(userId, { jobId, status: 'failed', updatedAt: failedUpdatedAt, error: message });
        throw err;
    }
}, {
    connection: { url: env.REDIS_URL }
});
worker.on('failed', async (job, err) => {
    if (!job)
        return;
    const jobId = job.data.jobId;
    const userId = job.data.userId;
    const metaKey = jobMetaKey(jobId);
    const message = err?.message || 'Unknown error';
    await redis.hset(metaKey, {
        status: 'failed',
        error: message,
        updatedAt: Date.now().toString()
    });
    await redis.expire(metaKey, META_TTL_SECONDS);
    const failedUpdatedAt = Date.now();
    if (userId) {
        await redis.zrem(jobsPendingKey(userId), jobId);
        const recentKey = jobsRecentKey(userId);
        await redis.zadd(recentKey, failedUpdatedAt, jobId);
        await redis.zremrangebyscore(recentKey, 0, failedUpdatedAt - RECENT_WINDOW_SECONDS * 1000);
        const recentSize = await redis.zcard(recentKey);
        if (recentSize > RECENT_MAX_SIZE) {
            await redis.zremrangebyrank(recentKey, 0, recentSize - RECENT_MAX_SIZE - 1);
        }
        await publish(userId, { jobId, status: 'failed', updatedAt: failedUpdatedAt, error: message });
    }
});
console.log('Worker started');
worker.on('error', (err) => {
    console.error('[worker] error:', err?.message ?? err);
});
