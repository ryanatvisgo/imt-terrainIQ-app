// Test: Flutter App Load and Basic Rendering
const { test, expect } = require('@playwright/test');

test.describe('Flutter App - Load and Render', () => {
  test('should load Flutter app without errors', async ({ page }) => {
    // Listen for console errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    // Navigate to Flutter app
    await page.goto('http://localhost:3201');

    // Wait for Flutter to load (look for flutter-view)
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 15000 });

    // Check for JavaScript errors
    expect(errors.length).toBe(0);
  });

  test('should render Flutter canvas', async ({ page }) => {
    await page.goto('http://localhost:3201');

    // Wait for Flutter to initialize
    await page.waitForTimeout(3000);

    // Check for Flutter rendering elements
    const flutterView = await page.locator('flutter-view, flt-glass-pane').count();
    expect(flutterView).toBeGreaterThan(0);

    // Check for canvas element
    const canvas = await page.locator('canvas, flt-scene-host').count();
    expect(canvas).toBeGreaterThan(0);
  });

  test('should have valid page title', async ({ page }) => {
    await page.goto('http://localhost:3201');

    // Wait for page to load
    await page.waitForTimeout(2000);

    const title = await page.title();
    expect(title).toBeTruthy();
    expect(title.length).toBeGreaterThan(0);
  });

  test('should not have network errors', async ({ page }) => {
    const failedRequests = [];

    page.on('requestfailed', request => {
      failedRequests.push({
        url: request.url(),
        failure: request.failure()
      });
    });

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(3000);

    // Allow some expected failures (like missing fonts, etc.)
    // but check for critical resource failures
    const criticalFailures = failedRequests.filter(req =>
      req.url.includes('main.dart.js') ||
      req.url.includes('flutter.js')
    );

    expect(criticalFailures.length).toBe(0);
  });

  test('should connect to MQTT broker', async ({ page }) => {
    const mqttLogs = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('MQTT') || text.includes('mqtt')) {
        mqttLogs.push(text);
      }
    });

    await page.goto('http://localhost:3201');

    // Wait for MQTT connection attempt
    await page.waitForTimeout(5000);

    // Check for MQTT connection logs
    const connectionLogs = mqttLogs.filter(log =>
      log.includes('Connected') || log.includes('Connecting')
    );

    expect(connectionLogs.length).toBeGreaterThan(0);
  });
});
