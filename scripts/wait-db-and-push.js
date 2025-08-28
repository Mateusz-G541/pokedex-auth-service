#!/usr/bin/env node
const { execSync } = require('child_process');

const MAX_ATTEMPTS = parseInt(process.env.DB_WAIT_ATTEMPTS || '30', 10);
const SLEEP_MS = parseInt(process.env.DB_WAIT_SLEEP_MS || '1000', 10);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

(async () => {
  const dbUrl = process.env.DATABASE_URL || '<not set>';
  console.log(`[db-wait] Ensuring schema is applied via prisma db push`);
  console.log(`[db-wait] DATABASE_URL=${dbUrl}`);

  for (let i = 1; i <= MAX_ATTEMPTS; i++) {
    try {
      console.log(`[db-wait] Attempt ${i}/${MAX_ATTEMPTS} -> npx prisma db push --skip-generate`);
      execSync('npx prisma db push --skip-generate', { stdio: 'inherit' });
      console.log('[db-wait] prisma db push succeeded');
      process.exit(0);
    } catch (err) {
      console.warn(`[db-wait] prisma db push failed (attempt ${i}): ${err?.message || err}`);
      if (i === MAX_ATTEMPTS) {
        console.error('[db-wait] Exhausted attempts. Exiting with failure.');
        process.exit(1);
      }
      await sleep(SLEEP_MS);
    }
  }
})();
