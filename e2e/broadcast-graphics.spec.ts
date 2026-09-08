import { test, expect } from '@playwright/test';
import { execFileSync } from 'node:child_process';

test.use({ serviceWorkers: 'block' });

const renderFixture = (view: string) => execFileSync(
  'bundle', ['exec', 'ruby', 'e2e/render-graphics-fixture.rb', view], { encoding: 'utf8' }
);

test('face-off graphics keep real fixture identities, measurements and mobile fit', async ({ page }, testInfo) => {
  await page.route('**/graphics-fixture.html', route => route.fulfill({
    contentType: 'text/html', body: renderFixture('matchups')
  }));
  await page.goto('/graphics-fixture.html');
  await expect(page.locator('.featured-matchup')).toBeVisible();
  await expect(page.locator('.featured-team-name-dense')).toHaveText(['Montreal Canadiens', 'Boston Bruins']);
  await expect(page.locator('.featured-vs-dense')).toHaveText('VS');
  for (const logo of await page.locator('.featured-logo-dense').all()) {
    await expect.poll(() => logo.evaluate((image: HTMLImageElement) => image.naturalWidth)).toBeGreaterThan(0);
    await expect(logo).toHaveCSS('background-color', 'rgba(0, 0, 0, 0)');
  }
  expect((await page.locator('.featured-logo-dense').first().boundingBox())?.width).toBeGreaterThanOrEqual(76);
  await page.locator('.featured-matchup').screenshot({ path: testInfo.outputPath('featured-faceoff.png') });
  await page.locator('[data-tab="matchups"]').filter({ visible: true }).click();
  const card = page.locator('.matchup-card').first();
  await expect(card.locator('.matchup-team-name')).toHaveText(['Montreal Canadiens', 'Boston Bruins']);
  await expect(card.locator('.win-prob-label')).toHaveText('Alice win chance');
  await expect(card.locator('.faceoff-mark')).toHaveCSS('animation-iteration-count', '1');
  await expect(card.locator('.faceoff-mark')).toHaveCSS('animation-name', 'broadcast-lock');
  for (const logo of await card.locator('img').all()) {
    await expect.poll(() => logo.evaluate((image: HTMLImageElement) => image.naturalWidth)).toBeGreaterThan(0);
  }
  await expect.poll(() => card.evaluate(element => element.getAnimations({ subtree: true }).length)).toBe(0);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('faceoff.png'), fullPage: true });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await expect(card.locator('.faceoff-mark')).toHaveCSS('animation-name', 'none');
  for (const width of [320, 768, 1024]) {
    await page.setViewportSize({ width, height: 900 });
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  }
});

test('playoff podium, series wins and TBD remain legible with failed external graphics', async ({ page }, testInfo) => {
  await page.route('**/graphics-playoffs.html', route => route.fulfill({
    contentType: 'text/html', body: renderFixture('playoffs')
  }));
  await page.route('https://assets.nhle.com/**', route => route.abort());
  await page.route(/https:\/\/.*iconify.*/, route => route.abort());
  await page.goto('/graphics-playoffs.html');
  await expect(page.locator('.playoff-title-field > svg')).toHaveCSS('animation-name', 'broadcast-lock');
  await expect(page.locator('.fan-podium__step--1 .fan-podium__name')).toHaveText('Alice');
  await expect(page.locator('.fan-podium__step--1 .crest-fallback')).toBeVisible();
  const series = page.locator('.series').first();
  await series.scrollIntoViewIfNeeded();
  await expect(series.locator('.team-logo--placeholder').first()).toHaveText('BOS');
  await expect(series.locator('.team-logo--placeholder').first()).toBeVisible();
  await expect(series.locator('.team-wins')).toHaveText(['2', '1']);
  await expect(series.locator('.dot--won')).toHaveCount(3);
  await expect(page.locator('.team--advanced .team-name')).toHaveText('Toronto Maple Leafs');
  await expect(page.locator('.series--tbd .team-name')).toHaveText(['TBD', 'TBD']);
  await expect(page.locator('.series--tbd .series-status')).toHaveText('Awaiting matchup');
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
  await page.screenshot({ path: testInfo.outputPath('playoff-bracket-fallbacks.png'), fullPage: true });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await expect(page.locator('.playoff-title-field > svg')).toHaveCSS('animation-name', 'none');
});

test('league, odds and standings keep team identity when crests and icons fail', async ({ page }) => {
  await page.route('https://assets.nhle.com/**', route => route.abort());
  await page.route(/https:\/\/.*iconify.*/, route => route.abort());
  await page.goto('/');
  if (await page.locator('.season-history').count()) {
    await page.locator('.season-history > summary').click();
  }
  await expect(page.locator('.crest-stage .crest-fallback')).toBeVisible();
  await expect(page.locator('.crest-stage .crest-fallback')).not.toBeEmpty();
  await page.locator('[data-tab="standings"]').filter({ visible: true }).first().click();
  const team = page.locator('.team-card').first();
  await expect(team.locator('.team-logo-fallback')).toBeVisible();
  await team.click();
  await expect(team).toHaveAttribute('aria-expanded', 'true');
  await page.locator('[data-tab="playoff-odds"]').filter({ visible: true }).click();
  await expect(page.locator('.odds-crest').first()).toContainText(/^[A-Z]{3}$/);
  await expect(page.locator('.odds-fan').first()).not.toBeEmpty();
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});
