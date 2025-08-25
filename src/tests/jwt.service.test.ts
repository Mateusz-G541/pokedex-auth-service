/// <reference types="vitest" />
import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock fs to bypass reading real key files
vi.mock('fs', () => ({
  default: {
    readFileSync: vi.fn(() => 'TEST_KEY')
  },
  readFileSync: vi.fn(() => 'TEST_KEY')
}));

// Create realistic jwt mock that supports instanceof checks used in the service
class MockTokenExpiredError extends Error {}
class MockJsonWebTokenError extends Error {}

const signSpy = vi.fn((_payload: object) => 'mock.token.value');
const verifySpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));
const decodeSpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));

vi.mock('jsonwebtoken', () => ({
  default: {
    sign: signSpy,
    verify: verifySpy,
    decode: decodeSpy,
    TokenExpiredError: MockTokenExpiredError,
    JsonWebTokenError: MockJsonWebTokenError
  },
  sign: signSpy,
  verify: verifySpy,
  decode: decodeSpy,
  TokenExpiredError: MockTokenExpiredError,
  JsonWebTokenError: MockJsonWebTokenError
}));

import { jwtService } from '../services/jwt.service';

describe('JwtService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('generateToken returns a token string and uses RS256 with issuer/audience', () => {
    const token = jwtService.generateToken({ userId: 123, email: 'user@example.com' });

    expect(typeof token).toBe('string');
    expect(token).toBe('mock.token.value');

    expect(signSpy).toHaveBeenCalledTimes(1);
    const args = signSpy.mock.calls[0];
    // args: [payload, privateKey, options]
    expect(args[0]).toMatchObject({ userId: 123, email: 'user@example.com' });
    expect(args[2]).toMatchObject({
      algorithm: 'RS256',
      issuer: 'pokedex-auth-service',
      audience: 'pokedex-app'
    });
  });

  it('verifyToken returns decoded payload on success', () => {
    const payload = jwtService.verifyToken('mock.token');
    expect(payload).toMatchObject({ userId: 1, email: 'user@example.com' });
    expect(verifySpy).toHaveBeenCalledWith('mock.token', expect.anything(), expect.objectContaining({
      algorithms: ['RS256']
    }));
  });

  it('verifyToken maps TokenExpiredError to 401 with message', () => {
    verifySpy.mockImplementationOnce(() => { throw new MockTokenExpiredError('expired'); });
    expect(() => jwtService.verifyToken('expired.token')).toThrowError(/Token has expired/);
  });

  it('verifyToken maps JsonWebTokenError to 401 invalid token', () => {
    verifySpy.mockImplementationOnce(() => { throw new MockJsonWebTokenError('invalid'); });
    expect(() => jwtService.verifyToken('invalid.token')).toThrowError(/Invalid token/);
  });

  it('decodeToken returns payload without throwing', () => {
    const payload = jwtService.decodeToken('mock.token');
    expect(payload).toMatchObject({ userId: 1, email: 'user@example.com' });
    expect(decodeSpy).toHaveBeenCalled();
  });
});
