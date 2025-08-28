export const TestPasswords = { valid: 'P@ssw0rd123!' } as const;

export function uniqueEmail(prefix = 'user'): string {
  const n = Date.now() + Math.floor(Math.random() * 1e6);
  return `${prefix}.${n}@example.com`;
}
