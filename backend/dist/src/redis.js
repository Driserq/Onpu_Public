import Redis from 'ioredis';
import { env } from './env.js';
export const redis = new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: null
});
export const redisPub = new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: null
});
export const redisSub = new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: null
});
for (const [name, client] of Object.entries({ redis, redisPub, redisSub })) {
    client.on('error', (err) => {
        console.error(`[${name}] redis error:`, err?.message ?? err);
    });
}
