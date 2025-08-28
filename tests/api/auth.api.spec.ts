import { test, expect } from '@playwright/test';
import { register, login, me, newApiContext } from './helpers/auth';
import { uniqueEmail, TestPasswords } from './fixtures/test-data';

// All routes here assume app mounted under /auth in src/index.ts
// Health check is available at /health and configured in playwright.config.ts

test.describe('Auth API', () => {
  let api: Awaited<ReturnType<typeof newApiContext>>;

  test.beforeAll(async ({ baseURL }) => {
    api = await newApiContext(baseURL);
  });

  test('login happy path for an existing user', async () => {
    const email = uniqueEmail('login');
    const password = TestPasswords.valid;

    // Register user
    const { res: regRes } = await register(api, email, password);
    expect(regRes.status(), await regRes.text()).toBe(201);

    // Login user
    const { res: loginRes, json: loginBody } = await login(api, email, password);
    expect(loginRes.status(), await loginRes.text()).toBe(200);
    const token = loginBody?.data?.token as string;
    expect(token).toBeTruthy();

    // Access profile
    const { res: meRes, json: meBody } = await me(api, token);
    expect(meRes.status(), await meRes.text()).toBe(200);
    expect(meBody?.data?.email).toBe(email);
  });

  test('multiple users have isolated tokens and profiles', async () => {
    const emailA = uniqueEmail('userA');
    const emailB = uniqueEmail('userB');
    const password = TestPasswords.valid;

    const a = await register(api, emailA, password);
    const b = await register(api, emailB, password);
    expect(a.res.status()).toBe(201);
    expect(b.res.status()).toBe(201);

    const loginA = await login(api, emailA, password);
    const loginB = await login(api, emailB, password);
    expect(loginA.res.status()).toBe(200);
    expect(loginB.res.status()).toBe(200);

    const tokenA = loginA.json?.data?.token as string;
    const tokenB = loginB.json?.data?.token as string;
    expect(tokenA).toBeTruthy();
    expect(tokenB).toBeTruthy();
    expect(tokenA).not.toBe(tokenB);

    const meA = await me(api, tokenA);
    const meB = await me(api, tokenB);
    expect(meA.res.status()).toBe(200);
    expect(meB.res.status()).toBe(200);
    expect(meA.json?.data?.email).toBe(emailA);
    expect(meB.json?.data?.email).toBe(emailB);
    expect(meA.json?.data?.email).not.toBe(meB.json?.data?.email);
  });

  test.afterAll(async () => { await api.dispose(); });

  test('register -> login -> me happy path', async () => {
    const email = uniqueEmail('reg');
    const password = TestPasswords.valid;

    const { res: regRes, json: regBody } = await register(api, email, password);
    expect(regRes.status(), await regRes.text()).toBe(201);
    expect(regBody?.success).toBe(true);
    expect(regBody?.data?.token).toBeTruthy();
    expect(regBody?.data?.user?.email).toBe(email);
    expect(regBody?.data?.user?.id).toBeGreaterThan(0);
    // Ensure password never leaks back
    expect(JSON.stringify(regBody)).not.toContain(password);

    const { res: loginRes, json: loginBody } = await login(api, email, password);
    expect(loginRes.status(), await loginRes.text()).toBe(200);
    const token = loginBody?.data?.token as string;
    expect(token).toBeTruthy();

    const { res: meRes, json: meBody } = await me(api, token);
    expect(meRes.status(), await meRes.text()).toBe(200);
    expect(meBody?.data?.email).toBe(email);
    expect(meBody?.data?.id).toBeGreaterThan(0);
    expect(meBody?.data?.createdAt).toBeTruthy();
  });

  test('register duplicate email -> 409', async () => {
    const email = uniqueEmail('dup');
    const password = TestPasswords.valid;

    const first = await register(api, email, password);
    expect(first.res.status(), await first.res.text()).toBe(201);

    const second = await register(api, email, password);
    expect(second.res.status()).toBe(409);
    const body = await second.res.json();
    expect(body.success).toBe(false);
    expect(String(body.error || body.message || '')).toMatch(/already exists/i);
  });

  test('login invalid credentials -> 401', async () => {
    const email = uniqueEmail('bad');
    const password = TestPasswords.valid;
    const { res } = await login(api, email, password);
    expect(res.status(), await res.text()).toBe(401);
    const body = await res.json();
    expect(body.success).toBe(false);
  });

  test('public key endpoint returns key meta', async ({ request, baseURL }) => {
    const res = await request.get(`${baseURL}/auth/public-key`);
    expect(res.ok()).toBeTruthy();
    const body = await res.json();
    expect(body.data.publicKey).toBeTruthy();
    expect(body.data.algorithm).toBe('RS256');
    expect(body.data.issuer).toBe('pokedex-auth-service');
  });

  test('register response is sanitized (no password) and contains user id', async () => {
    const email = uniqueEmail('sanitize');
    const password = TestPasswords.valid;
    const { res, json } = await register(api, email, password);
    expect(res.status(), await res.text()).toBe(201);
    expect(json?.data?.user?.email).toBe(email);
    expect(json?.data?.user?.id).toBeGreaterThan(0);
    // Ensure no password leaked anywhere in payload
    expect(JSON.stringify(json)).not.toContain(password);
    // User should expose a predictable set of fields
    const userKeys = Object.keys(json?.data?.user ?? {});
    expect(userKeys).toEqual(expect.arrayContaining(['id', 'email', 'createdAt', 'updatedAt']));
  });

  test('public key is PEM formatted', async ({ request, baseURL }) => {
    const res = await request.get(`${baseURL}/auth/public-key`);
    expect(res.ok()).toBeTruthy();
    const body = await res.json();
    const pem = body.data.publicKey as string;
    expect(pem).toMatch(/-----BEGIN PUBLIC KEY-----/);
    expect(pem.trim().endsWith('-----END PUBLIC KEY-----')).toBe(true);
  });

  // Validation tests (error 400 from Joi schemas in src/utils/validation.ts)
  test('register validation: missing email and password -> 400 with combined messages', async () => {
    const res = await api.post('/auth/register', { data: {} });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Email is required/);
    expect(String(body.error)).toMatch(/Password is required/);
  });

  test('register validation: invalid email format -> 400', async () => {
    const res = await api.post('/auth/register', { data: { email: 'not-an-email', password: 'P@ssw0rd123!' } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Please provide a valid email address/);
  });

  test('register validation: weak password (missing special char) -> 400', async () => {
    const res = await api.post('/auth/register', { data: { email: uniqueEmail('weak'), password: 'Passw0rd' } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character/);
  });

  test('register validation: too short password -> 400', async () => {
    const res = await api.post('/auth/register', { data: { email: uniqueEmail('short'), password: 'P@1a' } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Password must be at least 8 characters long/);
  });

  test('login validation: missing email -> 400', async () => {
    const res = await api.post('/auth/login', { data: { password: 'whatever' } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Email is required/);
  });

  test('login validation: missing password -> 400', async () => {
    const res = await api.post('/auth/login', { data: { email: uniqueEmail('no-pass') } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Password is required/);
  });

  test('login validation: invalid email format -> 400', async () => {
    const res = await api.post('/auth/login', { data: { email: 'bad', password: 'something' } });
    expect(res.status(), await res.text()).toBe(400);
    const body = await res.json();
    expect(body.success).toBe(false);
    expect(String(body.error)).toMatch(/Please provide a valid email address/);
  });
});
