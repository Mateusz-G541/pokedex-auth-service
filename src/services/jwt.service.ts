import jwt, { SignOptions, Secret } from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { logger } from '../utils/logger';
import { createError } from '../middleware/error.middleware';

export interface JwtPayload {
  userId: number;
  email: string;
  iat?: number;
  exp?: number;
}

class JwtService {
  private privateKey!: string;
  private publicKey!: string;

  constructor() {
    this.loadKeys();
  }

  private loadKeys(): void {
    try {
      const privateKeyPath = process.env.JWT_PRIVATE_KEY_PATH || './keys/private.pem';
      const publicKeyPath = process.env.JWT_PUBLIC_KEY_PATH || './keys/public.pem';

      this.privateKey = fs.readFileSync(path.resolve(privateKeyPath), 'utf8');
      this.publicKey = fs.readFileSync(path.resolve(publicKeyPath), 'utf8');

      logger.info('JWT keys loaded successfully');
    } catch (error) {
      logger.error('Failed to load JWT keys', { error: (error as Error).message });
      throw createError('JWT keys not found. Please generate RSA keys first.', 500);
    }
  }

  generateToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
    try {
      const expiresInEnv = process.env.JWT_EXPIRES_IN;
      const expiresIn: SignOptions['expiresIn'] =
        expiresInEnv && /^\d+$/.test(expiresInEnv)
          ? Number(expiresInEnv)
          : ((expiresInEnv || '24h') as unknown as SignOptions['expiresIn']);

      const options: SignOptions = {
        algorithm: 'RS256',
        expiresIn,
        issuer: 'pokedex-auth-service',
        audience: 'pokedex-app'
      };

      return jwt.sign(payload as object, this.privateKey as Secret, options);
    } catch (error) {
      logger.error('Failed to generate JWT token', { error: (error as Error).message });
      throw createError('Failed to generate authentication token', 500);
    }
  }

  verifyToken(token: string): JwtPayload {
    try {
      const decoded = jwt.verify(token, this.publicKey as Secret, {
        algorithms: ['RS256'],
        issuer: 'pokedex-auth-service',
        audience: 'pokedex-app'
      }) as JwtPayload;

      return decoded;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw createError('Token has expired', 401);
      } else if (error instanceof jwt.JsonWebTokenError) {
        throw createError('Invalid token', 401);
      } else {
        logger.error('Token verification failed', { error: (error as Error).message });
        throw createError('Token verification failed', 401);
      }
    }
  }

  getPublicKey(): string {
    return this.publicKey;
  }

  decodeToken(token: string): JwtPayload | null {
    try {
      return jwt.decode(token) as JwtPayload;
    } catch (error) {
      logger.error('Failed to decode token', { error: (error as Error).message });
      return null;
    }
  }
}

export const jwtService = new JwtService();
