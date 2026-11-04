import { readFileSync, writeFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';

for (const name of ['core', 'app']) {
  const source = new URL('../docs/preview/' + name + '.mts', import.meta.url);
  const output = new URL('../docs/preview/' + name + '.mjs', import.meta.url);
  const generated = stripTypeScriptTypes(readFileSync(source, 'utf8'), { mode: 'strip' });
  if (process.argv.includes('--check')) {
    if (readFileSync(output, 'utf8') !== generated) throw new Error('Stale generated browser module: ' + name);
  } else writeFileSync(output, generated);
}
