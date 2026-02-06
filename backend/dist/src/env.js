import { z } from 'zod';
const EnvSchema = z.object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().default(3001),
    BASE_URL: z.string().url().default('http://localhost:3001'),
    REDIS_URL: z.string().default('redis://127.0.0.1:6379'),
    API_JWT_SECRET: z.string().min(32),
    GEMINI_API_KEY: z.string().min(1),
    GEMINI_MODEL: z.string().default('gemini-3-flash-preview'),
    GEMINI_TIMEOUT_MS: z.coerce.number().default(10 * 60 * 1000),
    APPLE_AUDIENCE: z.string().min(1),
    TARUKINGU: z.string().min(1),
    ALLOW_DEV_BYPASS: z.coerce.boolean().default(false),
    DEV_BYPASS_TOKEN: z.string().optional()
});
export const env = EnvSchema.parse(process.env);
