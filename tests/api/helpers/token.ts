import fs from 'fs';
import path from 'path';
import jwt, { Secret, SignOptions } from 'jsonwebtoken';

const PRIV_PATH = process.env.JWT_PRIVATE_KEY_PATH || './keys/private.pem';
const privateKey: Secret = fs.readFileSync(path.resolve(PRIV_PATH), 'utf8');

const BASE_OPTIONS: SignOptions = {
  algorithm: 'RS256',
  issuer: 'pokedex-auth-service',
  audience: 'pokedex-app',
};

export function issueToken(payload: Record<string, unknown>, options: SignOptions = {}): string {
  return jwt.sign(payload, privateKey, { ...BASE_OPTIONS, ...options });
}

export function issueExpiredToken(userId: number, email: string): string {
  const exp = Math.floor(Date.now() / 1000) - 10; // expired 10s ago
  // Place exp inside payload to force expiration
  return issueToken({ userId, email, exp }, {});
}
