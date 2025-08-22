import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { validate, registerSchema, loginSchema } from '../utils/validation';

const router = Router();

// Public routes
router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.get('/public-key', authController.getPublicKey);

// Protected routes
router.get('/me', authenticateToken, authController.getProfile);

export default router;
