import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './specs',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3001',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Server is manually started, so webServer config is commented out
  // webServer: {
  //   command: 'cd ../.. && export ANTHROPIC_API_KEY=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 && node kanban_server.js',
  //   url: 'http://localhost:3001',
  //   reuseExistingServer: true,
  //   timeout: 120 * 1000,
  // },
});
