// Playwright configuration for Flutter Web UI testing
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false, // Run tests sequentially to avoid port conflicts
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1, // Single worker to avoid conflicts
  reporter: [
    ['html'],
    ['list']
  ],

  use: {
    baseURL: 'http://localhost:3201',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Don't start web server automatically - expect it to be running
  // Start with: ./start_flutter.sh
  timeout: 30000, // 30 seconds per test
});
