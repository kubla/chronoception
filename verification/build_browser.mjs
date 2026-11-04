import { readFileSync, writeFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { createHash } from 'node:crypto';

const read = path => readFileSync(new URL('../' + path, import.meta.url), 'utf8');
const hash = source => createHash('sha256').update(source).digest('hex').slice(0, 12);
const core = stripTypeScriptTypes(read('docs/preview/core.mts'), { mode: 'strip' });
const app = stripTypeScriptTypes(read('docs/preview/app.mts'), { mode: 'strip' })
  .replace("'./core.mjs'", "'./core.mjs?v=" + hash(core) + "'");
const index = read('docs/index.html')
  .replace(/href="preview\/style.css(?:\?v=[a-f0-9]+)?"/, 'href="preview/style.css?v=' + hash(read('docs/preview/style.css')) + '"')
  .replace(/src="preview\/app.mjs(?:\?v=[a-f0-9]+)?"/, 'src="preview/app.mjs?v=' + hash(app) + '"');
for (const [path, generated] of [['docs/preview/core.mjs', core], ['docs/preview/app.mjs', app], ['docs/index.html', index]]) {
  const output = new URL('../' + path, import.meta.url);
  if (process.argv.includes('--check')) {
    if (readFileSync(output, 'utf8') !== generated) throw new Error('Stale generated browser asset: ' + path);
  } else writeFileSync(output, generated);
}
