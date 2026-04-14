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
// 1. CONSOLE ERROR AUDIT — catch any JS errors on load
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Console Error Audit', () => {
  test('no JS errors on initial page load', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    await loadFixture(page);
    expect(errors).toEqual([]);
  });

  test('no JS errors on mobile viewport load', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);
    expect(errors).toEqual([]);
  });

  test('no JS errors when applying all 32 team themes', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    await loadFixture(page);

    const teamKeys = await page.evaluate(() =>
      Object.keys(window.TeamThemes.themes).filter(k => k !== 'default')
    );

    for (const key of teamKeys) {
      await page.evaluate(k => window.TeamThemes.applyTheme(k), key);
    }
    // Reset to default
    await page.evaluate(() => window.TeamThemes.applyTheme('default'));

    expect(errors).toEqual([]);
  });

  test('no JS errors when opening and closing team picker', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    await loadFixture(page);

    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);

    expect(errors).toEqual([]);
  });

  test('no JS errors when using social reactions', async ({ page }) => {
    const errors = [];
    page.on('pageerror', err => errors.push(err.message));
    await loadFixture(page);

    // Click reaction, pick emoji
    await page.click('.reaction-btn');
    await page.waitForTimeout(200);
    await page.click('.emoji-btn');
    await page.waitForTimeout(300);

    expect(errors).toEqual([]);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. THEME SWITCHING INTEGRATION — full round-trips
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Theme Switching Integration', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('selecting team via picker persists across reload', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);

    // Click Bruins card
    const bruinsCard = page.locator('.team-picker-card[data-team="bruins"]');
    await bruinsCard.click();
    await page.waitForTimeout(400);

    // Reload page
    await loadFixture(page);

    // Theme should persist
    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBe('bruins');

    // CSS variable should be applied
    const accent = await page.evaluate(() =>
      getComputedStyle(document.documentElement).getPropertyValue('--color-accent-primary').trim()
    );
    expect(accent).toBe('#FFB81C');
  });

  test('reset via picker fully clears theme on reload', async ({ page }) => {
    // Set a team
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('avalanche');
      window.TeamThemes.applyTheme('avalanche');
    });

    // Open picker and reset
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.click('.team-picker-reset');
    await page.waitForTimeout(400);

    // Reload
    await loadFixture(page);

    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBeNull();

    const cachedCSS = await page.evaluate(() => localStorage.getItem('nhl_fan_team_css'));
    expect(cachedCSS).toBeNull();

    // Inline styles should be clear
    const inlineAccent = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );
    expect(inlineAccent).toBe('');
  });

  test('rapid theme switching does not corrupt state', async ({ page }) => {
    const teams = ['bruins', 'kraken', 'devils', 'sharks', 'avalanche', 'default'];
    for (const team of teams) {
      await page.evaluate(t => window.TeamThemes.applyTheme(t), team);
    }

    // Should be in default state
    const inlineAccent = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );
    expect(inlineAccent).toBe('');
  });

  test('meta theme-color updates with team theme', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('kraken'));
    const metaContent = await page.evaluate(() =>
      document.querySelector('meta[name="theme-color"]')?.getAttribute('content')
    );
    expect(metaContent).toBeTruthy();
    expect(metaContent).not.toBe('#0b162a'); // Should be kraken's dark bg, not default
  });

  test('data-team attribute set on html element', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('devils'));
    const attr = await page.getAttribute('html', 'data-team');
    expect(attr).toBe('devils');

    await page.evaluate(() => window.TeamThemes.applyTheme('default'));
    const cleared = await page.getAttribute('html', 'data-team');
    expect(cleared).toBe('');
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. TEAM PICKER EDGE CASES
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Team Picker Edge Cases', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('selected team shows checkmark in picker', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('bruins');
      window.TeamThemes.applyTheme('bruins');
    });

    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);

    const selected = page.locator('.team-picker-card.selected');
    await expect(selected).toHaveCount(1);
    const key = await selected.getAttribute('data-team');
    expect(key).toBe('bruins');
  });

  test('clicking outside content closes modal', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    // Click the modal wrapper area outside the content (top-left corner)
    await page.locator('.team-picker-modal').click({ position: { x: 5, y: 5 } });
    await page.waitForTimeout(300);
    await expect(page.locator('.team-picker-modal.open')).toHaveCount(0);
  });

  test('modal body scroll is locked when open', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const overflow = await page.evaluate(() => document.body.style.overflow);
    expect(overflow).toBe('hidden');
  });

  test('modal body scroll restored after close', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    const overflow = await page.evaluate(() => document.body.style.overflow);
    expect(overflow).toBe('');
  });

  test('each team card has a two-color swatch', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const swatches = page.locator('.team-picker-swatch');
    const count = await swatches.count();
    expect(count).toBe(32);

    // Each swatch should have 2 color spans
    const firstSwatchSpans = await swatches.first().locator('span').count();
    expect(firstSwatchSpans).toBe(2);
  });

  test('double-opening picker does not duplicate modals', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);

    const modals = page.locator('.team-picker-modal');
    // Should only have one modal in DOM (rebuilt each time)
    await expect(modals).toHaveCount(1);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 4. SOCIAL FEATURES EDGE CASES
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Social Features Edge Cases', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('multiple reactions on same card accumulate', async ({ page }) => {
    // First reaction
    const btn = page.locator('.reaction-btn').first();
    await btn.click();
    await page.waitForTimeout(200);
    await page.locator('.emoji-btn').first().click();
    await page.waitForTimeout(300);

    // Second reaction (same emoji)
    await btn.click();
    await page.waitForTimeout(200);
    await page.locator('.emoji-btn').first().click();
    await page.waitForTimeout(300);

    // Count should be 2
    const countText = await page.locator('.reaction-count').first().textContent();
    expect(countText).toContain('2');
  });

  test('emoji picker repositions at viewport edge', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await loadFixture(page);

    await page.click('.reaction-btn');
    await page.waitForTimeout(200);

    const picker = page.locator('.emoji-picker');
    await expect(picker).toBeVisible();

    const box = await picker.boundingBox();
    // Picker should be within viewport
    expect(box.x).toBeGreaterThanOrEqual(0);
    expect(box.x + box.width).toBeLessThanOrEqual(375 + 10); // small tolerance
  });

  test('reaction float animation respects reduced motion', async ({ page }) => {
    // Emulate reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await loadFixture(page);

    await page.click('.reaction-btn');
    await page.waitForTimeout(200);
    await page.click('.emoji-btn');
    await page.waitForTimeout(300);

    // No floating element should be in DOM (skipped for reduced motion)
    const floaters = page.locator('.reaction-float');
    await expect(floaters).toHaveCount(0);
  });

  test('confetti respects reduced motion', async ({ page }) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await loadFixture(page);

    await page.evaluate(() => window.socialFeatures.celebrate());
    await page.waitForTimeout(500);

    const confetti = page.locator('.confetti-piece');
    await expect(confetti).toHaveCount(0);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. MOBILE GESTURES EDGE CASES
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Mobile Gestures Edge Cases', () => {
  test('does NOT initialize on desktop viewport', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });
    await loadFixture(page);
    const hasPullIndicator = await page.locator('#pull-indicator').count();
    expect(hasPullIndicator).toBe(0);
  });

  test('pulltorefresh custom event is dispatched', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);

    // Listen for the custom event
    const eventFired = await page.evaluate(() => {
      return new Promise(resolve => {
        document.addEventListener('pulltorefresh', (e) => {
          e.preventDefault(); // prevent actual reload
          resolve(true);
        });
        // Simulate the triggerRefresh method
        window.mobileGestures.triggerRefresh();
      });
    });
    expect(eventFired).toBe(true);
  });

  test('getCurrentTabIndex returns valid index', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);
    const idx = await page.evaluate(() => window.mobileGestures.getCurrentTabIndex());
    expect(idx).toBe(0); // 'league' is active by default
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. CROSS-FILE STATIC ANALYSIS
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Cross-File Consistency', () => {
  test('all local scripts declared in app_assets are in precache_paths', async () => {
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );

    const localScripts = assetManifest.local_scripts
      .map(script => script.src)
      .filter(src => !src.startsWith('http'));

    for (const script of localScripts) {
      expect(assetManifest.precache_paths).toContain('./' + script);
    }
  });

  test('service-worker cache version matches across both names', async () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    const cacheMatch = sw.match(/CACHE_NAME = '([^']+)'/);
    const dataCacheMatch = sw.match(/DATA_CACHE_NAME = '([^']+)'/);
    expect(cacheMatch).toBeTruthy();
    expect(dataCacheMatch).toBeTruthy();

    // Extract version numbers
    const cacheVersion = cacheMatch[1].match(/v(\d+)/)[1];
    const dataVersion = dataCacheMatch[1].match(/v(\d+)/)[1];
    expect(cacheVersion).toBe(dataVersion);
  });

  test('theme-init.js localStorage key matches team-themes.js', async () => {
    const init = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'theme-init.js'), 'utf-8');
    const themes = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'team-themes.js'), 'utf-8');

    // Both should reference the same key
    expect(init).toContain('nhl_fan_team_css');
    expect(themes).toContain('nhl_fan_team_css');
  });

  test('team-picker.js uses TeamThemes API, not raw localStorage', async () => {
    const picker = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'team-picker.js'), 'utf-8');
    // Should use setStoredTeam, not direct localStorage for team key
    expect(picker).toContain('setStoredTeam');
    // Should NOT have direct localStorage.removeItem for the team key
    expect(picker).not.toContain("localStorage.removeItem('nhl_fan_team')");
    expect(picker).not.toContain("localStorage.removeItem('fan_team')");
  });

  test('playoffs.html.erb loads design-tokens.css', async () => {
    const playoffs = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoffs.html.erb'), 'utf-8');
    expect(playoffs).toContain('design-tokens.css');
  });

  test('playoffs.html.erb loads iconify script', async () => {
    const playoffs = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoffs.html.erb'), 'utf-8');
    expect(playoffs).toContain('iconify-icon');
    expect(playoffs).toMatch(/script.*iconify/);
  });

  test('all image onerror handlers remove hidden class', async () => {
    const erb = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'standings.html.erb'), 'utf-8');
    const onerrorMatches = erb.match(/onerror="[^"]+"/g) || [];

    for (const handler of onerrorMatches) {
      expect(handler).toContain("classList.remove('hidden')");
    }
  });

  test('site.webmanifest references icon.svg', async () => {
    const manifest = JSON.parse(fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8'));
    const svgIcon = manifest.icons.find(i => i.src === 'icon.svg');
    expect(svgIcon).toBeTruthy();
    expect(svgIcon.type).toBe('image/svg+xml');
  });

  test('all team theme backgrounds produce valid hex colors', async ({ page }) => {
    await loadFixture(page);
    const invalid = await page.evaluate(() => {
      const themes = window.TeamThemes.themes;
      const bad = [];
      for (const [key, team] of Object.entries(themes)) {
        const bg = team.theme['--color-bg-primary'];
        if (!bg || !/^#[0-9a-f]{6}$/i.test(bg)) {
          bad.push({ key, bg });
        }
      }
      return bad;
    });
    expect(invalid).toEqual([]);
  });
});
