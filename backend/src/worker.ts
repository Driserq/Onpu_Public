import { Worker } from 'bullmq';
import { env } from './env.js';
import { redis, redisPub } from './redis.js';
import { jobMetaKey, jobResultKey, jobsPendingKey, jobsRecentKey, userJobEventsChannel } from './keys.js';
import { generateLyricsData, generateTranslations } from './gemini.js';
import { normalizeIsHigh, stripCodeFences } from './sanitize.js';
import type { LyricsJobResult } from './types.js';
import { createHash } from 'node:crypto';

type JobData = {
  jobId: string;
  userId: string;
  title: string;
  artist: string;
  lyrics: string;
};

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
} catch (err: any) {
  console.error('[worker] redis ping failed:', err?.message ?? err);
  process.exit(1);
}

async function publish(userId: string, change: { jobId: string; status: string; updatedAt: number; stage?: string; error?: string }) {
  await redisPub.publish(userJobEventsChannel(userId), JSON.stringify(change));
}

async function updateRunningStage(metaKey: string, userId: string, jobId: string, stage: 'translating' | 'lyrics_data' | 'finalizing') {
  const updatedAt = Date.now();
  await redis.hset(metaKey, {
    status: 'running',
    stage,
    userId,
    updatedAt: updatedAt.toString()
  });
  await redis.expire(metaKey, META_TTL_SECONDS);
  await redis.zadd(jobsPendingKey(userId), updatedAt, jobId);
  await publish(userId, { jobId, status: 'running', updatedAt, stage });
}

function linesFromLyrics(lyrics: string): string[] {
  return lyrics
    .trim()
    .split(/\r?\n/)
    .map((l) => l.trimEnd())
    .filter((l) => l.length > 0);
}

function toInputDict(lines: string[]): Record<number, string> {
  const dict: Record<number, string> = {};
  for (let i = 0; i < lines.length; i++) dict[i] = lines[i];
  return dict;
}

export const worker = new Worker<JobData>(
  'lyrics-jobs',
  async (job) => {
    const { jobId, userId, lyrics } = job.data;
    const metaKey = jobMetaKey(jobId);

    try {
      console.log(`[worker] picked up job ${jobId} (user=${userId})`);

      await updateRunningStage(metaKey, userId, jobId, 'translating');

      const lines = linesFromLyrics(lyrics);
      const inputJson = JSON.stringify(toInputDict(lines));


      console.log(`[worker] calling gemini translations for job ${jobId} (lines=${lines.length})`);
      const translationsRaw = await generateTranslations(inputJson);

      await updateRunningStage(metaKey, userId, jobId, 'lyrics_data');
      console.log(`[worker] calling gemini lyricsData for job ${jobId} (lines=${lines.length})`);
      const lyricsDataRaw = await generateLyricsData(inputJson, lines.length);

      await updateRunningStage(metaKey, userId, jobId, 'finalizing');

      const translationsClean = stripCodeFences(translationsRaw);
      const lyricsDataClean = stripCodeFences(lyricsDataRaw);

      let translations: Record<string, string>;
      let lyricsData: LyricsJobResult['lyricsData'];
      
      try {
        translations = JSON.parse(translationsClean) as Record<string, string>;
      } catch (e: any) {
        throw new Error(`Failed to parse translations JSON: ${e?.message ?? e}. Snippet=${translationsClean.slice(0, 500)}`);
      }
      
      // Handle compact format or JSON format based on configuration
      if (env.USE_COMPACT_FORMAT) {
        console.log(`[worker] processing compact format for job ${jobId}`);
        const { sanitizeCompactFormat, validateCompactFormat } = await import('./compact-format.js');
        
        // Sanitize and split into lines
        const sanitized = sanitizeCompactFormat(lyricsDataClean);
        const linesArray = sanitized.split('\n').filter(l => l.trim());
        
        // Validate and store each line
        const compactLyricsData: Record<string, string> = {};
        for (let i = 0; i < linesArray.length; i++) {
          try {
            validateCompactFormat(linesArray[i], i);
            compactLyricsData[i.toString()] = linesArray[i];
          } catch (err: any) {
            console.warn(`[worker] validation warning for job ${jobId} line ${i}: ${err?.message ?? err}`);
            // Store anyway, let iOS handle parsing errors gracefully
            compactLyricsData[i.toString()] = linesArray[i];
          }
        }
        
        lyricsData = compactLyricsData;
      } else {
        // Parse as JSON (backward compatibility)
        console.log(`[worker] processing JSON format for job ${jobId}`);
        const normalized = normalizeIsHigh(lyricsDataClean);
        try {
          lyricsData = JSON.parse(normalized) as LyricsJobResult['lyricsData'];
        } catch (e: any) {
          throw new Error(`Failed to parse lyricsData JSON: ${e?.message ?? e}. Snippet=${normalized.slice(0, 500)}`);
        }
      }

      const result: LyricsJobResult = { translations, lyricsData };

      await redis.set(jobResultKey(jobId), JSON.stringify(result), 'EX', RESULT_TTL_SECONDS);
      const succeededUpdatedAt = Date.now();
      await redis.hset(metaKey, {
        status: 'succeeded',
        updatedAt: succeededUpdatedAt.toString()
      });
      await redis.hdel(metaKey, 'stage');
      await redis.expire(metaKey, META_TTL_SECONDS);
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
    } catch (err: any) {
      const message = err?.message || 'Unknown error';
      console.error(`[worker] failed job ${jobId}: ${message}`);

      const failedUpdatedAt = Date.now();
      await redis.hset(metaKey, {
        status: 'failed',
        error: message,
        updatedAt: failedUpdatedAt.toString()
      });
      await redis.expire(metaKey, META_TTL_SECONDS);
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
  },
  {
    connection: { url: env.REDIS_URL }
  }
);

worker.on('failed', async (job, err) => {
  if (!job) return;
  const jobId = (job.data as any).jobId as string;
  const userId = (job.data as any).userId as string;
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
