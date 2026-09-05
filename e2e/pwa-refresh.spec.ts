import { test, expect, Page } from '@playwright/test';
import { once } from 'node:events';
import { createServer, get } from 'node:http';
import path from 'node:path';

test.use({ serviceWorkers: 'allow' });

test.beforeEach(async ({ page }) => {
  await page.route('**/pwa-harness.html', route => route.fulfill({
    contentType: 'text/html',
    body: '<!DOCTYPE html><html lang="en"><title>PWA lifecycle fixture</title><body>Worker lifecycle fixture</body></html>'
  }));
  await page.goto('/pwa-harness.html');
  await page.unroute('**/pwa-harness.html');
});

async function activateWorker(page: Page) {
  await page.evaluate(async () => {
    await navigator.serviceWorker.register('./service-worker.js');
    await navigator.serviceWorker.ready;
  });
  await page.waitForFunction(() => navigator.serviceWorker.controller !== null);
}

test('offline worker update failure is reported without an unhandled rejection', async ({ page }) => {
  const errors: string[] = [];
  const warnings: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'warning') warnings.push(message.text());
  });
  await page.evaluate(() => {
    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        controller: null,
        register: async () => ({
          update: async () => { throw new Error('offline update'); },
          addEventListener() {}
        }),
        addEventListener() {}
      }
    });
  });
  await page.addScriptTag({ path: path.join(__dirname, '../lib/standings-app.js') });
  await page.evaluate(() => window.dispatchEvent(new Event('load')));
  await expect.poll(() => warnings.some(message =>
    message.includes('ServiceWorker registration or update failed:') && message.includes('offline update')
  )).toBe(true);
  expect(errors).toEqual([]);
});

test('new worker replaces previous-season asset and data caches', async ({ page, request }) => {
  await page.evaluate(async () => {
    localStorage.setItem('nhl_fan_team', 'bruins');
    const assets = await caches.open('hockey-bet-static-v11');
    await assets.put('./styles.css', new Response('obsolete stylesheet'));
    const data = await caches.open('hockey-bet-data-v11');
    await data.put('./available_seasons.json', new Response('{"seasons":["obsolete"]}'));
  });

  await activateWorker(page);

  const styles = await request.get('/styles.css');
  expect(await page.evaluate(async () => {
    const cache = await caches.open('hockey-bet-static-v12');
    return (await cache.match('./styles.css'))?.text();
  })).toBe(await styles.text());

  const seasons = await request.get('/available_seasons.json');
  expect(await page.evaluate(async () =>
    (await fetch('./available_seasons.json')).json()
  )).toEqual(await seasons.json());

  const keys = await page.evaluate(() => caches.keys());
  expect(keys).toEqual(expect.arrayContaining(['hockey-bet-static-v12', 'hockey-bet-data-v12']));
  expect(keys).not.toContain('hockey-bet-static-v11');
  expect(keys).not.toContain('hockey-bet-data-v11');
  expect(await page.evaluate(() => localStorage.getItem('nhl_fan_team'))).toBe('bruins');
});

test('cached league and offline fallback recover after reconnecting', async ({ page, baseURL, isMobile }, testInfo) => {
  if (!baseURL) throw new Error('PWA recovery requires the configured site server');
  const target = new URL(baseURL);
  let connected = true;
  const server = createServer((request, response) => {
    if (!connected) {
      request.socket.destroy();
      return;
    }
    const upstream = get({
      hostname: target.hostname,
      port: target.port,
      path: request.url ?? '/',
      agent: false
    }, incoming => {
      response.writeHead(incoming.statusCode ?? 502, { ...incoming.headers, 'cache-control': 'no-store' });
      incoming.pipe(response);
    });
    upstream.on('error', error => response.destroy(error));
  });
  const listening = once(server, 'listening');
  server.listen(0, '127.0.0.1');
  await listening;

  try {
    const address = server.address();
    if (!address || typeof address === 'string') throw new Error('PWA recovery server has no TCP port');
    const origin = `http://127.0.0.1:${address.port}`;
    await page.goto(origin, { waitUntil: 'domcontentloaded' });
    await activateWorker(page);

    // Drop only this origin's connections; leave service-worker networking enabled.
    connected = false;
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expect(page.getByRole('heading', { name: 'NHL Fan League', exact: true })).toBeVisible();
    await page.locator('.desktop-tab[data-tab="standings"], .nav-item[data-tab="standings"]')
      .filter({ visible: true }).click();
    await expect(page.locator('#standings-tab')).toBeVisible();
    await page.goto(`${origin}/?offline-refresh-probe`, { waitUntil: 'domcontentloaded' });
    await expect(page.getByRole('heading', { name: "You're offline", exact: true })).toBeVisible();
    await expect(page.locator('body')).toHaveCSS('background-color', 'rgb(16, 18, 20)');
    await expect(page.locator('link[rel="stylesheet"], script[src]')).toHaveCount(0);

    const retry = page.getByRole('button', { name: 'Try again', exact: true });
    await expect(retry).toHaveCSS('min-height', '44px');
    if (!isMobile) {
      await page.keyboard.press('Tab');
      await expect(retry).toBeFocused();
    }
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
    await page.screenshot({ path: testInfo.outputPath('offline.png') });

    connected = true;
    if (isMobile) {
      await retry.tap();
    } else {
      await page.keyboard.press('Enter');
    }
    await expect(page.getByRole('heading', { name: 'NHL Fan League', exact: true })).toBeVisible();
  } finally {
    const closed = new Promise<void>((resolve, reject) =>
      server.close(error => error ? reject(error) : resolve())
    );
    server.closeAllConnections();
    await closed;
  }
});
