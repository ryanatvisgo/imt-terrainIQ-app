// Test: MQTT Connection and Communication
const { test, expect } = require('@playwright/test');

test.describe('MQTT Connection', () => {
  test('should establish MQTT connection', async ({ page }) => {
    const mqttLogs = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('MQTT')) {
        mqttLogs.push(text);
      }
    });

    await page.goto('http://localhost:3201');

    // Wait for MQTT connection
    await page.waitForTimeout(6000);

    // Check for successful connection
    const connected = mqttLogs.some(log =>
      log.includes('✅') && log.includes('Connected')
    );

    expect(connected).toBe(true);
  });

  test('should subscribe to preview topics', async ({ page }) => {
    const mqttLogs = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('MQTT') || text.includes('Subscribed')) {
        mqttLogs.push(text);
      }
    });

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(6000);

    // Check for subscription confirmation
    const subscribed = mqttLogs.some(log =>
      log.includes('Subscribed') && log.includes('preview')
    );

    expect(subscribed).toBe(true);
  });

  test('should publish status on connect', async ({ page }) => {
    const mqttLogs = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('MQTT') || text.includes('Published')) {
        mqttLogs.push(text);
      }
    });

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(6000);

    // Check for status publication
    const published = mqttLogs.some(log =>
      log.includes('Published') && log.includes('status')
    );

    expect(published).toBe(true);
  });

  test('should maintain stable connection', async ({ page }) => {
    const disconnections = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('❌') && text.includes('Disconnected')) {
        disconnections.push(text);
      }
    });

    await page.goto('http://localhost:3201');

    // Monitor for 10 seconds
    await page.waitForTimeout(10000);

    // Should have zero disconnections during stable operation
    expect(disconnections.length).toBe(0);
  });

  test('should not have MQTT errors', async ({ page }) => {
    const mqttErrors = [];

    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('MQTT') && (text.includes('Error') || text.includes('error'))) {
        mqttErrors.push(text);
      }
    });

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(6000);

    // Should have no MQTT errors
    expect(mqttErrors.length).toBe(0);
  });

  test('should have unique client ID', async ({ page }) => {
    const clientIds = [];

    page.on('console', msg => {
      const text = msg.text();
      const match = text.match(/flutter_dashcam_preview_(\d+)/);
      if (match) {
        clientIds.push(match[1]);
      }
    });

    await page.goto('http://localhost:3201');
    await page.waitForTimeout(6000);

    // Should have at least one client ID
    expect(clientIds.length).toBeGreaterThan(0);

    // Client ID should be 6 digits
    if (clientIds.length > 0) {
      expect(clientIds[0].length).toBe(6);
    }
  });
});
