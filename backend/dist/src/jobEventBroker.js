export class JobEventBroker {
    subscriber;
    fetchChangesForJobIds;
    flushDelayMs;
    waitersByUser = new Map();
    buffersByUser = new Map();
    constructor(subscriber, fetchChangesForJobIds, flushDelayMs = 25) {
        this.subscriber = subscriber;
        this.fetchChangesForJobIds = fetchChangesForJobIds;
        this.flushDelayMs = flushDelayMs;
    }
    async start() {
        await this.subscriber.psubscribe('user:*:job-events');
        this.subscriber.on('pmessage', (_pattern, channel, message) => {
            const userId = this.parseUserIdFromChannel(channel);
            if (!userId)
                return;
            const jobId = this.parseJobIdFromMessage(message);
            if (!jobId)
                return;
            this.bufferJobId(userId, jobId);
        });
    }
    registerWaiter(waiter) {
        let set = this.waitersByUser.get(waiter.userId);
        if (!set) {
            set = new Set();
            this.waitersByUser.set(waiter.userId, set);
        }
        set.add(waiter);
    }
    bufferJobId(userId, jobId) {
        let buf = this.buffersByUser.get(userId);
        if (!buf) {
            buf = { jobIds: new Set() };
            this.buffersByUser.set(userId, buf);
        }
        buf.jobIds.add(jobId);
        if (buf.flushTimer)
            return;
        buf.flushTimer = setTimeout(() => {
            buf.flushTimer = undefined;
            void this.flushUser(userId).catch(() => {
                // ignore
            });
        }, this.flushDelayMs);
    }
    async flushUser(userId) {
        const buf = this.buffersByUser.get(userId);
        if (!buf || buf.jobIds.size === 0)
            return;
        const jobIds = Array.from(buf.jobIds);
        buf.jobIds.clear();
        const waiters = this.waitersByUser.get(userId);
        if (!waiters || waiters.size === 0)
            return;
        // Resolve all waiters, but respect each waiter's sinceMs/limit.
        for (const waiter of Array.from(waiters)) {
            try {
                const changes = await this.fetchChangesForJobIds(userId, jobIds, waiter.sinceMs, waiter.limit);
                waiter.cleanup();
                waiter.resolve(changes);
            }
            catch (err) {
                waiter.cleanup();
                waiter.reject(err);
            }
        }
    }
    parseUserIdFromChannel(channel) {
        // channel: user:{userId}:job-events
        const m = /^user:([^:]+):job-events$/.exec(channel);
        return m?.[1] ?? null;
    }
    parseJobIdFromMessage(message) {
        try {
            const parsed = JSON.parse(message);
            return typeof parsed?.jobId === 'string' ? parsed.jobId : null;
        }
        catch {
            return null;
        }
    }
    removeWaiter(waiter) {
        const set = this.waitersByUser.get(waiter.userId);
        if (!set)
            return;
        set.delete(waiter);
        if (set.size === 0)
            this.waitersByUser.delete(waiter.userId);
    }
}
export function createWaiterCleanup(broker, waiter) {
    return () => broker.removeWaiter(waiter);
}
