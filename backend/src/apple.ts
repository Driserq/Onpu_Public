import { createRemoteJWKSet, jwtVerify } from 'jose';
import { env } from './env.js';

const JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));

export type VerifiedAppleToken = {
  sub: string;
  aud?: string | string[];
  nonce?: string;
};

export async function verifyAppleIdentityToken(identityToken: string): Promise<VerifiedAppleToken> {
  const { payload } = await jwtVerify(identityToken, JWKS, {
    issuer: 'https://appleid.apple.com',
    audience: env.APPLE_AUDIENCE
  });

  const sub = payload.sub;
  if (!sub || typeof sub !== 'string') {
    throw new Error('Missing sub in Apple token');
  }

  const aud = payload.aud as string | string[] | undefined;
  const nonce = (payload as any).nonce as string | undefined;
  return { sub, aud, nonce };
}
