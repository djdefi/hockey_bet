import { test, expect, Page } from '@playwright/test';

test.use({ serviceWorkers: 'block', reducedMotion: 'reduce' });

async function selectView(page: Page, name: string) {
  await page.locator(`.desktop-tab[data-tab="${name}"], .nav-item[data-tab="${name}"]`)
    .filter({ visible: true }).click();
  await expect(page.locator(`#${name}-tab`)).toBeVisible();
}

test('viewfinder navigation, team details, and responsive layout', async ({ page }, testInfo) => {
  const errors: string[] = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'NHL Fan League', exact: true })).toBeVisible();
  await expect(page.locator('.masthead-updated')).toContainText('Updated');
  await expect(page.locator('.viewfinder-frame')).toBeVisible();
  await expect(page.locator('#main-content')).toHaveCount(1);
  await expect(page.locator('main#main-content')).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('league-viewport.png') });
  await page.screenshot({ path: testInfo.outputPath('league.png'), fullPage: true });

  await page.getByRole('button', { name: 'View team standings', exact: true }).click();
  const team = page.locator('.team-card').first();
  await team.focus();
  await page.keyboard.press('Enter');
  await expect(team).toHaveAttribute('aria-expanded', 'true');
  await expect(team.locator('.team-card-details')).toBeVisible();
  await page.keyboard.press('Space');
  await expect(team).toHaveAttribute('aria-expanded', 'false');

  for (const view of ['standings', 'matchups', 'playoff-odds', 'trends']) {
    await selectView(page, view);
    if (view === 'playoff-odds') {
      await expect(page.locator('.odds-table')).toBeVisible();
      await expect(page.locator('#playoffOddsChart')).toBeVisible();
      await expect(page.getByText('Outer ring: make playoffs. Inner ring: win the Cup.')).toBeVisible();
    }
    if (view === 'trends') {
      await expect(page.locator('#seasonSelector option').first()).not.toHaveText('Loading...');
    }
    if (view === 'matchups') {
      for (const matchup of await page.locator('.matchup-card').all()) {
        const homeFan = await matchup.locator('.matchup-fan-name').last().innerText();
        await expect(matchup.locator('.win-prob-label')).toHaveText(`${homeFan} win chance`);
        await expect(matchup.locator('.matchup-time')).toContainText(/PT|Time TBD/);
      }
    }
    const fits = await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth);
    expect(fits, `${view} should not overflow the viewport`).toBe(true);
    await page.evaluate(() => new Promise<void>(resolve =>
      requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
    ));
    await page.screenshot({ path: testInfo.outputPath(`${view}.png`), fullPage: true });
  }
  expect(errors).toEqual([]);
});

test('team picker stays above mobile navigation and preserves the chosen theme', async ({ page }, testInfo) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Choose your team', exact: true }).click();
  const dialog = page.getByRole('dialog', { name: 'Choose Your Team', exact: true });
  await expect(dialog).toBeVisible();
  await expect(page.getByRole('button', { name: 'Close team picker' })).toBeFocused();
  await page.screenshot({ path: testInfo.outputPath('team-picker.png'), fullPage: false });
  await page.getByRole('button', { name: 'Boston Bruins', exact: true }).click();
  await expect(dialog).toBeHidden();
  expect(await page.evaluate(() => localStorage.getItem('nhl_fan_team'))).toBe('bruins');
  await page.reload();
  expect(await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue('--color-accent-primary').trim()
  )).toBe('#FFB81C');
  await page.getByRole('button', { name: 'Choose your team', exact: true }).click();
  await page.getByRole('button', { name: 'Reset to Default' }).click();
  expect(await page.evaluate(() => localStorage.getItem('nhl_fan_team'))).toBeNull();
});

test('empty and single-day seasons keep older trends accessible', async ({ page }, testInfo) => {
  await page.route('**/available_seasons.json', route => route.fulfill({
    json: { seasons: ['2026-2027', '2025-2026', '2024-2025', '2023-2024', '2022-2023'], current_season: '2026-2027' }
  }));
  await page.route('**/standings_history.json', route => route.fulfill({
    json: [
      { date: '2022-10-08', season: '2022-2023', standings: { Alice: null } },
      { date: '2022-10-09', season: '2022-2023', standings: { Alice: null } },
      { date: '2023-10-08', season: '2023-2024', standings: {} },
      { date: '2023-10-09', season: '2023-2024', standings: {} },
      { date: '2024-10-08', season: '2024-2025', standings: { Alice: 0 } },
      { date: '2024-10-09', season: '2024-2025', standings: { Alice: 4 } },
      { date: '2025-10-08', season: '2025-2026', standings: { Alice: 2 } }
    ]
  }));
  await page.route('**/fan_team_colors.json', route => route.fulfill({ json: { Alice: '#ffbc52' } }));
  await page.goto('/');
  await selectView(page, 'trends');
  const selector = page.locator('#seasonSelector');
  await expect(page.locator('#trend-status')).toContainText('No trend data for this season yet');
  await expect(selector).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('trends-empty.png'), fullPage: true });
  await selector.selectOption('2025-2026');
  await expect(page.locator('#trend-status')).toContainText('Tracking started on 2025-10-08');
  await selector.selectOption('2024-2025');
  await expect(page.locator('#leagueTrendChart')).toBeVisible();
  await expect(page.locator('#trend-status')).toBeHidden();
  expect(await page.evaluate('Chart.getChart("leagueTrendChart").data.datasets[0].data')).toEqual([0, 4]);
  await page.screenshot({ path: testInfo.outputPath('trends-zero.png'), fullPage: true });
  for (const season of ['2023-2024', '2022-2023']) {
    await selector.selectOption(season);
    await expect(page.locator('#leagueTrendChart')).toBeHidden();
    await expect(page.locator('#trend-status')).toContainText('No trend data for this season yet');
  }
  await selector.selectOption('2026-2027');
  await expect(page.locator('#leagueTrendChart')).toBeHidden();
  await selector.selectOption('2024-2025');
  await expect(page.locator('#leagueTrendChart')).toBeVisible();
});

test('playoff page keeps the viewfinder identity and relative return navigation', async ({ page }, testInfo) => {
  await page.goto('/playoffs.html');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Stanley Cup playoffs');
  await page.screenshot({ path: testInfo.outputPath('playoffs.png'), fullPage: true });
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true);
  const back = page.getByRole('link', { name: 'Back to league' }).first();
  await expect(back).toHaveAttribute('href', 'index.html');
  await back.click();
  await expect(page.locator('#league-tab')).toBeVisible();
});
