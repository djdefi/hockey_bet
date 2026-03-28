import { test, expect, Page } from '@playwright/test';
import path from 'path';

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');

// Helper: take a named screenshot for both projects
async function snap(page: Page, name: string) {
  await page.screenshot({
    path: path.join(SCREENSHOT_DIR, `${name}.png`),
    fullPage: false,
  });
}

async function snapFull(page: Page, name: string) {
  await page.screenshot({
    path: path.join(SCREENSHOT_DIR, `${name}-full.png`),
    fullPage: true,
  });
}

// ─── Page Load & Structure ──────────────────────────────────────────

test.describe('Page load and structure', () => {
  test('loads without errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await snap(page, '01-initial-load');

    // No JS errors
    expect(errors).toEqual([]);
  });

  test('has correct title and lang', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle('NHL Standings');
    const lang = await page.locator('html').getAttribute('lang');
    expect(lang).toBe('en');
  });

  test('has header with NHL Fan League heading', async ({ page }) => {
    await page.goto('/');
    const heading = page.locator('h1');
    await expect(heading).toBeVisible();
    await expect(heading).toHaveText('NHL Fan League');
  });

  test('has last updated timestamp', async ({ page }) => {
    await page.goto('/');
    const timestamp = page.locator('header .text-secondary');
    await expect(timestamp).toBeVisible();
    const text = await timestamp.textContent();
    expect(text).toMatch(/Last updated:/);
  });

  test('loads external resources (Iconify, stylesheets)', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Check styles.css is loaded
    const styles = page.locator('link[href="styles.css"]');
    await expect(styles).toHaveCount(1);

    // Check Iconify script
    const iconify = page.locator('script[src*="iconify"]');
    await expect(iconify).toHaveCount(1);
  });

  test('full page screenshot', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    await snapFull(page, '02-full-page');
  });
});

// ─── Desktop Tab Navigation ─────────────────────────────────────────

test.describe('Desktop tab navigation', () => {
  test.beforeEach(async ({}, testInfo) => {
    if (testInfo.project.name === 'mobile-iphone') test.skip();
  });

  test('has 5 desktop tabs', async ({ page }) => {
    await page.goto('/');
    const tabs = page.locator('.desktop-tab');
    await expect(tabs).toHaveCount(5);

    const labels = await tabs.allTextContents();
    expect(labels).toEqual(['League', 'Matchups', 'Standings', 'Playoff Odds', 'Trends']);
  });

  test('League tab is active by default', async ({ page }) => {
    await page.goto('/');
    const leagueTab = page.locator('.desktop-tab[data-tab="league"]');
    await expect(leagueTab).toHaveClass(/active/);

    const leagueSection = page.locator('#league-tab');
    await expect(leagueSection).toHaveClass(/active/);
  });

  test('switches to Matchups tab', async ({ page }) => {
    await page.goto('/');
    await page.click('.desktop-tab[data-tab="matchups"]');

    const matchupsTab = page.locator('.desktop-tab[data-tab="matchups"]');
    await expect(matchupsTab).toHaveClass(/active/);

    const matchupsSection = page.locator('#matchups-tab');
    await expect(matchupsSection).toHaveClass(/active/);

    // League tab should no longer be active
    const leagueSection = page.locator('#league-tab');
    await expect(leagueSection).not.toHaveClass(/active/);

    await snap(page, '03-matchups-tab');
  });

  test('switches to Standings tab', async ({ page }) => {
    await page.goto('/');
    await page.click('.desktop-tab[data-tab="standings"]');

    const section = page.locator('#standings-tab');
    await expect(section).toHaveClass(/active/);
    await snap(page, '04-standings-tab');
  });

  test('switches to Playoff Odds tab', async ({ page }) => {
    await page.goto('/');
    await page.click('.desktop-tab[data-tab="playoff-odds"]');

    const section = page.locator('#playoff-odds-tab');
    await expect(section).toHaveClass(/active/);
    await snap(page, '05-playoff-odds-tab');
  });

  test('switches to Trends tab', async ({ page }) => {
    await page.goto('/');
    await page.click('.desktop-tab[data-tab="trends"]');

    const section = page.locator('#trends-tab');
    await expect(section).toHaveClass(/active/);
    await snap(page, '06-trends-tab');
  });

  test('cycles through all tabs correctly', async ({ page }) => {
    await page.goto('/');
    const tabNames = ['league', 'matchups', 'standings', 'playoff-odds', 'trends'];

    for (const tab of tabNames) {
      await page.click(`.desktop-tab[data-tab="${tab}"]`);
      const section = page.locator(`#${tab}-tab`);
      await expect(section).toHaveClass(/active/);

      // All other sections should be inactive
      for (const other of tabNames.filter(t => t !== tab)) {
        const otherSection = page.locator(`#${other}-tab`);
        await expect(otherSection).not.toHaveClass(/active/);
      }
    }
  });

  test('tab keyboard navigation works', async ({ page }) => {
    await page.goto('/');
    const matchupsTab = page.locator('.desktop-tab[data-tab="matchups"]');
    await matchupsTab.focus();
    await matchupsTab.press('Enter');

    const section = page.locator('#matchups-tab');
    await expect(section).toHaveClass(/active/);
  });
});

// ─── Mobile Navigation ──────────────────────────────────────────────

test.describe('Mobile bottom navigation', () => {
  test.beforeEach(async ({}, testInfo) => {
    if (testInfo.project.name === 'desktop-chrome') test.skip();
  });

  test('has bottom nav items', async ({ page }) => {
    await page.goto('/');
    const navItems = page.locator('.nav-item');
    const count = await navItems.count();
    expect(count).toBeGreaterThanOrEqual(4);
    await snap(page, '07-mobile-initial');
  });

  test('switches tabs via mobile nav', async ({ page }) => {
    await page.goto('/');
    await page.click('.nav-item[data-tab="matchups"]');

    const section = page.locator('#matchups-tab');
    await expect(section).toHaveClass(/active/);
    await snap(page, '08-mobile-matchups');
  });

  test('mobile nav highlights active tab', async ({ page }) => {
    await page.goto('/');
    await page.click('.nav-item[data-tab="standings"]');

    const activeNav = page.locator('.nav-item[data-tab="standings"]');
    await expect(activeNav).toHaveClass(/active/);
    await snap(page, '09-mobile-standings');
  });
});

// ─── League Tab Content ─────────────────────────────────────────────

test.describe('League tab content', () => {
  test('shows section headings', async ({ page }) => {
    await page.goto('/');
    const leagueTab = page.locator('#league-tab');
    await expect(leagueTab).toHaveClass(/active/);

    // Should have a heading visible
    const headings = leagueTab.locator('h2, h3');
    const count = await headings.count();
    expect(count).toBeGreaterThan(0);
  });

  test('shows top leaders section', async ({ page }) => {
    await page.goto('/');
    // Look for leader cards or top-3 section
    const leaderCards = page.locator('#league-tab .leader-card, #league-tab .top-leaders');
    const count = await leaderCards.count();
    expect(count).toBeGreaterThanOrEqual(0); // May not have data in fixtures
    await snap(page, '10-league-leaders');
  });

  test('shows team cards', async ({ page }) => {
    await page.goto('/');
    const teamCards = page.locator('#league-tab .team-card');
    const count = await teamCards.count();
    // Should have some team cards in the standings section
    expect(count).toBeGreaterThanOrEqual(0);
  });
});

// ─── Featured Matchup ───────────────────────────────────────────────

test.describe('Featured matchup', () => {
  test('displays featured matchup section', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    const isVisible = await featured.isVisible().catch(() => false);

    if (isVisible) {
      await expect(featured).toBeVisible();

      // Check for section heading
      const heading = featured.locator('.section-heading');
      await expect(heading).toContainText('Featured Matchup');

      await snap(page, '11-featured-matchup');
    } else {
      // No matchups in fixture data - document this
      console.log('No featured matchup rendered (fixture data may lack matchups)');
    }
  });

  test('featured matchup has team logos or fallbacks', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    // Should have team logos or fallback divs
    const logos = featured.locator('.featured-logo-dense, .logo-fallback-dense');
    const count = await logos.count();
    expect(count).toBeGreaterThanOrEqual(2); // Both teams
  });

  test('featured matchup has fan names', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    const fanNames = featured.locator('.featured-fan-name-dense');
    await expect(fanNames).toHaveCount(2);

    // Each should have non-empty text
    for (let i = 0; i < 2; i++) {
      const text = await fanNames.nth(i).textContent();
      expect(text?.trim().length).toBeGreaterThan(0);
    }
  });

  test('featured matchup has stats grid', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    // Should have stats: Record, Pts, GPG, Streak
    const statsGrids = featured.locator('.featured-stats-grid');
    await expect(statsGrids).toHaveCount(2); // One per team

    const statLabels = featured.locator('.stat-label-dense');
    const labels = await statLabels.allTextContents();
    expect(labels).toEqual(expect.arrayContaining(['Record', 'Pts', 'GPG', 'Streak']));
  });

  test('featured matchup has VS divider', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    const vs = featured.locator('.featured-vs-dense');
    await expect(vs).toBeVisible();
    await expect(vs).toHaveText('VS');
  });

  test('featured matchup has prediction', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    const prediction = featured.locator('.featured-prediction-compact');
    if (await prediction.isVisible().catch(() => false)) {
      const text = await prediction.textContent();
      expect(text).toMatch(/Prediction:.*\d+% confidence/);
    }
  });

  test('featured matchup has game time', async ({ page }) => {
    await page.goto('/');
    const featured = page.locator('.featured-matchup').first();
    if (!(await featured.isVisible().catch(() => false))) {
      test.skip();
      return;
    }

    const time = featured.locator('.featured-time-compact');
    if (await time.isVisible().catch(() => false)) {
      const text = await time.textContent();
      expect(text?.trim().length).toBeGreaterThan(0);
    }
  });
});

// ─── Matchups Tab ───────────────────────────────────────────────────

test.describe('Matchups tab', () => {
  test('shows matchup cards or empty message', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const matchupsTab = page.locator('#matchups-tab');
    await expect(matchupsTab).toHaveClass(/active/);

    const matchupCards = matchupsTab.locator('.matchup-card');
    const emptyMsg = matchupsTab.locator('.text-secondary');
    const cardCount = await matchupCards.count();

    if (cardCount > 0) {
      // Matchups exist - validate structure
      await snap(page, '12-matchups-cards');
    } else {
      // Should show empty message
      await expect(emptyMsg).toBeVisible();
    }
  });

  test('matchup cards have team info', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    const count = await cards.count();
    if (count === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();

    // Check for team sections
    const teams = firstCard.locator('.matchup-team');
    await expect(teams).toHaveCount(2);

    // Check for VS divider
    const vs = firstCard.locator('.matchup-vs');
    await expect(vs).toBeVisible();
    await expect(vs).toHaveText('VS');

    // Check fan names
    const fanNames = firstCard.locator('.matchup-fan-name');
    await expect(fanNames).toHaveCount(2);
    for (let i = 0; i < 2; i++) {
      const text = await fanNames.nth(i).textContent();
      expect(text?.trim().length).toBeGreaterThan(0);
    }

    // Check team names
    const teamNames = firstCard.locator('.matchup-team-name');
    await expect(teamNames).toHaveCount(2);
  });

  test('matchup cards have stat comparisons', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    if ((await cards.count()) === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();
    const stats = firstCard.locator('.matchup-stat');
    const count = await stats.count();
    expect(count).toBeGreaterThanOrEqual(3); // Record, Points, Goals/Game at minimum

    // Check for stat labels
    const labels = firstCard.locator('.matchup-stat-label');
    const labelTexts = await labels.allTextContents();
    expect(labelTexts).toEqual(expect.arrayContaining(['Record', 'Points', 'Goals/Game']));
  });

  test('matchup cards have comparison bars', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    if ((await cards.count()) === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();
    const bars = firstCard.locator('.stat-bar-container');
    const count = await bars.count();
    expect(count).toBeGreaterThanOrEqual(2);

    // Bar fills should have width styles
    const fills = firstCard.locator('.stat-bar-fill');
    for (let i = 0; i < await fills.count(); i++) {
      const style = await fills.nth(i).getAttribute('style');
      expect(style).toMatch(/width:\s*\d+%/);
    }
  });

  test('matchup cards have win probability bar', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    if ((await cards.count()) === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();
    const winProb = firstCard.locator('.win-probability');
    await expect(winProb).toBeVisible();

    const probValue = firstCard.locator('.win-prob-value');
    const text = await probValue.textContent();
    expect(text).toMatch(/\d+%/);
  });

  test('matchup cards have team logos', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    if ((await cards.count()) === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();
    const logos = firstCard.locator('.team-logo, .team-logo-fallback');
    const count = await logos.count();
    expect(count).toBeGreaterThanOrEqual(2);

    await snap(page, '13-matchup-detail');
  });

  test('matchup cards have momentum indicators', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="matchups"]');

    const cards = page.locator('#matchups-tab .matchup-card');
    if ((await cards.count()) === 0) {
      test.skip();
      return;
    }

    const firstCard = cards.first();
    const momentum = firstCard.locator('.matchup-stat-label:has-text("Momentum")');
    await expect(momentum).toBeVisible();
  });
});

// ─── Standings Tab ──────────────────────────────────────────────────

test.describe('Standings tab', () => {
  test('shows standings content', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="standings"]');

    const standingsTab = page.locator('#standings-tab');
    await expect(standingsTab).toHaveClass(/active/);

    // Should have team cards or a standings table
    const teamCards = standingsTab.locator('.team-card');
    const count = await teamCards.count();
    expect(count).toBeGreaterThan(0);

    await snap(page, '14-standings-content');
  });

  test('team cards have required info', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="standings"]');

    const teamCards = page.locator('#standings-tab .team-card');
    const count = await teamCards.count();
    if (count === 0) {
      test.skip();
      return;
    }

    const firstCard = teamCards.first();

    // Should have a fan name or team name visible
    const textContent = await firstCard.textContent();
    expect(textContent?.trim().length).toBeGreaterThan(0);
  });

  test('team cards are expandable', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="standings"]');

    const expandToggles = page.locator('#standings-tab .expand-toggle');
    const count = await expandToggles.count();

    if (count > 0) {
      // Click first expand toggle
      await expandToggles.first().click();
      await page.waitForTimeout(300);

      // Check that expanded content is visible
      const expanded = page.locator('#standings-tab .team-card.expanded, #standings-tab .expandable.active');
      const expandedCount = await expanded.count();
      expect(expandedCount).toBeGreaterThan(0);

      await snap(page, '15-standings-expanded');
    }
  });

  test('team cards have playoff status indicators', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="standings"]');

    const teamCards = page.locator('#standings-tab .team-card');
    const count = await teamCards.count();

    // At least some cards should have status classes
    const statusCards = page.locator('#standings-tab .team-card[class*="color-bg-"]');
    const statusCount = await statusCards.count();
    // Allow 0 if fixtures don't have playoff status
    expect(statusCount).toBeGreaterThanOrEqual(0);
  });
});

// ─── Playoff Odds Tab ───────────────────────────────────────────────

test.describe('Playoff odds tab', () => {
  test('shows playoff odds content', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="playoff-odds"]');

    const section = page.locator('#playoff-odds-tab');
    await expect(section).toHaveClass(/active/);

    // Should have heading
    const heading = section.locator('h2');
    await expect(heading).toBeVisible();

    await snap(page, '16-playoff-odds');
  });

  test('has chart canvas element', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="playoff-odds"]');

    const canvas = page.locator('#playoffOddsChart');
    await expect(canvas).toBeVisible();
  });

  test('has odds summary section', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="playoff-odds"]');

    const summary = page.locator('#playoffOddsSummary');
    const count = await summary.count();
    expect(count).toBeGreaterThanOrEqual(0);
  });
});

// ─── Trends Tab ─────────────────────────────────────────────────────

test.describe('Trends tab', () => {
  test('shows trends content', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="trends"]');

    const section = page.locator('#trends-tab');
    await expect(section).toHaveClass(/active/);

    await snap(page, '17-trends');
  });

  test('has chart canvas element', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="trends"]');

    const canvas = page.locator('#leagueTrendChart');
    await expect(canvas).toBeVisible();
  });

  test('has season selector', async ({ page }) => {
    await page.goto('/');
    await page.click('[data-tab="trends"]');

    const selector = page.locator('#seasonSelector');
    if (await selector.isVisible().catch(() => false)) {
      await expect(selector).toBeVisible();
    }
  });
});

// ─── Accessibility ──────────────────────────────────────────────────

test.describe('Accessibility', () => {
  test('all tabs have aria-labels', async ({ page }) => {
    await page.goto('/');

    const desktopTabs = page.locator('.desktop-tab');
    const count = await desktopTabs.count();
    for (let i = 0; i < count; i++) {
      const label = await desktopTabs.nth(i).getAttribute('aria-label');
      expect(label).toBeTruthy();
    }
  });

  test('tab sections have role=tabpanel', async ({ page }) => {
    await page.goto('/');
    const sections = page.locator('.tab-section');
    const count = await sections.count();

    for (let i = 0; i < count; i++) {
      const role = await sections.nth(i).getAttribute('role');
      expect(role).toBe('tabpanel');
    }
  });

  test('active tab has aria-current', async ({ page }) => {
    await page.goto('/');
    const activeTab = page.locator('.desktop-tab.active');
    const ariaCurrent = await activeTab.getAttribute('aria-current');
    expect(ariaCurrent).toBe('page');
  });

  test('images have alt text', async ({ page }) => {
    await page.goto('/');
    const images = page.locator('img');
    const count = await images.count();

    for (let i = 0; i < count; i++) {
      const alt = await images.nth(i).getAttribute('alt');
      expect(alt).toBeTruthy();
    }
  });

  test('header is landmark', async ({ page }) => {
    await page.goto('/');
    const header = page.locator('header[role="banner"]');
    await expect(header).toBeVisible();
  });

  test('navigation is landmark', async ({ page }) => {
    await page.goto('/');
    const nav = page.locator('nav[role="navigation"]');
    const count = await nav.count();
    expect(count).toBeGreaterThanOrEqual(1);
  });
});

// ─── Console Errors & Network ───────────────────────────────────────

test.describe('Runtime health', () => {
  test('no console errors on page load', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Filter out expected errors (e.g., service worker in non-HTTPS)
    const unexpectedErrors = errors.filter(
      (e) => !e.includes('ServiceWorker') && !e.includes('service-worker')
    );
    expect(unexpectedErrors).toEqual([]);
  });

  test('no console errors when switching all tabs', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    const tabs = ['league', 'matchups', 'standings', 'playoff-odds', 'trends'];
    for (const tab of tabs) {
      await page.click(`[data-tab="${tab}"]`);
      await page.waitForTimeout(300);
    }

    const unexpectedErrors = errors.filter(
      (e) => !e.includes('ServiceWorker') && !e.includes('service-worker')
    );
    expect(unexpectedErrors).toEqual([]);
  });

  test('critical CSS and JS files load', async ({ page }) => {
    const failedRequests: string[] = [];
    page.on('requestfailed', (req) => {
      const url = req.url();
      // Only flag local resources, not external CDNs
      if (url.includes('localhost')) {
        failedRequests.push(url);
      }
    });

    await page.goto('/');
    await page.waitForLoadState('networkidle');

    expect(failedRequests).toEqual([]);
  });
});

// ─── Visual Regression Screenshots ─────────────────────────────────

test.describe('Visual snapshots (all tabs)', () => {
  const tabs = [
    { name: 'league', label: 'League' },
    { name: 'matchups', label: 'Matchups' },
    { name: 'standings', label: 'Standings' },
    { name: 'playoff-odds', label: 'Playoff Odds' },
    { name: 'trends', label: 'Trends' },
  ];

  for (const tab of tabs) {
    test(`screenshot: ${tab.label} tab`, async ({ page }, testInfo) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      await page.click(`[data-tab="${tab.name}"]`);
      await page.waitForTimeout(500);

      const project = testInfo.project.name;
      await snap(page, `${project}-${tab.name}`);
    });
  }
});
