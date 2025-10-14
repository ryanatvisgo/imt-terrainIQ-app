# Kanban UI Automated Tests

Automated browser tests for the TerrainIQ Kanban UI using Playwright.

## Setup

```bash
cd kanban/tests
npm install
npx playwright install chromium
```

## Running Tests

```bash
# Run all tests
npm test

# Run tests with UI mode (visual test runner)
npm run test:ui

# Run tests in headed mode (see browser)
npm run test:headed

# Debug tests
npm run test:debug

# View test report
npm run report
```

## Test Coverage

### Board View
- ✓ Load board with all columns
- ✓ Display tasks in columns
- ✓ Show task counts

### Task Selection
- ✓ Open sidebar on task click
- ✓ Highlight selected task
- ✓ Close sidebar

### Task Editing
- ✓ Edit task title
- ✓ Change task type/priority/assignee
- ✓ Toggle metadata section
- ✓ Switch between tabs

### AI Assistant
- ✓ Toggle AI section collapse/expand
- ✓ Display quick prompts
- ✓ Chat interface

### Pop-out Modal
- ✓ Open modal
- ✓ Display all editable fields
- ✓ AI assistant in modal sidebar
- ✓ Close modal (X button, backdrop)
- ✓ Save changes

### General
- ✓ Refresh board

## Architecture

Tests are isolated in the `kanban/tests` folder to keep them separate from the main project test suite.

- `package.json` - Test dependencies
- `playwright.config.js` - Playwright configuration
- `specs/` - Test specifications
- `README.md` - This file

## Notes

- Tests automatically start the Kanban server on port 3001
- Tests use the actual Kanban data in `kanban/` folders
- AI features are tested for UI presence, not actual API calls
