import type Redis from 'ioredis';

export type JobChange = {
  jobId: string;
  status: string;
  updatedAt: number;
  error?: string;
};

type Waiter = {
  userId: string;
  sinceMs: number;
  limit: number;
  resolve: (changes: JobChange[]) => void;
  reject: (err: unknown) => void;
  cleanup: () => void;
};

type UserBuffer = {
  jobIds: Set<string>;
  flushTimer?: NodeJS.Timeout;
};

export class JobEventBroker {
  private waitersByUser = new Map<string, Set<Waiter>>();
  private buffersByUser = new Map<string, UserBuffer>();

  constructor(
    private readonly subscriber: Redis,
    private readonly fetchChangesForJobIds: (userId: string, jobIds: string[], sinceMs: number, limit: number) => Promise<JobChange[]>,
    private readonly flushDelayMs: number = 25
  ) {}

  async start(): Promise<void> {
    await this.subscriber.psubscribe('user:*:job-events');
    this.subscriber.on('pmessage', (_pattern, channel, message) => {
      const userId = this.parseUserIdFromChannel(channel);
      if (!userId) return;
      const jobId = this.parseJobIdFromMessage(message);
      if (!jobId) return;
      this.bufferJobId(userId, jobId);
    });
  }

  registerWaiter(waiter: Waiter): void {
    let set = this.waitersByUser.get(waiter.userId);
    if (!set) {
      set = new Set();
      this.waitersByUser.set(waiter.userId, set);
    }
    set.add(waiter);
  }

  private bufferJobId(userId: string, jobId: string) {
    let buf = this.buffersByUser.get(userId);
    if (!buf) {
      buf = { jobIds: new Set() };
      this.buffersByUser.set(userId, buf);
    }
    buf.jobIds.add(jobId);
    if (buf.flushTimer) return;

    buf.flushTimer = setTimeout(() => {
      buf!.flushTimer = undefined;
      void this.flushUser(userId).catch(() => {
        // ignore
      });
    }, this.flushDelayMs);
  }

  private async flushUser(userId: string): Promise<void> {
    const buf = this.buffersByUser.get(userId);
    if (!buf || buf.jobIds.size === 0) return;

    const jobIds = Array.from(buf.jobIds);
    buf.jobIds.clear();

    const waiters = this.waitersByUser.get(userId);
    if (!waiters || waiters.size === 0) return;

    // Resolve all waiters, but respect each waiter's sinceMs/limit.
    for (const waiter of Array.from(waiters)) {
      try {
        const changes = await this.fetchChangesForJobIds(userId, jobIds, waiter.sinceMs, waiter.limit);
        waiter.cleanup();
        waiter.resolve(changes);
      } catch (err) {
        waiter.cleanup();
        waiter.reject(err);
      }
    }
  }

  private parseUserIdFromChannel(channel: string): string | null {
    // channel: user:{userId}:job-events
    const m = /^user:([^:]+):job-events$/.exec(channel);
    return m?.[1] ?? null;
  }

  private parseJobIdFromMessage(message: string): string | null {
    try {
      const parsed: any = JSON.parse(message);
      return typeof parsed?.jobId === 'string' ? parsed.jobId : null;
    } catch {
      return null;
    }
  }

  removeWaiter(waiter: Waiter): void {
    const set = this.waitersByUser.get(waiter.userId);
    if (!set) return;
    set.delete(waiter);
    if (set.size === 0) this.waitersByUser.delete(waiter.userId);
  }
}

export function createWaiterCleanup(broker: JobEventBroker, waiter: Waiter): () => void {
  return () => broker.removeWaiter(waiter);
}
