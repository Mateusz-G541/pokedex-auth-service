import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/user.service';
import { Role } from '@prisma/client';
import { logger } from '../utils/logger';

export class UserController {
  // Get all users (admin only)
  async getAllUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;

      const result = await userService.getAllUsers(page, limit);

      res.status(200).json({
        success: true,
        message: 'Users retrieved successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  // Get user by ID
  async getUserById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = parseInt(req.params.id);
      
      // Check if user is accessing their own profile or is admin
      const isOwnProfile = req.user?.userId === userId;
      const isAdmin = req.user?.role === Role.ADMINISTRATOR;
      
      if (!isOwnProfile && !isAdmin) {
        res.status(403).json({
          success: false,
          error: 'Forbidden: You can only access your own profile',
        });
        return;
      }

      const user = await userService.getUserById(userId);

      if (!user) {
        res.status(404).json({
          success: false,
          error: 'User not found',
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: 'User retrieved successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  // Create new user (admin only)
  async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password, role } = req.body;

      const user = await userService.createUser({
        email,
        password,
        role: role || Role.USER,
      });

      res.status(201).json({
        success: true,
        message: 'User created successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  // Update user
  async updateUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = parseInt(req.params.id);
      const updateData = req.body;

      // Check if user is updating their own profile or is admin
      const isOwnProfile = req.user?.userId === userId;
      const isAdmin = req.user?.role === Role.ADMINISTRATOR;

      if (!isOwnProfile && !isAdmin) {
        res.status(403).json({
          success: false,
          error: 'Forbidden: You can only update your own profile',
        });
        return;
      }

      // If updating own profile, restrict what can be updated
      if (isOwnProfile && !isAdmin) {
        // Users can only update email and password
        delete updateData.role;
        delete updateData.isActive;
      }

      const user = await userService.updateUser(userId, updateData, isOwnProfile && !isAdmin);

      res.status(200).json({
        success: true,
        message: 'User updated successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  // Delete user (admin only)
  async deleteUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = parseInt(req.params.id);

      // Prevent self-deletion
      if (req.user?.userId === userId) {
        res.status(400).json({
          success: false,
          error: 'You cannot delete your own account',
        });
        return;
      }

      await userService.deleteUser(userId);

      res.status(200).json({
        success: true,
        message: 'User deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  // Search users (admin only)
  async searchUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { query, role, isActive } = req.query;

      const users = await userService.searchUsers(
        query as string,
        role as Role,
        isActive === 'true' ? true : isActive === 'false' ? false : undefined
      );

      res.status(200).json({
        success: true,
        message: 'Users search completed',
        data: users,
      });
    } catch (error) {
      next(error);
    }
  }

  // Update own profile
  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const { email, password, currentPassword } = req.body;

      // For password change, verify current password
      if (password && !currentPassword) {
        res.status(400).json({
          success: false,
          error: 'Current password is required to change password',
        });
        return;
      }

      // TODO: Verify current password before allowing password change

      const user = await userService.updateUser(
        userId,
        { email, password },
        true
      );

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
