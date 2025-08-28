import { defineConfig, devices } from '@playwright/test';

const TEST_PORT = process.env.PLAYWRIGHT_PORT || '4010';
const HOST = process.env.HOST || '127.0.0.1';
const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || `http://${HOST}:${TEST_PORT}`;
const DEFAULT_DB_URL = 'mysql://auth_user:auth_password@127.0.0.1:3307/auth_db';

export default defineConfig({
  testDir: 'tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: BASE_URL,
    trace: 'retain-on-failure',
  },
  webServer: process.env.PLAYWRIGHT_NO_WEBSERVER
    ? undefined
    : {
        command: 'npm run dev:test',
        url: `${BASE_URL}/health`,
        reuseExistingServer: false,
        timeout: 60_000,
        env: {
          PORT: TEST_PORT,
          HOST,
          DATABASE_URL: process.env.DATABASE_URL || DEFAULT_DB_URL,
          JWT_PRIVATE_KEY_PATH: process.env.JWT_PRIVATE_KEY_PATH || './keys/private.pem',
          JWT_PUBLIC_KEY_PATH: process.env.JWT_PUBLIC_KEY_PATH || './keys/public.pem',
          JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '24h',
          BCRYPT_ROUNDS: process.env.BCRYPT_ROUNDS || '12',
          CORS_ORIGIN: process.env.CORS_ORIGIN || 'http://localhost:3000,http://localhost:5173',
          RATE_LIMIT_WINDOW_MS: process.env.RATE_LIMIT_WINDOW_MS || '900000',
          RATE_LIMIT_MAX_REQUESTS: process.env.RATE_LIMIT_MAX_REQUESTS || '100',
          NODE_ENV: process.env.NODE_ENV || 'test',
        },
      },
  projects: [
    { name: 'API', use: { ...devices['Desktop Chrome'] } },
  ],
});
