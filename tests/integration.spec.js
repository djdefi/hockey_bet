// @ts-check
const { test, expect } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

const FIXTURE = 'tests/test-fixture.html';

async function loadFixture(page) {
  const url = 'file://' + path.resolve(__dirname, '..', FIXTURE);
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(500);
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. STANDINGS TABLE
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Standings Table', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
    await page.evaluate(() => switchTab('standings'));
  });

  test('standings table has proper table role', async ({ page }) => {
    const table = page.locator('.standings-table');
    await expect(table).toHaveAttribute('role', 'table');
  });

  test('standings table has aria-label', async ({ page }) => {
    const table = page.locator('.standings-table');
    await expect(table).toHaveAttribute('aria-label', 'NHL Standings');
  });

  test('standings table has column headers with scope', async ({ page }) => {
    const headers = page.locator('.standings-table th[scope="col"]');
    const count = await headers.count();
    expect(count).toBeGreaterThanOrEqual(6);
  });

  test('standings table has data rows', async ({ page }) => {
    const rows = page.locator('.standings-table tbody tr');
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(3);
  });

  test('fan team rows have data-team attribute', async ({ page }) => {
    const fanRow = page.locator('.standings-table .fan-team-row');
    await expect(fanRow).toHaveAttribute('data-team', 'SJS');
  });

  test('status icons have aria-labels', async ({ page }) => {
    const statuses = page.locator('.standings-table [aria-label]');
    const count = await statuses.count();
    expect(count).toBeGreaterThan(0);

    // Check specific status labels
    const eliminated = page.locator('[aria-label="Eliminated"]');
    await expect(eliminated).toHaveCount(1);

    const clinched = page.locator('[aria-label="Clinched"]');
    await expect(clinched).toHaveCount(1);

    const contending = page.locator('[aria-label="Contending"]');
    await expect(contending).toHaveCount(1);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. IMAGE FALLBACK BEHAVIOR
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Image Fallback', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('broken images trigger fallback display', async ({ page }) => {
    // Wait for onerror to fire on the broken image
    await page.waitForTimeout(1000);

    const fallback = page.locator('.team-logo-fallback').first();
    const isHidden = await fallback.evaluate(el => el.classList.contains('hidden'));
    // After onerror, fallback should not be hidden
    expect(isHidden).toBe(false);
  });

  test('fallback shows team abbreviation', async ({ page }) => {
    await page.waitForTimeout(1000);

    const fallback = page.locator('.team-logo-fallback').first();
    const text = await fallback.textContent();
    expect(text.trim()).toBe('SJS');
  });

  test('broken img element is hidden after error', async ({ page }) => {
    await page.waitForTimeout(1000);

    const img = page.locator('.matchup-card img.team-logo').first();
    const display = await img.evaluate(el => el.style.display);
    expect(display).toBe('none');
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Design Tokens', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('CSS custom properties are defined on :root', async ({ page }) => {
    const vars = await page.evaluate(() => {
      const style = getComputedStyle(document.documentElement);
      return {
        bgPrimary: style.getPropertyValue('--color-bg-primary').trim(),
        accentPrimary: style.getPropertyValue('--color-accent-primary').trim(),
      };
    });

    expect(vars.bgPrimary).toBeTruthy();
    expect(vars.accentPrimary).toBeTruthy();
  });

  test('team theme overrides CSS custom properties', async ({ page }) => {
    const defaultAccent = await page.evaluate(() =>
      getComputedStyle(document.documentElement).getPropertyValue('--color-accent-primary').trim()
    );

    await page.evaluate(() => window.TeamThemes.applyTheme('sharks'));

    const sharksAccent = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );

    expect(sharksAccent).toBeTruthy();
    expect(sharksAccent).not.toBe(defaultAccent);
  });

  test('resetting theme removes inline CSS overrides', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.applyTheme('sharks');
      window.TeamThemes.applyTheme('default');
    });

    const inlineStyle = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );

    // After reset, inline property should be empty (design-tokens.css takes over)
    expect(inlineStyle).toBe('');
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 4. SERVICE WORKER FILE ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Service Worker Analysis', () => {
  test('cache version is consistent between CACHE_NAME and DATA_CACHE_NAME', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');

    const cacheMatch = sw.match(/CACHE_NAME = '([^']+)'/);
    const dataMatch = sw.match(/DATA_CACHE_NAME = '([^']+)'/);

    expect(cacheMatch).toBeTruthy();
    expect(dataMatch).toBeTruthy();

    // Extract version numbers
    const cacheVersion = cacheMatch[1].match(/v(\d+)/);
    const dataVersion = dataMatch[1].match(/v(\d+)/);

    expect(cacheVersion).toBeTruthy();
    expect(dataVersion).toBeTruthy();
    expect(cacheVersion[1]).toBe(dataVersion[1]);
  });

  test('service worker handles all fetch event types', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');

    // JSON handling (stale-while-revalidate)
    expect(sw).toContain('.json');

    // Navigation handling (offline fallback)
    expect(sw).toContain("request.mode === 'navigate'");

    // Static asset handling (cache-first)
    expect(sw).toContain('caches.match(request)');
  });

  test('service worker activates correctly (claims clients)', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    expect(sw).toContain('self.clients.claim()');
  });

  test('service worker skips waiting on install', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    expect(sw).toContain('self.skipWaiting()');
  });

  test('service worker cleans up old caches', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    expect(sw).toContain('caches.delete(name)');
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. MULTI-VIEWPORT CONSISTENCY
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Multi-Viewport Consistency', () => {
  const viewports = [
    { name: 'iPhone SE', width: 375, height: 667 },
    { name: 'iPad', width: 768, height: 1024 },
    { name: 'Desktop', width: 1280, height: 720 },
  ];

  for (const vp of viewports) {
    test(`app loads without errors on ${vp.name} (${vp.width}x${vp.height})`, async ({ page }) => {
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));

      await page.setViewportSize({ width: vp.width, height: vp.height });
      await loadFixture(page);

      expect(errors).toHaveLength(0);
    });

    test(`tab switching works on ${vp.name}`, async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await loadFixture(page);

      await page.evaluate(() => switchTab('standings'));
      await expect(page.locator('#standings-tab')).toHaveClass(/active/);

      await page.evaluate(() => switchTab('league'));
      await expect(page.locator('#league-tab')).toHaveClass(/active/);
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. TEMPLATE FILE QUALITY
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Template Quality', () => {
  test('standings.html.erb has DOCTYPE declaration', () => {
    const html = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'standings.html.erb'), 'utf-8');
    // ERB templates may have a comment line before DOCTYPE
    const withoutComments = html.replace(/^<%#[^%]*%>\s*/gm, '').trimStart();
    expect(withoutComments.toLowerCase()).toMatch(/^<!doctype html>/);
  });

  test('standings.html.erb has lang attribute', () => {
    const html = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'standings.html.erb'), 'utf-8');
    expect(html).toContain('lang="en"');
  });

  test('standings.html.erb has viewport meta tag', () => {
    const html = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'standings.html.erb'), 'utf-8');
    expect(html).toContain('viewport');
    expect(html).toContain('width=device-width');
  });

  test('standings.html.erb has charset meta', () => {
    const html = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'standings.html.erb'), 'utf-8');
    expect(html).toContain('charset');
  });

  test('playoffs.html.erb has proper HTML structure', () => {
    const html = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoffs.html.erb'), 'utf-8');
    expect(html).toContain('<!DOCTYPE html>');
    expect(html).toContain('lang="en"');
  });

  test('all JS files in lib/ are syntactically valid', () => {
    const jsFiles = fs.readdirSync(path.resolve(__dirname, '..', 'lib'))
      .filter(f => f.endsWith('.js'));

    for (const file of jsFiles) {
      const content = fs.readFileSync(path.resolve(__dirname, '..', 'lib', file), 'utf-8');
      // Check for basic syntax validity — no orphaned braces, no syntax errors
      expect(() => {
        new Function(content);
      }).not.toThrow();
    }
  });

  test('no console.log left in production JS (only warn/error allowed)', () => {
    const jsFiles = fs.readdirSync(path.resolve(__dirname, '..', 'lib'))
      .filter(f => f.endsWith('.js'));

    for (const file of jsFiles) {
      const content = fs.readFileSync(path.resolve(__dirname, '..', 'lib', file), 'utf-8');
      const lines = content.split('\n');

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        // Skip comments
        if (line.startsWith('//') || line.startsWith('*')) continue;
        // Check for console.log (but allow console.warn, console.error)
        if (line.includes('console.log(') && !line.includes('//')) {
          // Allow console.log only in PWA install success message
          if (!line.includes('installed successfully')) {
            throw new Error(`${file}:${i + 1} has console.log: ${line}`);
          }
        }
      }
    }
  });
});
