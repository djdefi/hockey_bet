import { defineConfig, devices } from '@playwright/test';

const previewPort = Number(process.env.PREVIEW_PORT || 8765);

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
    baseURL: `http://localhost:${previewPort}`,
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
    command: `bundle exec ruby update_standings.rb && npx serve _site -l ${previewPort} --no-clipboard`,
    port: previewPort,
    reuseExistingServer: !process.env.CI,
    timeout: 45000,
  },
});
