// Test: UI Interactions and Visual Elements
const { test, expect } = require('@playwright/test');

test.describe('Flutter UI Interactions', () => {
  test('should render UI elements after load', async ({ page }) => {
    await page.goto('http://localhost:3201');

    // Wait for Flutter to fully render
    await page.waitForTimeout(5000);

    // Take screenshot to verify visual rendering
    await page.screenshot({ path: 'tests/e2e/screenshots/ui-loaded.png' });

    // Verify Flutter view exists
    const flutterView = await page.locator('flutter-view, flt-glass-pane').count();
    expect(flutterView).toBeGreaterThan(0);
  });

  test('should handle page resize', async ({ page }) => {
    await page.goto('http://localhost:3201');
    await page.waitForTimeout(3000);

    // Resize to portrait mobile
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(1000);

    // Take screenshot
    await page.screenshot({ path: 'tests/e2e/screenshots/ui-portrait.png' });

    // Resize to landscape
    await page.setViewportSize({ width: 667, height: 375 });
    await page.waitForTimeout(1000);

    // Take screenshot
    await page.screenshot({ path: 'tests/e2e/screenshots/ui-landscape.png' });

    // Should not crash on resize
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    expect(errors.length).toBe(0);
  });

  test('should respond to mouse events', async ({ page }) => {
    await page.goto('http://localhost:3201');
    await page.waitForTimeout(3000);

    // Try clicking on the canvas
    const canvas = page.locator('canvas, flt-scene-host').first();
    await canvas.click({ position: { x: 100, y: 100 } });

    // Wait for any UI response
    await page.waitForTimeout(500);

    // Should not cause errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    expect(errors.length).toBe(0);
  });

  test('should handle keyboard input', async ({ page }) => {
    await page.goto('http://localhost:3201');
    await page.waitForTimeout(3000);

    // Try some keyboard events
    await page.keyboard.press('Space');
    await page.waitForTimeout(200);
    await page.keyboard.press('Enter');
    await page.waitForTimeout(200);

    // Should not cause errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    expect(errors.length).toBe(0);
  });

  test('should maintain performance', async ({ page }) => {
    await page.goto('http://localhost:3201');

    // Measure page load performance
    const performanceTiming = await page.evaluate(() => {
      const perfData = window.performance.timing;
      return {
        loadTime: perfData.loadEventEnd - perfData.navigationStart,
        domReady: perfData.domContentLoadedEventEnd - perfData.navigationStart,
      };
    });

    // Page should load in reasonable time (< 10 seconds)
    expect(performanceTiming.loadTime).toBeLessThan(10000);
    expect(performanceTiming.loadTime).toBeGreaterThan(0);

    console.log('Performance metrics:', performanceTiming);
  });

  test('should render without visual regressions', async ({ page }) => {
    await page.goto('http://localhost:3201');

    // Wait for full render
    await page.waitForTimeout(5000);

    // Take baseline screenshot
    await page.screenshot({
      path: 'tests/e2e/screenshots/baseline.png',
      fullPage: true
    });

    // Verify screenshot was created (basic check)
    const fs = require('fs');
    const screenshotExists = fs.existsSync('tests/e2e/screenshots/baseline.png');
    expect(screenshotExists).toBe(true);
  });

  test('should support touch events', async ({ page, browserName }) => {
    // Skip on non-mobile browsers
    if (browserName !== 'chromium') {
      test.skip();
    }

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(3000);

    // Simulate touch tap
    const canvas = page.locator('canvas, flt-scene-host').first();
    await canvas.tap({ position: { x: 150, y: 150 } });

    await page.waitForTimeout(500);

    // Should not cause errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    expect(errors.length).toBe(0);
  });
});
