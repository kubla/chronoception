import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { mkdirSync, writeFileSync } from 'node:fs';
import { extname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const { chromium } = await import(pathToFileURL(process.argv[2]).href);
const root = resolve('docs');
const mime = { '.html': 'text/html', '.css': 'text/css', '.mjs': 'text/javascript', '.svg': 'image/svg+xml' };
const server = createServer(async (request, response) => {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  const path = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  if (!path.startsWith(root + '/')) { response.writeHead(403).end(); return; }
  try {
    const bytes = await readFile(path);
    response.writeHead(200, { 'Content-Type': mime[extname(path)] ?? 'application/octet-stream' }).end(bytes);
  } catch { response.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const base = 'http://127.0.0.1:' + server.address().port;
mkdirSync('evidence/browser', { recursive: true });
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1280, height: 960 }, recordVideo: { dir: 'evidence/browser/videos', size: { width: 1280, height: 960 } } });
const page = await context.newPage();
const failures = [];
const journeys = [];
page.on('pageerror', error => failures.push(error.message));
page.on('response', response => { if (response.status() >= 400) failures.push(response.status() + ' ' + response.url()); });
const click = name => page.getByRole('button', { name, exact: true }).click();
const visible = async text => { await page.getByText(text, { exact: true }).first().waitFor({ state: 'visible' }); };

try {
  await page.goto(base);
  await page.screenshot({ path: 'evidence/browser/phone-ready.png', fullPage: true });
  await click('Interval, 5 min');
  await page.getByLabel('Seconds', { exact: true }).fill('0');
  await click('Use interval');
  await visible('Choose an interval longer than zero.');
  await page.getByLabel('Seconds', { exact: true }).fill('1');
  await click('Use interval');
  await click('Begin');
  await page.waitForTimeout(1100);
  await click('Now');
  assert.match(await page.locator('.feedback h2').innerText(), /late$/);
  await page.screenshot({ path: 'evidence/browser/phone-feedback.png', fullPage: true });
  await click('Finish');
  await click('View history');
  await visible('1 recorded attempt');
  await page.reload();
  await click('History');
  await visible('1 recorded attempt');
  await visible('Completed');
  journeys.push('phone: real estimate, feedback, finish, persisted history after reload');

  await click('Done');
  await click('Begin');
  await click('End session');
  await click('View history');
  await visible('1 recorded attempt');
  await visible('Cancelled');
  journeys.push('phone: cancellation does not manufacture an attempt');

  await click('Done');
  await click('Practice again');
  await click('Begin');
  await page.reload();
  await click('History');
  await visible('Interrupted');
  await visible('1 recorded attempt');
  journeys.push('phone: unfinished practice is interrupted on reload');

  await click('Apple Watch');
  await click('History');
  await visible('No attempts yet');
  await click('Done');
  await click('3 attempts');
  await click('Begin');
  for (let index = 0; index < 3; index++) {
    await click('Now');
    await click(index === 2 ? 'Finish' : 'Next attempt');
  }
  await click('View history');
  await visible('3 recorded attempts');
  await page.screenshot({ path: 'evidence/browser/watch-history.png', fullPage: true });
  journeys.push('watch: independent history and three explicit estimates/advances');

  await click('About Chronoception');
  await visible('Your practice, stored locally.');
  assert.equal(await page.getByRole('link', { name: 'Native app privacy policy ↗' }).getAttribute('href'), 'privacy.html');
  journeys.push('about: privacy and browser limitations are available without an account');

  await page.goto(base);
  await click('Train yourself');
  await click('Interval, 5 min');
  await page.getByLabel('Seconds', { exact: true }).fill('1');
  await click('Use interval');
  await click('3 repetitions');
  await click('Begin');
  await visible('0 of 3 cues');
  await visible('1 of 3 cues');
  await page.screenshot({ path: 'evidence/browser/training-running.png', fullPage: true });
  await visible('Training complete');
  await visible('3 of 3 cues');
  await page.screenshot({ path: 'evidence/browser/training-complete.png', fullPage: true });
  await click('View history');
  await visible('3 of 3 cued intervals');
  await visible('1 recorded attempt');
  await visible('1s calibration');
  await page.reload();
  await click('History');
  await visible('3 of 3 cued intervals');
  journeys.push('phone: train with three real timed cues, persistence, separate estimate count and per-interval calibration');

  for (const kind of ['phone', 'watch']) {
    await page.goto(base + '/?device=' + kind);
    await click('Train yourself');
    await click('Begin');
    await click('End training');
    await visible('Training ended');
    await visible('0 of 1 cues');
    await click('View history');
    await visible('0 of 1 cued intervals');
    await click('Done');
    await click('Practice again');
    await click('Begin');
    await page.reload();
    await click('History');
    await visible('Interrupted');
    journeys.push(kind + ': training cancellation and reload do not invent cued intervals');
  }

  for (const kind of ['phone', 'watch']) {
    await page.goto(base + '/?device=' + kind);
    await click('Train yourself');
    await click('Interval, 5 min');
    await page.getByLabel('Seconds', { exact: true }).fill('1');
    await click('Use interval');
    await click('3 repetitions');
    await click('Begin');
    await visible('Training complete');
    await visible('3 of 3 cues');
    await page.screenshot({ path: `evidence/browser/${kind}-training-complete.png`, fullPage: true });
    await click('Practice again');
    await click('Begin');
    await click('History');
    await click('Done');
    await visible('Training interrupted');
    await visible('0 of 3 cues');
    await click('Practice again');
    await click('Begin');
    await click(kind === 'phone' ? 'Apple Watch' : 'iPhone');
    await page.waitForTimeout(1200);
    await click(kind === 'phone' ? 'iPhone' : 'Apple Watch');
    await visible('Training interrupted');
    await visible('0 of 3 cues');
    journeys.push(kind + ': positive repeated cues; opening a sheet or switching device interrupts invisible training');
  }

  const layouts = [];
  for (const width of [320, 390, 1280]) {
    for (const device of ['phone', 'watch']) {
      await page.setViewportSize({ width, height: width === 1280 ? 960 : 844 });
      await page.goto(base + '/?device=' + device);
      await page.locator('[data-action="begin"]').waitFor({ state: 'visible' });
      const bounds = await page.evaluate(() => ({ viewport: innerWidth, content: document.documentElement.scrollWidth }));
      assert.ok(bounds.content <= bounds.viewport, JSON.stringify({ device, width, ...bounds }));
      layouts.push({ device, width, ...bounds });
      await page.screenshot({ path: `evidence/browser/${device}-${width}.png`, fullPage: true });
    }
  }
  assert.deepEqual(failures, []);
  writeFileSync('evidence/browser/receipt.json', JSON.stringify({ candidate: process.env.GITHUB_SHA, candidate_tree: (await import('node:child_process')).execFileSync('git', ['rev-parse', 'HEAD^{tree}'], { encoding: 'utf8' }).trim(), run: process.env.GITHUB_RUN_ID, result: 'passed', journeys, layouts, browserErrors: failures, environment: 'ephemeral Chromium against the actual Pages files; live Pages also inspected separately', haptics: 'not_simulated' }, null, 2) + '\n');
  console.log(`PASS: ${journeys.length} browser journeys, six viewport/device layouts, no page errors or failed resources.`);
} finally {
  await context.close();
  await browser.close();
  server.close();
}
