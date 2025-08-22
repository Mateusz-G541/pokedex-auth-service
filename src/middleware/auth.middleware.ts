import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { createError } from './error.middleware';
import { JwtPayload } from '../services/jwt.service';

// Extend Express Request interface to include user
declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      throw createError('Authorization header is required', 401);
    }

    const token = authHeader.split(' ')[1]; // Bearer <token>
    
    if (!token) {
      throw createError('Bearer token is required', 401);
    }

    // Verify token and get user payload
    const userPayload = await authService.verifyToken(token);
    
    // Attach user to request object
    req.user = userPayload;
    
    next();
  } catch (error) {
    next(error);
  }
};
