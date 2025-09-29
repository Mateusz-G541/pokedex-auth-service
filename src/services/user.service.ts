import { PrismaClient, User, Role } from '@prisma/client';
import bcrypt from 'bcrypt';
import { AppError } from '../utils/errors';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export interface CreateUserDto {
  email: string;
  password: string;
  role?: Role;
}

export interface UpdateUserDto {
  email?: string;
  password?: string;
  role?: Role;
  isActive?: boolean;
}

export interface UserResponse {
  id: number;
  email: string;
  role: Role;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

class UserService {
  // Get all users (admin only)
  async getAllUsers(page: number = 1, limit: number = 10): Promise<{
    users: UserResponse[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    try {
      const skip = (page - 1) * limit;
      
      const [users, total] = await Promise.all([
        prisma.user.findMany({
          skip,
          take: limit,
          select: {
            id: true,
            email: true,
            role: true,
            isActive: true,
            createdAt: true,
            updatedAt: true,
          },
          orderBy: {
            createdAt: 'desc',
          },
        }),
        prisma.user.count(),
      ]);

      return {
        users,
        total,
        page,
        totalPages: Math.ceil(total / limit),
      };
    } catch (error) {
      logger.error('Error fetching users:', error);
      throw new AppError('Failed to fetch users', 500);
    }
  }

  // Get user by ID
  async getUserById(userId: number): Promise<UserResponse | null> {
    try {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          email: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      return user;
    } catch (error) {
      logger.error('Error fetching user by ID:', error);
      throw new AppError('Failed to fetch user', 500);
    }
  }

  // Create new user (admin only)
  async createUser(data: CreateUserDto): Promise<UserResponse> {
    try {
      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email: data.email },
      });

      if (existingUser) {
        throw new AppError('User with this email already exists', 409);
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(
        data.password,
        parseInt(process.env.BCRYPT_ROUNDS || '12')
      );

      // Create user
      const user = await prisma.user.create({
        data: {
          email: data.email,
          password: hashedPassword,
          role: data.role || Role.USER,
        },
        select: {
          id: true,
          email: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      logger.info(`User created: ${user.email} with role ${user.role}`);
      return user;
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Error creating user:', error);
      throw new AppError('Failed to create user', 500);
    }
  }

  // Update user
  async updateUser(
    userId: number,
    data: UpdateUserDto,
    isOwnProfile: boolean = false
  ): Promise<UserResponse> {
    try {
      // Check if user exists
      const existingUser = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!existingUser) {
        throw new AppError('User not found', 404);
      }

      // Prepare update data
      const updateData: any = {};

      // Users can only update their own email and password
      if (isOwnProfile) {
        if (data.email) updateData.email = data.email;
        if (data.password) {
          updateData.password = await bcrypt.hash(
            data.password,
            parseInt(process.env.BCRYPT_ROUNDS || '12')
          );
        }
      } else {
        // Admins can update everything
        if (data.email) updateData.email = data.email;
        if (data.password) {
          updateData.password = await bcrypt.hash(
            data.password,
            parseInt(process.env.BCRYPT_ROUNDS || '12')
          );
        }
        if (data.role !== undefined) updateData.role = data.role;
        if (data.isActive !== undefined) updateData.isActive = data.isActive;
      }

      // Check if email is being changed and if it's already taken
      if (data.email && data.email !== existingUser.email) {
        const emailExists = await prisma.user.findUnique({
          where: { email: data.email },
        });
        if (emailExists) {
          throw new AppError('Email already in use', 409);
        }
      }

      // Update user
      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: updateData,
        select: {
          id: true,
          email: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      logger.info(`User updated: ${updatedUser.email}`);
      return updatedUser;
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Error updating user:', error);
      throw new AppError('Failed to update user', 500);
    }
  }

  // Delete user (admin only)
  async deleteUser(userId: number): Promise<void> {
    try {
      // Check if user exists
      const user = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new AppError('User not found', 404);
      }

      // Prevent deleting the last admin
      if (user.role === Role.ADMINISTRATOR) {
        const adminCount = await prisma.user.count({
          where: { role: Role.ADMINISTRATOR },
        });
        if (adminCount <= 1) {
          throw new AppError('Cannot delete the last administrator', 400);
        }
      }

      await prisma.user.delete({
        where: { id: userId },
      });

      logger.info(`User deleted: ${user.email}`);
    } catch (error) {
      if (error instanceof AppError) throw error;
      logger.error('Error deleting user:', error);
      throw new AppError('Failed to delete user', 500);
    }
  }

  // Search users
  async searchUsers(
    query: string,
    role?: Role,
    isActive?: boolean
  ): Promise<UserResponse[]> {
    try {
      const where: any = {};

      if (query) {
        where.email = {
          contains: query,
        };
      }

      if (role) {
        where.role = role;
      }

      if (isActive !== undefined) {
        where.isActive = isActive;
      }

      const users = await prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          role: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
        take: 50,
        orderBy: {
          email: 'asc',
        },
      });

      return users;
    } catch (error) {
      logger.error('Error searching users:', error);
      throw new AppError('Failed to search users', 500);
    }
  }
}

export const userService = new UserService();
