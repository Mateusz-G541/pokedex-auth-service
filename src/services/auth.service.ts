import bcrypt from 'bcrypt';
import { PrismaClient } from '@prisma/client';
import { jwtService, JwtPayload } from './jwt.service';
import { createError } from '../middleware/error.middleware';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export interface RegisterData {
  email: string;
  password: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: number;
    email: string;
    role?: string;
    createdAt: Date;
    updatedAt: Date;
  };
}

export interface UserProfile {
  id: number;
  email: string;
  role?: string;
  createdAt: Date;
  updatedAt: Date;
}

class AuthService {
  private readonly saltRounds: number;

  constructor() {
    this.saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12');
  }

  async register(data: RegisterData): Promise<AuthResponse> {
    const { email, password } = data;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      throw createError('User with this email already exists', 409);
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, this.saltRounds);

    try {
      // Create user
      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword
        }
      });

      // Generate JWT token (include role)
      const token = jwtService.generateToken({
        userId: user.id,
        email: user.email,
        role: (user as any).role || 'USER'
      });

      logger.info('User registered successfully', { userId: user.id, email: user.email });

      return {
        token,
        user: {
          id: user.id,
          email: user.email,
          role: (user as any).role || 'USER',
          createdAt: user.createdAt,
          updatedAt: user.updatedAt
        }
      };
    } catch (error) {
      logger.error('Failed to register user', { error: (error as Error).message, email });
      throw createError('Failed to create user account', 500);
    }
  }

  async login(data: LoginData): Promise<AuthResponse> {
    const { email, password } = data;

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      throw createError('Invalid email or password', 401);
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw createError('Invalid email or password', 401);
    }

    try {
      // Generate JWT token (include role)
      const token = jwtService.generateToken({
        userId: user.id,
        email: user.email,
        role: (user as any).role || 'USER'
      });

      logger.info('User logged in successfully', { userId: user.id, email: user.email });

      return {
        token,
        user: {
          id: user.id,
          email: user.email,
          role: (user as any).role || 'USER',
          createdAt: user.createdAt,
          updatedAt: user.updatedAt
        }
      };
    } catch (error) {
      logger.error('Failed to generate login token', { error: (error as Error).message, email });
      throw createError('Login failed', 500);
    }
  }

  async getUserProfile(userId: number): Promise<UserProfile> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });

    if (!user) {
      throw createError('User not found', 404);
    }

    return user;
  }

  async verifyToken(token: string): Promise<JwtPayload> {
    return jwtService.verifyToken(token);
  }

  getPublicKey(): string {
    return jwtService.getPublicKey();
  }
}

export const authService = new AuthService();
