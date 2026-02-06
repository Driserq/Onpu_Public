import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import jwt from '@fastify/jwt';
import { z } from 'zod';
import { randomUUID, createHash } from 'node:crypto';

import { env } from './env.js';
import { verifyAppleIdentityToken } from './apple.js';
import { lyricsQueue } from './queue.js';
import { redis, redisPub, redisSub } from './redis.js';
import { jobMetaKey, jobResultKey, jobsPendingKey, jobsRecentKey, userJobEventsChannel } from './keys.js';
import type { JobChange, LyricsJobStatus, LyricsJobView, LongpollResponse, RecentResponse } from './types.js';
import { JobEventBroker } from './jobEventBroker.js';

type ApiJwtPayload = { sub: string };

function sha256Hex(input: string): string {
  return createHash('sha256').update(input, 'utf8').digest('hex');
}

let loggedAppleAudOnce = false;

function requireAppHeader(_app: ReturnType<typeof Fastify>) {
  return async (req: any, reply: any) => {
    const appHeader = req.headers['tarukingu'];
    if (typeof appHeader !== 'string' || appHeader !== env.TARUKINGU) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }
  };
}

function nowMs() {
  return Date.now();
}

function requireAuth(_app: ReturnType<typeof Fastify>) {
  return async (req: any, reply: any) => {
    const appHeader = req.headers['tarukingu'];
    if (typeof appHeader !== 'string' || appHeader !== env.TARUKINGU) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    // Dev bypass (staging only)
    if (env.ALLOW_DEV_BYPASS) {
      const devToken = req.headers['x-dev-token'];
      if (typeof devToken === 'string' && env.DEV_BYPASS_TOKEN && devToken === env.DEV_BYPASS_TOKEN) {
        req.user = { sub: 'dev-user' } satisfies ApiJwtPayload;
        return;
      }
    }

    await req.jwtVerify();
  };
}

function requireDevBypass(_app: ReturnType<typeof Fastify>) {
  return async (req: any, reply: any) => {
    const appHeader = req.headers['tarukingu'];
    if (typeof appHeader !== 'string' || appHeader !== env.TARUKINGU) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }

    if (!env.ALLOW_DEV_BYPASS || !env.DEV_BYPASS_TOKEN) {
      return reply.code(404).send({ error: 'Not found' });
    }
    const devToken = req.headers['x-dev-token'];
    if (typeof devToken !== 'string' || devToken !== env.DEV_BYPASS_TOKEN) {
      return reply.code(401).send({ error: 'Unauthorized' });
    }
  };
}

async function getJobView(jobId: string): Promise<LyricsJobView> {
  const meta = await redis.hgetall(jobMetaKey(jobId));
  const status = (meta.status as LyricsJobStatus | undefined) ?? 'queued';
  const stage = (meta.stage as LyricsJobView['stage'] | undefined) ?? undefined;
  const error = meta.error;
  const updatedAt = parseUpdatedAt(meta);
  if (status === 'succeeded') {
    const resultRaw = await redis.get(jobResultKey(jobId));
    if (resultRaw) {
      return { jobId, status, stage, updatedAt, result: JSON.parse(resultRaw), error: error || undefined };
    }
    // Result expired or ACKed.
    return { jobId, status, stage, updatedAt, error: error || undefined };
  }
  return { jobId, status, stage, updatedAt, error: error || undefined };
}

const META_TTL_SECONDS = 24 * 60 * 60;

function parseUpdatedAt(meta: Record<string, string>): number {
  const raw = meta.updatedAt;
  const n = raw ? Number(raw) : NaN;
  return Number.isFinite(n) ? n : 0;
}

async function requireOwnedJob(jobId: string, userId: string): Promise<Record<string, string> | null> {
  const meta = await redis.hgetall(jobMetaKey(jobId));
  if (!meta.userId) return null;
  if (meta.userId !== userId) return null;
  return meta;
}

async function fetchChangesForJobIds(userId: string, jobIds: string[], sinceMs: number, limit: number): Promise<JobChange[]> {
  const unique = Array.from(new Set(jobIds)).slice(0, limit);
  if (unique.length === 0) return [];

  const pipe = redis.pipeline();
  for (const id of unique) pipe.hgetall(jobMetaKey(id));
  const results = await pipe.exec();

  const changes: JobChange[] = [];
  for (let i = 0; i < unique.length; i++) {
    const id = unique[i];
    const [, meta] = results?.[i] ?? [];
    if (!meta || typeof meta !== 'object') continue;
    if ((meta as any).userId !== userId) continue;
    const updatedAt = parseUpdatedAt(meta as any);
    if (updatedAt <= sinceMs) continue;
    const status = (meta as any).status as string | undefined;
    if (!status) continue;
    const stage = (meta as any).stage as LyricsJobView['stage'] | undefined;
    const error = (meta as any).error as string | undefined;
    changes.push({ jobId: id, status, updatedAt, ...(stage ? { stage } : {}), ...(error ? { error } : {}) });
  }

  changes.sort((a, b) => a.updatedAt - b.updatedAt);
  return changes.slice(0, limit);
}

async function getIndexChanges(userId: string, sinceMs: number, limit: number): Promise<JobChange[]> {
  const minExclusive = `(${sinceMs}`;
  const maxInclusive = '+inf';

  const pendingIds = await redis.zrangebyscore(jobsPendingKey(userId), minExclusive, maxInclusive, 'LIMIT', 0, limit);
  const recentIds = await redis.zrangebyscore(jobsRecentKey(userId), minExclusive, maxInclusive, 'LIMIT', 0, limit);
  const ids = Array.from(new Set([...pendingIds, ...recentIds])).slice(0, limit);
  return await fetchChangesForJobIds(userId, ids, sinceMs, limit);
}

const app = Fastify({ logger: true });

app.log.info({ redisUrl: env.REDIS_URL }, 'api starting');
try {
  const pong = await redis.ping();
  app.log.info({ pong }, 'api redis ping');
} catch (err: any) {
  app.log.error({ err: err?.message ?? err }, 'api redis ping failed');
}

await app.register(cors, {
  origin: true,
  credentials: true
});

await app.register(rateLimit, {
  max: 120,
  timeWindow: '1 minute'
});

await app.register(jwt, {
  secret: env.API_JWT_SECRET
});

const broker = new JobEventBroker(redisSub, fetchChangesForJobIds);
await broker.start();

// Health
app.get('/healthz', async () => ({ ok: true }));

// Root
app.get('/', async () => ({ ok: true, name: 'onpu-backend' }));

// DEV diagnostics
app.get('/v1/debug/queue', { preHandler: requireDevBypass(app) }, async () => {
  const counts = await lyricsQueue.getJobCounts('waiting', 'active', 'delayed', 'failed', 'completed', 'paused');
  const lastId = await redis.get('bull:lyrics-jobs:id');
  const pong = await redis.ping();
  return {
    redisUrl: env.REDIS_URL,
    redisPing: pong,
    lastId,
    counts
  };
});

// Auth
app.post('/v1/auth/apple', {
  config: { rateLimit: { max: 20, timeWindow: '1 minute' } },
  preHandler: requireAppHeader(app)
}, async (req, reply) => {
  const body = z.object({
    identityToken: z.string().min(1),
    nonce: z.string().min(1)
  }).parse(req.body);

  const expectedNonce = sha256Hex(body.nonce);

  const testMode = process.env.APPLE_TEST_MODE === 'true';
  if (testMode && env.NODE_ENV !== 'test') {
    return reply.code(404).send({ error: 'Not found' });
  }

  const verified = testMode
    ? { sub: 'test-user', aud: env.APPLE_AUDIENCE, nonce: expectedNonce }
    : await verifyAppleIdentityToken(body.identityToken);

  if (!loggedAppleAudOnce) {
    loggedAppleAudOnce = true;
    req.log.info({ appleAud: verified.aud, noncePresent: Boolean(verified.nonce) }, 'apple identity token decoded');
  }

  if (!verified.nonce) {
    return reply.code(400).send({ error: 'Missing nonce claim in identity token' });
  }
  if (verified.nonce !== expectedNonce) {
    return reply.code(401).send({ error: 'Nonce mismatch' });
  }

  const accessToken = app.jwt.sign({ sub: verified.sub } satisfies ApiJwtPayload, { expiresIn: '1h' });
  return reply.send({ accessToken, expiresIn: 3600, user: { sub: verified.sub } });
});

app.get('/v1/auth/me', { preHandler: requireAuth(app) }, async (req: any) => {
  const user = req.user as ApiJwtPayload;
  return { ok: true, sub: user.sub };
});

// Jobs
app.post('/v1/jobs', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const body = z.object({
    title: z.string().default(''),
    artist: z.string().default(''),
    lyrics: z.string().min(1)
  }).parse(req.body);

  const user = req.user as ApiJwtPayload;
  const jobId = randomUUID();
  const createdAt = nowMs();

  await redis.hset(jobMetaKey(jobId), {
    status: 'queued',
    userId: user.sub,
    createdAt: createdAt.toString(),
    updatedAt: createdAt.toString()
  });
  await redis.expire(jobMetaKey(jobId), META_TTL_SECONDS);
  await redis.zadd(jobsPendingKey(user.sub), createdAt, jobId);
  await redisPub.publish(userJobEventsChannel(user.sub), JSON.stringify({ jobId, status: 'queued', updatedAt: createdAt }));

  await lyricsQueue.add('analyze', {
    jobId,
    userId: user.sub,
    title: body.title,
    artist: body.artist,
    lyrics: body.lyrics
  }, {
    removeOnComplete: true,
    removeOnFail: true
  });

  const counts = await lyricsQueue.getJobCounts('waiting', 'active', 'delayed', 'failed', 'completed', 'paused');
  app.log.info({ jobId, userId: user.sub, counts }, 'enqueued lyrics job');

  return reply.send({ jobId, status: 'queued' });
});

app.get('/v1/jobs/:id', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const jobId = z.string().uuid().parse(req.params.id);
  const user = req.user as ApiJwtPayload;
  const meta = await requireOwnedJob(jobId, user.sub);
  if (!meta) return reply.code(404).send({ error: 'Not found' });
  return reply.send(await getJobView(jobId));
});

app.get('/v1/jobs/:id/result', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const jobId = z.string().uuid().parse(req.params.id);
  const user = req.user as ApiJwtPayload;
  const meta = await requireOwnedJob(jobId, user.sub);
  if (!meta) return reply.code(404).send({ error: 'Not found' });
  const status = meta.status as string | undefined;
  if (status !== 'succeeded') return reply.code(409).send({ status: status ?? 'queued' });
  const raw = await redis.get(jobResultKey(jobId));
  if (!raw) return reply.code(404).send({ error: 'Not found' });
  return reply.send(JSON.parse(raw));
});

app.post('/v1/jobs/:id/ack', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const jobId = z.string().uuid().parse(req.params.id);
  const user = req.user as ApiJwtPayload;
  const meta = await requireOwnedJob(jobId, user.sub);
  if (!meta) return reply.code(404).send({ error: 'Not found' });

  await redis.del(jobResultKey(jobId));
  await redis.expire(jobMetaKey(jobId), META_TTL_SECONDS);
  await redis.zrem(jobsPendingKey(user.sub), jobId);
  return reply.send({ ok: true });
});

app.get('/v1/jobs/recent', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const user = req.user as ApiJwtPayload;
  const q = z.object({
    since: z.coerce.number().optional().default(0),
    limit: z.coerce.number().optional().default(50)
  }).parse(req.query);

  const sinceMs = q.since;
  const limit = Math.min(Math.max(q.limit, 1), 200);
  const minExclusive = `(${sinceMs}`;
  const ids = await redis.zrangebyscore(jobsRecentKey(user.sub), minExclusive, '+inf', 'LIMIT', 0, limit);

  const changes = await fetchChangesForJobIds(user.sub, ids, sinceMs, limit);
  const resp: RecentResponse = { changes };
  return reply.send(resp);
});

app.get('/v1/jobs/pending/longpoll', { preHandler: requireAuth(app) }, async (req: any, reply) => {
  const user = req.user as ApiJwtPayload;
  const q = z.object({
    timeout: z.coerce.number().optional().default(20),
    since: z.coerce.number().optional().default(0),
    limit: z.coerce.number().optional().default(50)
  }).parse(req.query);

  const timeoutSeconds = Math.min(Math.max(q.timeout, 1), 30);
  const sinceMs = q.since;
  const limit = Math.min(Math.max(q.limit, 1), 200);

  // Fast reconciliation (covers missed pub/sub): check pending+recent indexes.
  const immediate = await getIndexChanges(user.sub, sinceMs, limit);
  if (immediate.length > 0) {
    const resp: LongpollResponse = { changes: immediate, hasPending: true };
    return reply.send(resp);
  }

  const pendingCount = await redis.zcard(jobsPendingKey(user.sub));
  if (pendingCount === 0) {
    const resp: LongpollResponse = { changes: [], hasPending: false };
    return reply.send(resp);
  }

  const changes = await new Promise<JobChange[]>((resolve, reject) => {
    let timer: NodeJS.Timeout | undefined;
    let cleanedUp = false;

    const waiter: any = {
      userId: user.sub,
      sinceMs,
      limit,
      resolve: (c: JobChange[]) => {
        waiter.cleanup();
        resolve(c);
      },
      reject: (err: unknown) => {
        waiter.cleanup();
        reject(err);
      },
      cleanup: () => {
        if (cleanedUp) return;
        cleanedUp = true;
        if (timer) clearTimeout(timer);
        broker.removeWaiter(waiter);
      }
    };

    timer = setTimeout(() => {
      waiter.cleanup();
      resolve([]);
    }, timeoutSeconds * 1000);

    broker.registerWaiter(waiter);

    // Explicit disconnect cleanup to prevent waiter leaks.
    req.raw.on('close', () => {
      waiter.cleanup();
    });
  });

  const pendingCountAfter = await redis.zcard(jobsPendingKey(user.sub));
  const resp: LongpollResponse = { changes, hasPending: pendingCountAfter > 0 };
  return reply.send(resp);
});

await app.listen({ port: env.PORT, host: '0.0.0.0' });
