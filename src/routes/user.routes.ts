import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { requireAdmin } from '../middleware/rbac.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { userValidation } from '../validation/user.validation';

const router = Router();

// Public routes (none for user management)

// Protected routes - require authentication
router.use(authenticateToken);

// User's own profile
router.get('/profile', userController.updateProfile);
router.put('/profile', 
  validateRequest(userValidation.updateProfile),
  userController.updateProfile
);

// Admin-only routes
router.get('/', 
  requireAdmin,
  userController.getAllUsers
);

router.get('/search',
  requireAdmin,
  userController.searchUsers
);

router.post('/',
  requireAdmin,
  validateRequest(userValidation.createUser),
  userController.createUser
);

router.get('/:id',
  userController.getUserById
);

router.put('/:id',
  validateRequest(userValidation.updateUser),
  userController.updateUser
);

router.delete('/:id',
  requireAdmin,
  userController.deleteUser
);

export default router;
