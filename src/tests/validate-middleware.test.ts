/// <reference types="vitest" />
import { describe, it, expect, vi } from 'vitest';
import { validate, loginSchema } from '../utils/validation';
import type { Request, Response, NextFunction } from 'express';

const makeReq = (body: unknown) => ({ body } as Request);
const makeRes = () => ({ } as unknown as Response);

describe('validate() middleware', () => {
  it('aggregates multiple Joi errors when both email and password are missing', () => {
    const middleware = validate(loginSchema);
    const req = makeReq({});
    const res = makeRes();
    const next = vi.fn() as unknown as NextFunction;

    try {
      middleware(req, res, next);
      throw new Error('Expected middleware to throw, but it did not');
    } catch (err: any) {
      expect(err).toBeDefined();
      expect(err.statusCode || err.status || 400).toBe(400);
      const message: string = String(err.message);
      expect(message).toContain('Email is required');
      expect(message).toContain('Password is required');
    }

    // next should not be called on validation error
    expect(next).not.toHaveBeenCalled();
  });

  it('calls next() when body is valid', () => {
    const middleware = validate(loginSchema);
    const req = makeReq({ email: 'user@example.com', password: 'StrongPass1!' });
    const res = makeRes();
    const next = vi.fn() as unknown as NextFunction;

    middleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
  });
});
