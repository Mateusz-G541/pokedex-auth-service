// Token validation middleware for pokemon-api-service
// Copy this file to your pokemon-api-service/src/middleware/ directory

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import axios from 'axios';

interface JwtPayload {
  userId: number;
  email: string;
  iat?: number;
  exp?: number;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

class TokenValidator {
  private publicKey: string | null = null;
  private keyFetchTime: number = 0;
  private readonly KEY_CACHE_DURATION = 3600000; // 1 hour in milliseconds

  private async fetchPublicKey(): Promise<string> {
    const authServiceUrl = process.env.AUTH_SERVICE_URL || 'http://localhost:4000';
    
    try {
      const response = await axios.get(`${authServiceUrl}/auth/public-key`, {
        timeout: 5000
      });
      
      if (response.data.success && response.data.data.publicKey) {
        this.publicKey = response.data.data.publicKey;
        this.keyFetchTime = Date.now();
        return this.publicKey;
      } else {
        throw new Error('Invalid response format from auth service');
      }
    } catch (error) {
      console.error('Failed to fetch public key from auth service:', error);
      throw new Error('Unable to fetch public key for token validation');
    }
  }

  private async getPublicKey(): Promise<string> {
    // Check if we have a cached key that's still valid
    if (this.publicKey && (Date.now() - this.keyFetchTime) < this.KEY_CACHE_DURATION) {
      return this.publicKey;
    }

    // Fetch new key
    return await this.fetchPublicKey();
  }

  async validateToken(token: string): Promise<JwtPayload> {
    try {
      const publicKey = await this.getPublicKey();
      
      const decoded = jwt.verify(token, publicKey, {
        algorithms: ['RS256'],
        issuer: 'pokedex-auth-service',
        audience: 'pokedex-app'
      }) as JwtPayload;

      return decoded;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new Error('Token has expired');
      } else if (error instanceof jwt.JsonWebTokenError) {
        throw new Error('Invalid token');
      } else {
        throw new Error('Token validation failed');
      }
    }
  }
}

const tokenValidator = new TokenValidator();

// Middleware function
export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({
        error: 'Authorization header is required'
      });
    }

    const token = authHeader.split(' ')[1]; // Bearer <token>
    
    if (!token) {
      return res.status(401).json({
        error: 'Bearer token is required'
      });
    }

    // Validate token
    const userPayload = await tokenValidator.validateToken(token);
    
    // Attach user to request object
    req.user = userPayload;
    
    next();
  } catch (error) {
    return res.status(401).json({
      error: (error as Error).message
    });
  }
};

// Optional middleware - only validates token if present
export const optionalAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader) {
      const token = authHeader.split(' ')[1];
      
      if (token) {
        try {
          const userPayload = await tokenValidator.validateToken(token);
          req.user = userPayload;
        } catch (error) {
          // Ignore token validation errors for optional auth
          console.warn('Optional auth token validation failed:', (error as Error).message);
        }
      }
    }
    
    next();
  } catch (error) {
    // For optional auth, we don't fail the request
    next();
  }
};
