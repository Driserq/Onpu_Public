import { createRemoteJWKSet, jwtVerify } from 'jose';
import { env } from './env.js';
const JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
export async function verifyAppleIdentityToken(identityToken) {
    const { payload } = await jwtVerify(identityToken, JWKS, {
        issuer: 'https://appleid.apple.com',
        audience: env.APPLE_AUDIENCE
    });
    const sub = payload.sub;
    if (!sub || typeof sub !== 'string') {
        throw new Error('Missing sub in Apple token');
    }
    const aud = payload.aud;
    const nonce = payload.nonce;
    return { sub, aud, nonce };
}
