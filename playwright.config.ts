import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  outputDir: './e2e/test-results',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'e2e/report', open: 'never' }],
    ['list'],
  ],
  use: {
    baseURL: 'http://localhost:8765',
    screenshot: 'on',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'desktop-chrome',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'mobile-iphone',
      use: { ...devices['iPhone 14'] },
    },
  ],
  webServer: {
    command: 'bundle exec ruby update_standings.rb && npx serve _site -l 8765 --no-clipboard',
    port: 8765,
    reuseExistingServer: !process.env.CI,
    timeout: 45000,
  },
});
