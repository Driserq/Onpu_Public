import { Queue } from 'bullmq';
import { env } from './env.js';
export const lyricsQueue = new Queue('lyrics-jobs', {
    connection: { url: env.REDIS_URL }
});
