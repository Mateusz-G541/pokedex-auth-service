import Joi from 'joi';
import { Role } from '@prisma/client';

export const userValidation = {
  createUser: {
    body: Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string()
        .min(8)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
        .required()
        .messages({
          'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
        }),
      role: Joi.string().valid(...Object.values(Role)).optional(),
    }),
  },

  updateUser: {
    body: Joi.object({
      email: Joi.string().email().optional(),
      password: Joi.string()
        .min(8)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
        .optional()
        .messages({
          'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
        }),
      role: Joi.string().valid(...Object.values(Role)).optional(),
      isActive: Joi.boolean().optional(),
    }),
  },

  updateProfile: {
    body: Joi.object({
      email: Joi.string().email().optional(),
      password: Joi.string()
        .min(8)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
        .optional()
        .messages({
          'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character',
        }),
      currentPassword: Joi.string().when('password', {
        is: Joi.exist(),
        then: Joi.required(),
        otherwise: Joi.optional(),
      }),
    }),
  },
};
