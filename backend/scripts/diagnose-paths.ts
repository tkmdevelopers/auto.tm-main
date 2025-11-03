/*
 * Diagnostics for path alias resolution.
 * Usage:
 *   npx ts-node -r tsconfig-paths/register ./scripts/diagnose-paths.ts
 */
import * as path from 'path';

function tryResolve(mod: string) {
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const resolved = require.resolve(mod);
    console.log(`[OK] ${mod} -> ${resolved}`);
  } catch (e: any) {
    console.log(`[FAIL] ${mod} -> ${e.message}`);
  }
}

const targets = [
  'src/auth/auth.entity',
  path.join(process.cwd(), 'backend', 'src', 'auth', 'auth.entity.ts'),
  './src/auth/auth.entity.ts',
];

console.log('Diagnosing module resolution...');
for (const t of targets) {
  tryResolve(t);
}

console.log('Done. If alias form fails but direct path works, ensure ts-node used with tsconfig-paths/register and that paths config exists.');
