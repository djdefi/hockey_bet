import { test, expect } from '@playwright/test';
import { execFileSync } from 'node:child_process';

test.use({ serviceWorkers: 'block', contextOptions: { reducedMotion: 'reduce' } });

for (const mode of ['offseason', 'offseason-failure']) {
  test(`${mode}: team briefs lead, sources stay dated, and history remains separate`, async ({ page }, testInfo) => {
    const html = execFileSync('bundle', ['exec', 'ruby', 'e2e/render-graphics-fixture.rb', mode], { encoding: 'utf8' });
    await page.route('**/offseason-fixture.html', route => route.fulfill({ contentType: 'text/html', body: html }));
    await page.goto('/offseason-fixture.html');
    await expect(page.getByRole('heading', { name: 'Offseason team briefs' })).toBeVisible();
    await expect(page.locator('.team-brief')).toHaveCount(2);
    await expect(page.locator('.season-history')).not.toHaveAttribute('open');
    await expect(page.locator('.hero-champ')).toBeHidden();
    await expect(page.locator('.brief-story__meta time').first()).toHaveAttribute('datetime', '2026-09-05T16:00:00Z');
    await expect(page.locator('.brief-story h4 a').first()).toHaveAttribute('href', 'https://www.nhl.com/news/test-fixture-bos');
    await expect(page.locator('.brief-story__summary').first()).toContainText('Fixture publisher brief');
    if (mode === 'offseason-failure') {
      await expect(page.getByText('Source refresh failed. Showing previously fetched reports.')).toBeVisible();
      await expect(page.getByText("Unable to load this team's news. Read the official team feed below.")).toBeVisible();
      await expect(page.locator('[data-brief-team="MTL"] .brief-source')).toBeVisible();
      await expect(page.locator('[data-brief-team="MTL"] .brief-fetched')).toHaveCount(0);
    }
    await page.screenshot({ path: testInfo.outputPath(`${mode}.png`), fullPage: true });
    await page.getByLabel('Team', { exact: true }).selectOption('MTL');
    await expect(page.locator('[data-brief-team="BOS"]')).toBeHidden();
    await expect(page.locator('[data-brief-team="MTL"]')).toBeVisible();
    await page.getByLabel('Team', { exact: true }).selectOption('');
    await expect(page.locator('[data-brief-team="BOS"]')).toBeVisible();
    await page.locator('.season-history > summary').click();
    await expect(page.locator('.hero-champ')).toBeVisible();
    await expect(page.locator('.season-history > .season-note')).toContainText('not current-season rankings');
    for (const tab of ['standings', 'playoff-odds', 'matchups', 'trends']) {
      await page.locator(`.desktop-tab[data-tab="${tab}"], .nav-item[data-tab="${tab}"]`).filter({ visible: true }).click();
      await expect(page.locator(`#${tab}-tab > .season-note`)).toBeVisible();
      expect(await page.evaluate(() => window.scrollY)).toBe(0);
    }
    await page.locator('.desktop-tab[data-tab="league"], .nav-item[data-tab="league"]').filter({ visible: true }).click();
    for (const width of [320, 768, 1280]) {
      await page.setViewportSize({ width, height: 900 });
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    }
  });
}
