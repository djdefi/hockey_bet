import { test, expect } from '@playwright/test';

test.use({ serviceWorkers: 'block' });

test('division streams trace a real route without inventing later-round winners', async ({ page }, testInfo) => {
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/');
  await page.locator('[data-tab="playoff-odds"]').filter({ visible: true }).click();
  await expect(page.getByRole('heading', { name: 'Every road ends at the Cup.' })).toBeVisible();
  await expect(page.locator('.cup-team')).toHaveCount(16);
  const team = page.locator('.cup-team').first();
  const abbrev = await team.getAttribute('data-cup-team');
  if (!abbrev) throw new Error('Qualified team is missing its abbreviation');
  await team.click();
  await expect(team).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('.cup-streams .is-route')).toHaveCount(1);
  await expect(page.locator('.cup-final-streams .is-route')).toHaveCount(1);
  await expect(page.locator('#cup-route')).toContainText('First round:');
  await expect(page.locator('#cup-route')).toContainText('Second round:');
  await expect(page.locator('#cup-route')).toContainText('Stanley Cup Final');
  await page.screenshot({ path: testInfo.outputPath('cup-flow.png'), fullPage: true });

  await page.locator('.cup-standings > summary').click();
  await expect(page.locator('.cup-divisions button')).toHaveCount(32);
  const outside = page.locator('.cup-divisions button').filter({ hasText: 'Outside field' }).first();
  await outside.click();
  await expect(page.locator('#cup-route')).toContainText("No route in today's bracket");
  await expect(page.locator('.cup-streams .is-route')).toHaveCount(0);
  await page.locator('#cup-team').selectOption('');
  await expect(page.locator('.cup-field')).not.toHaveClass(/has-selection/);
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);

  const scroll = page.getByRole('region', { name: /Road to the Cup flow/ });
  await scroll.focus();
  await page.keyboard.press('End');
  await page.locator('.cup-model-odds > summary').click();
  await expect(page.locator('#playoffOddsChart')).toBeVisible();
  await expect(page.locator('.odds-table')).toBeVisible();
  expect(errors).toEqual([]);
});
