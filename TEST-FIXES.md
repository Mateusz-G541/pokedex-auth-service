# Test Fixes - CI/CD Issues Resolved

## Issues Identified

### Issue 1: JWT Service Test - Hoisting Error
```
Error: [vitest] There was an error when mocking a module.
ReferenceError: Cannot access 'signSpy' before initialization
```

**Root Cause**: Vitest hoists `vi.mock()` calls to the top of the file, but the spy variables (`signSpy`, `verifySpy`, `decodeSpy`) were declared outside the mock factory, causing a reference error.

### Issue 2: Playwright Tests Running in Vitest
```
Error: Playwright Test did not expect test.describe() to be called here.
```

**Root Cause**: The `tests/api/auth.api.spec.ts` file contains Playwright tests, but Vitest was trying to run them because there was no configuration to exclude them.

## Solutions Implemented

### Fix 1: JWT Service Test (`src/tests/jwt.service.test.ts`)

**Before:**
```typescript
// Spies declared outside vi.mock factory - causes hoisting error
const signSpy = vi.fn((..._args: any[]) => 'mock.token.value');
const verifySpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));
const decodeSpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));

vi.mock('jsonwebtoken', () => ({
  default: {
    sign: signSpy,  // ❌ Reference error - signSpy not initialized yet
    verify: verifySpy,
    decode: decodeSpy,
    // ...
  }
}));
```

**After:**
```typescript
// Spies declared INSIDE vi.mock factory - no hoisting issues
vi.mock('jsonwebtoken', () => {
  const signSpy = vi.fn((..._args: any[]) => 'mock.token.value');
  const verifySpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));
  const decodeSpy = vi.fn((_token: string) => ({ userId: 1, email: 'user@example.com' }));
  
  return {
    default: {
      sign: signSpy,  // ✅ Works - signSpy is defined in same scope
      verify: verifySpy,
      decode: decodeSpy,
      // ...
    }
  };
});

// Import jwt after mocking
import { jwtService } from '../services/jwt.service';
import jwt from 'jsonwebtoken';

// Get references to mocked functions for assertions
const signSpy = jwt.sign as any;
const verifySpy = jwt.verify as any;
const decodeSpy = jwt.decode as any;
```

**Key Changes:**
1. Moved spy declarations inside the `vi.mock()` factory function
2. Import `jwt` after the mock is set up
3. Get references to the mocked functions from the imported module

### Fix 2: Vitest Configuration (`vitest.config.ts`)

**Created new file** to configure Vitest properly:

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    // Exclude Playwright tests from Vitest
    exclude: [
      '**/node_modules/**',
      '**/dist/**',
      '**/tests/api/**',      // ✅ Exclude Playwright API tests
      '**/tests/e2e/**',      // ✅ Exclude Playwright E2E tests
      '**/*.spec.ts',         // ✅ Exclude .spec.ts files (Playwright convention)
    ],
    // Include only unit tests
    include: [
      'src/**/*.test.ts',     // ✅ Only run .test.ts files in src/
      'src/**/*.test.tsx',
    ],
  },
});
```

**Key Configuration:**
- **Exclude**: All Playwright test files (`tests/api/**`, `**/*.spec.ts`)
- **Include**: Only Vitest unit tests (`src/**/*.test.ts`)

### Fix 3: Package.json Scripts

**Updated test scripts** for clarity:

```json
{
  "scripts": {
    "test": "vitest run",           // Run Vitest unit tests
    "test:unit": "vitest run",      // Alias for unit tests
    "test:api": "bash scripts/gen-keys.sh && playwright test -c playwright.config.ts --project=API",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest run --coverage"
  }
}
```

## Test Separation

### Vitest (Unit Tests)
- **Location**: `src/**/*.test.ts`
- **Purpose**: Unit tests for services, utilities, middleware
- **Run with**: `npm test` or `npm run test:unit`
- **Examples**:
  - `src/tests/jwt.service.test.ts`
  - `src/tests/validation.test.ts`
  - `src/tests/validate-middleware.test.ts`

### Playwright (API Integration Tests)
- **Location**: `tests/api/**/*.spec.ts`
- **Purpose**: API integration tests with real database
- **Run with**: `npm run test:api`
- **Examples**:
  - `tests/api/auth.api.spec.ts`

## CI/CD Workflows

### Workflow 1: `ci.yml` (Existing)
- **Triggers**: All pushes and PRs
- **Tests**: Playwright API tests only
- **Command**: `npm run test:api`

### Workflow 2: `docker-build-push.yml` (New)
- **Triggers**: Push to main/master, PRs, manual
- **Tests**: Vitest unit tests
- **Command**: `npm test`
- **Additional**: Builds and pushes Docker image

## Verification

After these fixes, the CI/CD pipeline should:

1. ✅ **Vitest unit tests pass** (no hoisting errors)
2. ✅ **Playwright tests excluded** from Vitest runs
3. ✅ **Playwright tests run separately** via `test:api` script
4. ✅ **Docker build succeeds** after tests pass

## Testing Locally

### Run unit tests:
```bash
npm test
# or
npm run test:unit
```

### Run API tests:
```bash
npm run test:api
```

### Run all tests:
```bash
npm test && npm run test:api
```

## Key Learnings

### Vitest Hoisting
- `vi.mock()` is hoisted to the top of the file
- Variables declared outside the factory are not accessible inside
- **Solution**: Declare all mocks inside the factory function

### Test Separation
- Use different file extensions for different test frameworks
  - `.test.ts` for Vitest unit tests
  - `.spec.ts` for Playwright integration tests
- Configure test runners to exclude each other's files
- Keep test files in separate directories

### CI/CD Best Practices
- Run fast unit tests in every workflow
- Run slower integration tests separately or less frequently
- Use proper test configuration files (`vitest.config.ts`, `playwright.config.ts`)
- Clear separation between test types in package.json scripts

## Related Files

- `src/tests/jwt.service.test.ts` - Fixed JWT service unit tests
- `vitest.config.ts` - New Vitest configuration
- `package.json` - Updated test scripts
- `.github/workflows/docker-build-push.yml` - Runs unit tests
- `.github/workflows/ci.yml` - Runs API tests

## References

- [Vitest Mocking Guide](https://vitest.dev/api/vi.html#vi-mock)
- [Vitest Configuration](https://vitest.dev/config/)
- [Playwright Test](https://playwright.dev/docs/test-intro)
