import { test, expect } from '@playwright/test';

test.describe('Kanban UI - Board View', () => {
  test('should load the board with all columns', async ({ page }) => {
    await page.goto('/kanban_ui.html');

    // Check header
    await expect(page.locator('h1')).toContainText('TerrainIQ Kanban Board');

    // Check all 5 columns exist
    await expect(page.locator('.column-title:has-text("Backlog")')).toBeVisible();
    await expect(page.locator('.column-title:has-text("Ready")')).toBeVisible();
    await expect(page.locator('.column-title:has-text("In Progress")')).toBeVisible();
    await expect(page.locator('.column-title:has-text("Review")')).toBeVisible();
    await expect(page.locator('.column-title:has-text("Done")')).toBeVisible();

    // Take screenshot of board view
    await page.screenshot({ path: 'kanban/tests/screenshots/01-board-view.png', fullPage: true });
  });

  test('should display tasks in columns', async ({ page }) => {
    await page.goto('/kanban_ui.html');

    // Wait for board to load
    await page.waitForTimeout(1000);

    // Check that task cards are present
    const taskCards = page.locator('.task-card');
    const count = await taskCards.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should show task count in column headers', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Check that task counts are displayed
    const taskCounts = page.locator('.task-count');
    const count = await taskCounts.count();
    expect(count).toBe(5); // One for each column
  });
});

test.describe('Kanban UI - Task Selection', () => {
  test('should open sidebar when task is clicked', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Click first task
    const firstTask = page.locator('.task-card').first();
    await firstTask.click();

    // Check sidebar is visible
    const sidebar = page.locator('#sidebar');
    await expect(sidebar).not.toHaveClass(/collapsed/);

    // Check task details are shown
    await expect(page.locator('.task-detail-title')).toBeVisible();

    // Take screenshot with sidebar open
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'kanban/tests/screenshots/02-task-sidebar.png', fullPage: true });
  });

  test('should highlight selected task', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    const firstTask = page.locator('.task-card').first();
    await firstTask.click();

    // Check task has selected class
    await expect(firstTask).toHaveClass(/selected/);
  });

  test('should close sidebar when X is clicked', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Open sidebar
    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    // Close sidebar (be specific to avoid modal close button)
    await page.locator('#sidebar .close-btn').click();

    // Check sidebar is collapsed
    const sidebar = page.locator('#sidebar');
    await expect(sidebar).toHaveClass(/collapsed/);
  });
});

test.describe('Kanban UI - Task Editing', () => {
  test('should edit task title', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Open task
    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    // Click edit on title
    await page.locator('.edit-toggle:near(.task-detail-title)').first().click();

    // Input should be visible
    await expect(page.locator('#input-title')).toBeVisible();
  });

  test('should change task type', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Open task and expand metadata
    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);
    await page.locator('.metadata-header').click();
    await page.waitForTimeout(300);

    // Change type dropdown
    const typeSelect = page.locator('select').filter({ hasText: /Feature|Bug|Docs/ }).first();
    await typeSelect.selectOption('bug');

    // Wait for save
    await page.waitForTimeout(1000);

    // Check for save indicator
    await expect(page.locator('.save-indicator')).toBeVisible({ timeout: 3000 });
  });

  test('should toggle metadata section', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    const metadataSection = page.locator('#metadataSection');

    // Should start collapsed
    await expect(metadataSection).toHaveClass(/collapsed/);

    // Click to expand
    await page.locator('.metadata-header').click();
    await page.waitForTimeout(300);

    // Should be expanded
    await expect(metadataSection).not.toHaveClass(/collapsed/);
  });
});

test.describe('Kanban UI - Tabs', () => {
  test('should switch between tabs', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    // Click Acceptance Criteria tab
    await page.locator('.tab:has-text("Acceptance Criteria")').click();

    // Check tab content is visible
    await expect(page.locator('#tab-criteria')).toHaveClass(/active/);
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'kanban/tests/screenshots/03-acceptance-criteria-tab.png', fullPage: true });

    // Click Subtasks tab
    await page.locator('.tab:has-text("Subtasks")').click();
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'kanban/tests/screenshots/04-subtasks-tab.png', fullPage: true });

    // Click Notes tab
    await page.locator('.tab:has-text("Notes")').click();
    await expect(page.locator('#tab-notes')).toHaveClass(/active/);
    await page.waitForTimeout(300);
    await page.screenshot({ path: 'kanban/tests/screenshots/05-notes-tab.png', fullPage: true });
  });
});

test.describe('Kanban UI - AI Assistant', () => {
  test('should toggle AI assistant', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    const aiSection = page.locator('#aiSection');

    // Click to collapse
    await page.locator('.ai-section-header').click();
    await page.waitForTimeout(300);

    // Should be collapsed
    await expect(aiSection).toHaveClass(/collapsed/);

    // Click to expand
    await page.locator('.ai-section-header').click();
    await page.waitForTimeout(300);

    // Should be expanded
    await expect(aiSection).not.toHaveClass(/collapsed/);
  });

  test('should show AI quick prompts', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    // Check quick prompts exist
    await expect(page.locator('.quick-prompt-btn:has-text("Break down")')).toBeVisible();
    await expect(page.locator('.quick-prompt-btn:has-text("Suggest criteria")')).toBeVisible();
    await expect(page.locator('.quick-prompt-btn:has-text("Dependencies")')).toBeVisible();
  });
});

test.describe('Kanban UI - Pop-out Modal', () => {
  test('should open pop-out modal', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);

    // Click pop-out button
    await page.locator('.popout-btn').click();

    // Modal should be visible
    await expect(page.locator('#modalOverlay')).toHaveClass(/active/);
    await expect(page.locator('.modal-container')).toBeVisible();

    // Take screenshot of modal
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'kanban/tests/screenshots/06-popout-modal.png', fullPage: true });
  });

  test('should display all fields in modal', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);
    await page.locator('.popout-btn').click();

    // Check all textareas are present
    await expect(page.locator('#modal-description')).toBeVisible();
    await expect(page.locator('#modal-use-case')).toBeVisible();
    await expect(page.locator('#modal-criteria')).toBeVisible();
    await expect(page.locator('#modal-notes')).toBeVisible();
  });

  test('should have AI assistant in modal', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);
    await page.locator('.popout-btn').click();

    // Check AI assistant is present
    await expect(page.locator('.modal-ai-header')).toContainText('AI Assistant');
    await expect(page.locator('#modalChatMessages')).toBeVisible();
    await expect(page.locator('#modalChatInput')).toBeVisible();
  });

  test('should close modal when X clicked', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);
    await page.locator('.popout-btn').click();

    // Close modal
    await page.locator('.modal-header .close-btn').click();

    // Modal should be hidden
    await expect(page.locator('#modalOverlay')).not.toHaveClass(/active/);
  });

  test('should close modal when backdrop clicked', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    await page.locator('.task-card').first().click();
    await page.waitForTimeout(500);
    await page.locator('.popout-btn').click();

    // Click backdrop (outside modal)
    await page.locator('#modalOverlay').click({ position: { x: 10, y: 10 } });

    // Modal should be hidden
    await expect(page.locator('#modalOverlay')).not.toHaveClass(/active/);
  });
});

test.describe('Kanban UI - Refresh', () => {
  test('should refresh board when button clicked', async ({ page }) => {
    await page.goto('/kanban_ui.html');
    await page.waitForTimeout(1000);

    // Click refresh button
    await page.locator('button:has-text("Refresh")').click();

    // Wait for reload
    await page.waitForTimeout(1000);

    // Board should still be visible
    await expect(page.locator('.board')).toBeVisible();
  });
});
