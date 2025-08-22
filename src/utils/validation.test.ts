/// <reference types="vitest" />
import { describe, it, expect } from 'vitest';
import { registerSchema, loginSchema } from './validation';

describe('validation schemas', () => {
  it('registerSchema accepts a valid email and strong password', () => {
    const { error } = registerSchema.validate({
      email: 'user@example.com',
      password: 'Aa123456!'
    });

    expect(error).toBeUndefined();
  });

  it('registerSchema rejects weak password (missing special character)', () => {
    const { error } = registerSchema.validate({
      email: 'user@example.com',
      password: 'Aa123456'
    });

    expect(error).toBeDefined();
    expect(error?.details[0].message).toContain(
      'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
    );
  });

  it('loginSchema requires both email and password', () => {
    const { error } = loginSchema.validate({});
    expect(error).toBeDefined();

    const messages = error!.details.map(d => d.message).join(' | ');
    expect(messages).toContain('Email is required');
    expect(messages).toContain('Password is required');
  });
});
