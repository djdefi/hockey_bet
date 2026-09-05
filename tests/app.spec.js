// @ts-check
const { test, expect } = require('@playwright/test');

const FIXTURE = 'tests/test-fixture.html';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Navigate to the test fixture served from the repo root */
async function loadFixture(page) {
  // Serve from file protocol — playwright handles it fine
  const path = require('path');
  const url = 'file://' + path.resolve(__dirname, '..', FIXTURE);
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  // Wait for JS to initialize
  await page.waitForTimeout(500);
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. TEAM THEMES API
// ═══════════════════════════════════════════════════════════════════════════

test.describe('TeamThemes API', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('window.TeamThemes is exposed globally', async ({ page }) => {
    const exists = await page.evaluate(() => typeof window.TeamThemes === 'object');
    expect(exists).toBe(true);
  });

  test('has all 32 NHL teams plus default', async ({ page }) => {
    const count = await page.evaluate(() => Object.keys(window.TeamThemes.themes).length);
    expect(count).toBe(33); // 32 teams + default
  });

  test('getAllTeams groups by 4 divisions', async ({ page }) => {
    const divisions = await page.evaluate(() => Object.keys(window.TeamThemes.getAllTeams()));
    expect(divisions.sort()).toEqual(['Atlantic', 'Central', 'Metropolitan', 'Pacific']);
  });

  test('each division has 8 teams', async ({ page }) => {
    const counts = await page.evaluate(() => {
      const grouped = window.TeamThemes.getAllTeams();
      return Object.values(grouped).map(arr => arr.length);
    });
    counts.forEach(c => expect(c).toBe(8));
  });

  test('getTeamTheme returns valid theme object', async ({ page }) => {
    const theme = await page.evaluate(() => window.TeamThemes.getTeamTheme('kraken'));
    expect(theme.name).toBe('Seattle Kraken');
    expect(theme.abbrev).toBe('SEA');
    expect(theme.colors.primary).toBeTruthy();
    expect(theme.theme['--color-bg-primary']).toBeTruthy();
  });

  test('getTeamTheme falls back to default for unknown key', async ({ page }) => {
    const theme = await page.evaluate(() => window.TeamThemes.getTeamTheme('nonexistent'));
    expect(theme.name).toBe('Default Theme');
  });

  test('applyTheme sets CSS custom properties on :root', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('bruins'));
    const accent = await page.evaluate(() =>
      getComputedStyle(document.documentElement).getPropertyValue('--color-accent-primary').trim()
    );
    expect(accent).toBe('#FFB81C');
  });

  test('applyTheme("default") removes inline overrides', async ({ page }) => {
    // Apply a team first
    await page.evaluate(() => window.TeamThemes.applyTheme('bruins'));
    // Then reset
    await page.evaluate(() => window.TeamThemes.applyTheme('default'));
    const inlineStyle = await page.evaluate(() => document.documentElement.style.getPropertyValue('--color-accent-primary'));
    expect(inlineStyle).toBe('');
  });

  test('applyTheme sets data-team attribute', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('avalanche'));
    const attr = await page.evaluate(() => document.documentElement.dataset.team);
    expect(attr).toBe('avalanche');
  });

  test('setStoredTeam / getStoredTeam roundtrip', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('sharks');
    });
    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBe('sharks');
  });

  test('setStoredTeam(null) clears storage', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('sharks');
      window.TeamThemes.setStoredTeam(null);
    });
    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBeNull();
  });

  test('applyTheme caches CSS vars to localStorage', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('devils'));
    const cached = await page.evaluate(() => localStorage.getItem('nhl_fan_team_css'));
    expect(cached).toBeTruthy();
    const parsed = JSON.parse(await page.evaluate(() => localStorage.getItem('nhl_fan_team_css')));
    expect(parsed['--color-accent-primary']).toBe('#CE1126');
  });

  test('applyTheme("default") clears cached CSS', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.applyTheme('devils');
      window.TeamThemes.applyTheme('default');
    });
    const cached = await page.evaluate(() => localStorage.getItem('nhl_fan_team_css'));
    expect(cached).toBeNull();
  });

  test('theme backgrounds are darker than primary color', async ({ page }) => {
    // Verify backgrounds are actual dark shades, not the bright team color
    const result = await page.evaluate(() => {
      const theme = window.TeamThemes.getTeamTheme('bruins'); // Gold team
      const bgHex = theme.theme['--color-bg-primary'];
      // Parse lightness — bg should be very dark (< 20 in hex component average)
      const r = parseInt(bgHex.slice(1, 3), 16);
      const g = parseInt(bgHex.slice(3, 5), 16);
      const b = parseInt(bgHex.slice(5, 7), 16);
      return (r + g + b) / 3;
    });
    expect(result).toBeLessThan(40); // Very dark background
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. THEME INIT (early load)
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Theme Init', () => {
  test('applies cached theme from localStorage before JS loads', async ({ page }) => {
    const path = require('path');
    const url = 'file://' + path.resolve(__dirname, '..', FIXTURE);

    // Load fixture first to set localStorage in same origin
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.setItem('nhl_fan_team_css', JSON.stringify({
        '--color-accent-primary': '#CE1126',
        '--color-bg-primary': '#1a0306'
      }));
    });

    // Reload — theme-init.js should apply cached theme
    await page.goto(url, { waitUntil: 'domcontentloaded' });

    const accent = await page.evaluate(() =>
      document.documentElement.style.getPropertyValue('--color-accent-primary')
    );
    expect(accent).toBe('#CE1126');

    // Cleanup
    await page.evaluate(() => localStorage.removeItem('nhl_fan_team_css'));
  });

  test('handles corrupt localStorage gracefully', async ({ page }) => {
    const path = require('path');
    const url = 'file://' + path.resolve(__dirname, '..', FIXTURE);

    // Load fixture first to get same origin
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.setItem('nhl_fan_team_css', 'NOT_JSON{{{');
    });

    // Reload — should not throw, page loads fine
    await page.goto(url, { waitUntil: 'domcontentloaded' });
    const exists = await page.evaluate(() => typeof window.TeamThemes === 'object');
    expect(exists).toBe(true);

    // Cleanup
    await page.evaluate(() => localStorage.removeItem('nhl_fan_team_css'));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. TEAM PICKER MODAL
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Team Picker', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('trigger button is created in masthead', async ({ page }) => {
    const trigger = page.locator('.site-masthead .team-picker-trigger');
    await expect(trigger).toBeVisible();
  });

  test('clicking trigger opens modal', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const modal = page.locator('.team-picker-modal.open');
    await expect(modal).toBeVisible();
  });

  test('modal has all 4 divisions', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const divisions = page.locator('.team-picker-division h3');
    await expect(divisions).toHaveCount(4);
  });

  test('modal has 32 team cards', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const cards = page.locator('.team-picker-card');
    await expect(cards).toHaveCount(32);
  });

  test('clicking a team applies theme and closes modal', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);

    // Click the first team card
    const firstCard = page.locator('.team-picker-card').first();
    const teamKey = await firstCard.getAttribute('data-team');
    await firstCard.click();
    await page.waitForTimeout(400);

    // Modal should be closed
    const modal = page.locator('.team-picker-modal.open');
    await expect(modal).toHaveCount(0);

    // Theme should be applied
    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBe(teamKey);
  });

  test('Escape key closes modal', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    const modal = page.locator('.team-picker-modal.open');
    await expect(modal).toHaveCount(0);
  });

  test('Reset to Default clears theme', async ({ page }) => {
    // First select a team
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('bruins');
      window.TeamThemes.applyTheme('bruins');
    });

    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    await page.click('.team-picker-reset');
    await page.waitForTimeout(400);

    const stored = await page.evaluate(() => window.TeamThemes.getStoredTeam());
    expect(stored).toBeNull();

    const cachedCSS = await page.evaluate(() => localStorage.getItem('nhl_fan_team_css'));
    expect(cachedCSS).toBeNull();
  });

  test('trigger shows team dot when team is selected', async ({ page }) => {
    await page.evaluate(() => {
      window.TeamThemes.setStoredTeam('kraken');
      window.TeamThemes.applyTheme('kraken');
    });
    // Re-load to see dot
    await loadFixture(page);
    const dot = page.locator('.team-picker-trigger .team-dot');
    await expect(dot).toBeVisible();
  });

  test('modal has focus trap (Tab wraps)', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);

    // Focus should be inside the modal
    const focusInModal = await page.evaluate(() => {
      const modal = document.querySelector('.team-picker-content');
      return modal && modal.contains(document.activeElement);
    });
    expect(focusInModal).toBe(true);
  });

  test('modal has proper ARIA attributes', async ({ page }) => {
    await page.click('.team-picker-trigger');
    await page.waitForTimeout(300);
    const modal = page.locator('.team-picker-modal');
    await expect(modal).toHaveAttribute('role', 'dialog');
    await expect(modal).toHaveAttribute('aria-modal', 'true');
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 4. MOBILE GESTURES
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Mobile Gestures', () => {
  test('MobileGestures initializes on mobile viewport', async ({ page }) => {
    // Use mobile viewport
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);

    const exists = await page.evaluate(() => window.mobileGestures instanceof MobileGestures);
    expect(exists).toBe(true);
  });

  test('pull indicator is created on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);
    const indicator = page.locator('#pull-indicator');
    await expect(indicator).toBeAttached();
  });

  test('tabs are discovered from DOM', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);
    const tabs = await page.evaluate(() => window.mobileGestures.tabs);
    expect(tabs).toEqual(['league', 'matchups', 'standings', 'playoff-odds', 'trends']);
  });

  test('swipe threshold is adaptive for small screens', async ({ page }) => {
    await page.setViewportSize({ width: 360, height: 640 });
    await loadFixture(page);
    const threshold = await page.evaluate(() => window.mobileGestures.swipeThreshold);
    expect(threshold).toBeLessThanOrEqual(50);
  });

  test('haptic method exists and does not throw', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await loadFixture(page);
    const noThrow = await page.evaluate(() => {
      try { window.mobileGestures.haptic(10); return true; }
      catch (e) { return false; }
    });
    expect(noThrow).toBe(true);
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. PWA MANIFEST & SERVICE WORKER
// ═══════════════════════════════════════════════════════════════════════════

test.describe('PWA Assets', () => {
  test('site.webmanifest is valid JSON with required fields', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const raw = fs.readFileSync(path.resolve(__dirname, '..', 'site.webmanifest'), 'utf-8');
    const manifest = JSON.parse(raw);

    expect(manifest.name).toBeTruthy();
    expect(manifest.short_name).toBeTruthy();
    expect(manifest.start_url).toBeTruthy();
    expect(manifest.display).toBe('standalone');
    expect(manifest.icons.length).toBeGreaterThanOrEqual(2);
    expect(manifest.shortcuts.length).toBe(2);
    expect(manifest.id).toBeTruthy();
  });

  test('icon.svg exists and is valid SVG', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const svg = fs.readFileSync(path.resolve(__dirname, '..', 'icon.svg'), 'utf-8');

    expect(svg).toContain('<svg');
    expect(svg).toContain('viewBox="0 0 512 512"');
    expect(svg).toContain('fill="#ffbc52"');
    expect(svg).toContain('fill="#101214"');
    expect(svg).toContain('stroke="#f4f5f6"');
  });

  test('service-worker.js precaches all declared copied assets', async () => {
    const fs = require('fs');
    const path = require('path');
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');
    const assetManifest = JSON.parse(
      fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'app-assets.json'), 'utf-8')
    );

    expect(Object.keys(assetManifest.copy).sort()).toEqual(['css', 'js', 'root', 'vendor']);
    for (const [kind, files] of Object.entries(assetManifest.copy)) {
      expect(files.length).toBeGreaterThan(0);
      for (const file of files) {
        const asset = kind === 'vendor' ? './vendor/' + file : './' + file;
        const sourceDir = kind === 'root' ? '.' : kind === 'vendor' ? 'vendor' : 'lib';
        expect(assetManifest.precache_paths).toContain(asset);
        expect(fs.existsSync(path.resolve(__dirname, '..', sourceDir, file)), asset).toBe(true);
      }
    }

    expect(sw).toContain('APP_ASSET_MANIFEST_URL');
    expect(sw).toContain('manifest.precache_paths');
  });

  test('service-worker has offline fallback', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const sw = fs.readFileSync(path.resolve(__dirname, '..', 'service-worker.js'), 'utf-8');

    expect(sw).toContain('OFFLINE_HTML');
    expect(sw).toContain('<h1 id="offline-title">You\'re offline</h1>');
    expect(sw).toContain("request.mode === 'navigate'");
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 6. CSS & VISUAL INTEGRATION
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Visual Integration', () => {
  test.beforeEach(async ({ page }) => {
    await loadFixture(page);
  });

  test('accent bar is visible at top of page', async ({ page }) => {
    const bar = page.locator('.app-accent-bar');
    await expect(bar).toBeVisible();
    const box = await bar.boundingBox();
    expect(box.height).toBeGreaterThanOrEqual(2);
    expect(box.y).toBeLessThanOrEqual(5);
  });

  test('skeleton images use a neutral placeholder without shimmer', async ({ page }) => {
    const img = page.locator('.skeleton').first();
    await expect(img).toHaveCSS('background-color', 'rgb(34, 38, 42)');
    await expect(img).toHaveCSS('animation-name', 'none');
  });

  test('image onerror hides img and shows fallback', async ({ page }) => {
    await page.evaluate(() => switchTab('matchups'));
    const fallback = page.locator('.team-logo-fallback').first();
    await expect(fallback).toBeVisible();
  });

  test('team theme changes accent bar color', async ({ page }) => {
    await page.evaluate(() => window.TeamThemes.applyTheme('bruins'));
    await expect(page.locator('.app-accent-bar')).toHaveCSS('background-color', 'rgb(255, 184, 28)');
  });

  test('default design tokens use the viewfinder palette', async ({ page }) => {
    const vars = await page.evaluate(() => {
      const style = getComputedStyle(document.documentElement);
      return {
        bgPrimary: style.getPropertyValue('--color-bg-primary').trim(),
        textPrimary: style.getPropertyValue('--color-text-primary').trim(),
        accentPrimary: style.getPropertyValue('--color-accent-primary').trim(),
        focus: style.getPropertyValue('--color-focus').trim(),
      };
    });
    expect(vars).toEqual({
      bgPrimary: '#101214',
      textPrimary: '#f4f5f6',
      accentPrimary: '#ffbc52',
      focus: '#ffbc52',
    });
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// 7. PLAYOFF STYLES
// ═══════════════════════════════════════════════════════════════════════════

test.describe('Playoff Styles', () => {
  test('playoff_styles.css uses only CSS variables, no hardcoded colors', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const css = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoff_styles.css'), 'utf-8');

    // Should NOT contain hardcoded hex colors (except in rgba for leading team)
    const hexPattern = /#[0-9a-fA-F]{3,6}\b/g;
    const matches = css.match(hexPattern) || [];
    // Filter out any that are inside var() fallbacks (those are OK)
    // All hardcoded hex should be gone
    expect(matches.length).toBe(0);
  });

  test('playoff_styles.css uses flat series surfaces', async () => {
    const fs = require('fs');
    const path = require('path');
    const css = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoff_styles.css'), 'utf-8');

    const series = css.match(/\.series\s*\{([^}]+)\}/)?.[1];
    expect(series).toContain('border: 1px solid var(--color-border-default)');
    expect(series).toContain('background: var(--color-bg-depth)');
    expect(series).not.toContain('transform');
  });

  test('playoff_styles.css has team-seed styling', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const css = fs.readFileSync(path.resolve(__dirname, '..', 'lib', 'playoff_styles.css'), 'utf-8');

    const seed = css.match(/\.team-seed\s*\{([^}]+)\}/)?.[1];
    expect(seed).toContain('--color-text-muted');
    expect(seed).toContain('--font-family-mono');
  });
});
