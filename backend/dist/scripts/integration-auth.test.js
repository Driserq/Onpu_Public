import { spawn } from 'node:child_process';
const PORT = Number(process.env.PORT ?? 3999);
const BASE_URL = `http://127.0.0.1:${PORT}`;
async function sleep(ms) {
    await new Promise((r) => setTimeout(r, ms));
}
async function waitForHealthz(timeoutMs) {
    const started = Date.now();
    while (Date.now() - started < timeoutMs) {
        try {
            const r = await fetch(`${BASE_URL}/healthz`);
            if (r.ok)
                return;
        }
        catch {
            // ignore
        }
        await sleep(100);
    }
    throw new Error('Timed out waiting for /healthz');
}
async function main() {
    const tsxPath = new URL('../node_modules/.bin/tsx', import.meta.url).pathname;
    const child = spawn(tsxPath, ['src/server.ts'], {
        stdio: 'inherit',
        env: {
            ...process.env,
            NODE_ENV: 'test',
            APPLE_TEST_MODE: 'true',
            PORT: String(PORT),
            BASE_URL,
            REDIS_URL: process.env.REDIS_URL ?? 'redis://127.0.0.1:6379',
            API_JWT_SECRET: process.env.API_JWT_SECRET ?? 'test-secret-32+chars--------------------',
            GEMINI_API_KEY: process.env.GEMINI_API_KEY ?? 'test',
            APPLE_AUDIENCE: process.env.APPLE_AUDIENCE ?? 'me.kyzcwezsabuk.Uta',
            TARUKINGU: process.env.TARUKINGU ?? 'tarukingu'
        }
    });
    try {
        await waitForHealthz(10_000);
        const nonce = 'nonce-for-test';
        const authResp = await fetch(`${BASE_URL}/v1/auth/apple`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', tarukingu: 'tarukingu' },
            body: JSON.stringify({ identityToken: 'test', nonce })
        });
        if (authResp.status !== 200) {
            throw new Error(`Expected 200 from /v1/auth/apple, got ${authResp.status}: ${await authResp.text()}`);
        }
        const { accessToken } = (await authResp.json());
        if (!accessToken)
            throw new Error('Missing accessToken in response');
        const meResp = await fetch(`${BASE_URL}/v1/auth/me`, {
            headers: { Authorization: `Bearer ${accessToken}`, tarukingu: 'tarukingu' }
        });
        if (meResp.status !== 200) {
            throw new Error(`Expected 200 from /v1/auth/me, got ${meResp.status}: ${await meResp.text()}`);
        }
        console.log('✅ integration auth test passed');
    }
    finally {
        child.kill('SIGTERM');
    }
}
await main();
