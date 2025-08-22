import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { logger } from '../utils/logger';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      
      const result = await authService.register({ email, password });
      
      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      
      const result = await authService.login({ email, password });
      
      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'User not authenticated'
        });
      }

      const userProfile = await authService.getUserProfile(req.user.userId);
      
      res.status(200).json({
        success: true,
        message: 'User profile retrieved successfully',
        data: userProfile
      });
    } catch (error) {
      next(error);
    }
  }

  async getPublicKey(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const publicKey = authService.getPublicKey();
      
      res.status(200).json({
        success: true,
        message: 'Public key retrieved successfully',
        data: {
          publicKey,
          algorithm: 'RS256',
          issuer: 'pokedex-auth-service',
          audience: 'pokedex-app'
        }
      });
    } catch (error) {
      next(error);
    }
  }
}

export const authController = new AuthController();
