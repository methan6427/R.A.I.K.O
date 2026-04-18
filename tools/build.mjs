// Bundles standalone-agent.mjs into a single Windows .exe.
//
// Usage from the tools/ directory:
//   npm install
//   npm run bundle
//
// Output:
//   dist/raiko-agent.exe

import { execFileSync } from 'node:child_process';
import { mkdirSync, rmSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';

const HERE = dirname(fileURLToPath(import.meta.url));
const DIST = join(HERE, 'dist');
const BUNDLE = join(DIST, 'agent.cjs');
const EXE = join(DIST, 'raiko-agent.exe');

rmSync(DIST, { recursive: true, force: true });
mkdirSync(DIST, { recursive: true });

console.log('[build] Bundling agent with esbuild ->', BUNDLE);
await build({
  entryPoints: [join(HERE, 'standalone-agent.mjs')],
  bundle: true,
  platform: 'node',
  target: 'node20',
  format: 'cjs',
  outfile: BUNDLE,
  banner: { js: '/* R.A.I.K.O Standalone Agent (bundled) */' },
  // import.meta.url is unreachable when process.pkg is set (the only case
  // we run as CJS), so the warning is dead-code noise.
  logOverride: { 'empty-import-meta': 'silent' },
});

// Invoke pkg's JS entry directly via node — avoids the .cmd shim, which
// breaks on Windows + Node 22 when paths contain spaces.
const require = createRequire(import.meta.url);
const pkgEntry = require.resolve('@yao-pkg/pkg/lib-es5/bin.js');

console.log('[build] Producing single-file binary with pkg ->', EXE);
execFileSync(
  process.execPath,
  [pkgEntry, BUNDLE, '--target', 'node20-win-x64', '--output', EXE],
  { stdio: 'inherit' },
);

console.log('[build] Done. Drop config.json next to the exe and run it.');
