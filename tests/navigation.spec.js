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
// 1. DESKTOP TAB NAVIGATION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Desktop Tab Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('league tab is active by default', async ({ page }) => {
    const leagueTab = page.locator('#league-tab');
    await expect(leagueTab).toHaveClass(/active/);

    const leagueBtn = page.locator('.desktop-tab[data-tab="league"]');
    await expect(leagueBtn).toHaveClass(/active/);
    await expect(leagueBtn).toHaveAttribute('aria-current', 'page');
  });

  test('clicking a desktop tab switches the active panel', async ({ page }) => {
    const matchupsBtn = page.locator('.desktop-tab[data-tab="matchups"]');
    await matchupsBtn.click();

    // Matchups tab should now be active
    const matchupsTab = page.locator('#matchups-tab');
    await expect(matchupsTab).toHaveClass(/active/);

    // League tab should no longer be active
    const leagueTab = page.locator('#league-tab');
    await expect(leagueTab).not.toHaveClass(/active/);
  });

  test('clicking a tab updates aria-current', async ({ page }) => {
    const standingsBtn = page.locator('.desktop-tab[data-tab="standings"]');
    await standingsBtn.click();

    await expect(standingsBtn).toHaveAttribute('aria-current', 'page');

    // Previous tab loses aria-current
    const leagueBtn = page.locator('.desktop-tab[data-tab="league"]');
    await expect(leagueBtn).not.toHaveAttribute('aria-current');
  });

  test('only one tab panel is visible at a time', async ({ page }) => {
    const tabs = ['league', 'matchups', 'standings', 'playoff-odds', 'trends'];

    for (const tab of tabs) {
      const btn = page.locator(`.desktop-tab[data-tab="${tab}"]`);
      await btn.click();

      const activePanels = page.locator('.tab-section.active');
      await expect(activePanels).toHaveCount(1);

      const activePanel = page.locator(`#${tab}-tab`);
      await expect(activePanel).toHaveClass(/active/);
    }
  });

  test('cycling through all tabs and back to first works', async ({ page }) => {
    // Go to trends
    await page.locator('.desktop-tab[data-tab="trends"]').click();
    await expect(page.locator('#trends-tab')).toHaveClass(/active/);

    // Go back to league
    await page.locator('.desktop-tab[data-tab="league"]').click();
    await expect(page.locator('#league-tab')).toHaveClass(/active/);
    await expect(page.locator('#trends-tab')).not.toHaveClass(/active/);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. BOTTOM NAV NAVIGATION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Bottom Nav Navigation', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('bottom nav has correct items', async ({ page }) => {
    const navItems = page.locator('.bottom-nav .nav-item');
    await expect(navItems).toHaveCount(4);
  });

  test('clicking bottom nav item switches tab', async ({ page }) => {
    const matchupsNav = page.locator('.bottom-nav .nav-item[data-tab="matchups"]');
    await matchupsNav.click();

    await expect(page.locator('#matchups-tab')).toHaveClass(/active/);
    await expect(page.locator('#league-tab')).not.toHaveClass(/active/);
  });

  test('bottom nav and desktop tabs stay in sync', async ({ page }) => {
    // Click bottom nav "standings"
    await page.locator('.bottom-nav .nav-item[data-tab="standings"]').click();

    // Desktop tab should also be active
    const desktopBtn = page.locator('.desktop-tab[data-tab="standings"]');
    await expect(desktopBtn).toHaveClass(/active/);

    // Bottom nav item should be active
    const navItem = page.locator('.bottom-nav .nav-item[data-tab="standings"]');
    await expect(navItem).toHaveClass(/active/);

    // Now click desktop tab "league" — bottom nav should sync
    await page.locator('.desktop-tab[data-tab="league"]').click();

    const leagueNav = page.locator('.bottom-nav .nav-item[data-tab="league"]');
    await expect(leagueNav).toHaveClass(/active/);

    const standingsNav = page.locator('.bottom-nav .nav-item[data-tab="standings"]');
    await expect(standingsNav).not.toHaveClass(/active/);
  });

  test('only one bottom nav item is active at a time', async ({ page }) => {
    const tabs = ['league', 'matchups', 'standings', 'trends'];

    for (const tab of tabs) {
      await page.locator(`.bottom-nav .nav-item[data-tab="${tab}"]`).click();
      const activeItems = page.locator('.bottom-nav .nav-item.active');
      await expect(activeItems).toHaveCount(1);
    }
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. SWITCHAB FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('switchTab API', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('switchTab is available globally', async ({ page }) => {
    const exists = await page.evaluate(() => typeof window.switchTab === 'function');
    expect(exists).toBe(true);
  });

  test('switchTab with invalid tab name does not crash', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));

    await page.evaluate(() => switchTab('nonexistent-tab'));

    expect(errors).toHaveLength(0);
  });

  test('switchTab programmatically updates all UI elements', async ({ page }) => {
    await page.evaluate(() => switchTab('trends'));

    await expect(page.locator('#trends-tab')).toHaveClass(/active/);
    await expect(page.locator('.desktop-tab[data-tab="trends"]')).toHaveClass(/active/);
    await expect(page.locator('.bottom-nav .nav-item[data-tab="trends"]')).toHaveClass(/active/);
  });

  test('rapid tab switching does not corrupt state', async ({ page }) => {
    await page.evaluate(() => {
      switchTab('matchups');
      switchTab('standings');
      switchTab('trends');
      switchTab('league');
    });

    const activePanels = page.locator('.tab-section.active');
    await expect(activePanels).toHaveCount(1);
    await expect(page.locator('#league-tab')).toHaveClass(/active/);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 4. SERVICE WORKER CACHE COMPLETENESS
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Service Worker Cache', () => {
  test('service worker caches design-tokens.css', () => {
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );
    expect(assetManifest.precache_paths).toContain('./design-tokens.css');
  });

  test('service worker does not precache inline theme-init.js', () => {
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );
    expect(assetManifest.precache_paths).not.toContain('./theme-init.js');
  });

  test('service worker caches icon.svg', () => {
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );
    expect(assetManifest.precache_paths).toContain('./icon.svg');
  });

  test('precache_paths has no duplicates', () => {
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );
    const assets = assetManifest.precache_paths;
    const unique = new Set(assets);
    expect(assets.length).toBe(unique.size);
  });

  test('service worker has stale-while-revalidate for JSON', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    expect(sw).toContain('.json');
    expect(sw).toContain('DATA_CACHE_NAME');
    expect(sw).toContain('event.waitUntil(networkFetch');
  });

  test('service worker has offline fallback HTML', () => {
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    expect(sw).toContain('OFFLINE_HTML');
    expect(sw).toContain("You're Offline");
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. ACCESSIBILITY STRUCTURE
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Accessibility Structure', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('all tab panels have role=tabpanel', async ({ page }) => {
    const panels = page.locator('.tab-section');
    const count = await panels.count();

    for (let i = 0; i < count; i++) {
      await expect(panels.nth(i)).toHaveAttribute('role', 'tabpanel');
    }
  });

  test('all tab panels have aria-label', async ({ page }) => {
    const panels = page.locator('.tab-section');
    const count = await panels.count();

    for (let i = 0; i < count; i++) {
      const label = await panels.nth(i).getAttribute('aria-label');
      expect(label).toBeTruthy();
    }
  });

  test('desktop tabs have aria-label', async ({ page }) => {
    const tabs = page.locator('.desktop-tab');
    const count = await tabs.count();

    for (let i = 0; i < count; i++) {
      const label = await tabs.nth(i).getAttribute('aria-label');
      expect(label).toBeTruthy();
    }
  });

  test('header has role=banner', async ({ page }) => {
    const header = page.locator('header[role="banner"]');
    await expect(header).toHaveCount(1);
  });

  test('navigation has role=navigation', async ({ page }) => {
    const nav = page.locator('nav[role="navigation"]');
    await expect(nav).toHaveCount(1);
  });

  test('accent bar is aria-hidden', async ({ page }) => {
    const bar = page.locator('.app-accent-bar');
    await expect(bar).toHaveAttribute('aria-hidden', 'true');
  });

  test('page has lang attribute', async ({ page }) => {
    const lang = await page.locator('html').getAttribute('lang');
    expect(lang).toBe('en');
  });

  test('page has meta viewport', async ({ page }) => {
    const viewport = page.locator('meta[name="viewport"]');
    await expect(viewport).toHaveCount(1);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. THEME + TAB INTERACTION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Theme and Tab Interaction', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('switching tabs after applying a theme preserves theme', async ({ page }) => {
    // Apply avalanche theme
    await page.evaluate(() => {
      window.TeamThemes.applyTheme('avalanche');
      window.TeamThemes.setStoredTeam('avalanche');
    });

    const themeBefore = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );

    // Switch tabs
    await page.locator('.desktop-tab[data-tab="standings"]').click();
    await page.locator('.desktop-tab[data-tab="league"]').click();

    const themeAfter = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );

    expect(themeAfter).toBe(themeBefore);
  });

  test('team picker button remains functional after tab switches', async ({ page }) => {
    // Switch to standings and back
    await page.locator('.desktop-tab[data-tab="standings"]').click();
    await page.locator('.desktop-tab[data-tab="league"]').click();

    // Team picker trigger should still work
    const trigger = page.locator('.team-picker-trigger');
    await expect(trigger).toBeVisible();
    await trigger.click();

    const modal = page.locator('.team-picker-modal.open');
    await expect(modal).toBeVisible();
  });

  test('social reactions persist after tab switches', async ({ page }) => {
    // Add a reaction
    const reactionBtn = page.locator('.reaction-btn').first();
    await reactionBtn.click();
    await page.waitForTimeout(200);

    const emojiBtn = page.locator('.emoji-btn').first();
    await emojiBtn.click();
    await page.waitForTimeout(200);

    // Check reaction count exists
    const countBefore = await page.locator('.reaction-count').count();
    expect(countBefore).toBeGreaterThan(0);

    // Switch tabs and come back
    await page.locator('.desktop-tab[data-tab="standings"]').click();
    await page.locator('.desktop-tab[data-tab="league"]').click();

    // Reaction counts should still be there
    const countAfter = await page.locator('.reaction-count').count();
    expect(countAfter).toBe(countBefore);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 7. LOCALSTORAGE RESILIENCE
// ═══════════════════════════════════════════════════════════════════════════

test.describe('LocalStorage Resilience', () => {
  test('app loads when localStorage is disabled', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));

    // Disable localStorage before loading
    await page.addInitScript(() => {
      Object.defineProperty(window, 'localStorage', {
        get() {
          throw new DOMException('Storage disabled', 'SecurityError');
        }
      });
    });

    const url = 'file://' + path.resolve(__dirname, '..', FIXTURE);
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(500);

    // Should not throw any uncaught errors
    expect(errors).toHaveLength(0);

    // TeamThemes should still be available
    const exists = await page.evaluate(() => typeof window.TeamThemes === 'object');
    expect(exists).toBe(true);
  });

  test('theme-init handles missing localStorage gracefully', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));

    // Set corrupt data
    await page.addInitScript(() => {
      try {
        localStorage.setItem('nhl_fan_team_css', 'not-valid-json{{{');
      } catch(e) {}
    });

    await loadFixture(page);
    expect(errors).toHaveLength(0);
  });

  test('social reactions handle corrupt localStorage', async ({ page }) => {
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));

    await page.addInitScript(() => {
      try {
        localStorage.setItem('hockey_reactions', 'corrupted-data!!!');
      } catch(e) {}
    });

    await loadFixture(page);
    expect(errors).toHaveLength(0);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 8. PWA MANIFEST VALIDATION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('PWA Manifest Deep Validation', () => {
  test('manifest has proper display mode', () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8')
    );
    expect(['standalone', 'minimal-ui', 'fullscreen']).toContain(manifest.display);
  });

  test('manifest has theme_color matching app', () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8')
    );
    expect(manifest.theme_color).toBeTruthy();
    expect(manifest.background_color).toBeTruthy();
  });

  test('manifest start_url is set', () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8')
    );
    expect(manifest.start_url).toBeTruthy();
  });

  test('manifest has at least one icon', () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8')
    );
    expect(manifest.icons).toBeTruthy();
    expect(manifest.icons.length).toBeGreaterThan(0);
  });

  test('manifest icons have required fields', () => {
    const manifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8')
    );
    for (const icon of manifest.icons) {
      expect(icon.src).toBeTruthy();
      expect(icon.type).toBeTruthy();
    }
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 9. VISUAL REGRESSION GUARDS
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Visual Regression Guards', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('matchup cards have consistent border-radius', async ({ page }) => {
    const cards = page.locator('.matchup-card');
    const count = await cards.count();

    for (let i = 0; i < count; i++) {
      const radius = await cards.nth(i).evaluate(el =>
        getComputedStyle(el).borderRadius
      );
      expect(radius).toBeTruthy();
      expect(radius).not.toBe('0px');
    }
  });

  test('body has dark background', async ({ page }) => {
    const bg = await page.evaluate(() =>
      getComputedStyle(document.body).backgroundColor
    );
    // Should be a dark color (r, g, b values low)
    const match = bg.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
    if (match) {
      const [, r, g, b] = match.map(Number);
      // Dark theme: average < 80
      expect((r + g + b) / 3).toBeLessThan(80);
    }
  });

  test('accent bar spans full width', async ({ page }) => {
    const bar = page.locator('.app-accent-bar');
    const box = await bar.boundingBox();
    expect(box).toBeTruthy();
    expect(box.width).toBeGreaterThan(100);
    expect(box.height).toBeLessThan(10);
  });

  test('no horizontal overflow on default viewport', async ({ page }) => {
    const overflow = await page.evaluate(() => {
      return document.documentElement.scrollWidth > document.documentElement.clientWidth;
    });
    expect(overflow).toBe(false);
  });
});
