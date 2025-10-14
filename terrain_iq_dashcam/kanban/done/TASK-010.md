---
id: TASK-010
title: Fix AI Assistant model name and create automated browser tests
type: bug
priority: high
assignee: agent
validation_status: passed
created_at: 2025-10-12T08:04:59.633962
updated_at: 2025-10-12T08:05:07.779816
completed_at: 2025-10-12T08:05:07.779822
tags: []
---

# Fix AI Assistant model name and create automated browser tests

## Description

Fixed incorrect Claude model name (claude-3-5-sonnet-20241022 -> claude-3-5-sonnet-20240620) in kanban_server.js AI enhancement endpoint. Created comprehensive Playwright test suite in kanban/tests folder with tests for: board view, task selection, editing, AI assistant, pop-out modal, and refresh functionality. Tests are isolated from main project test suite.

## Use Case



## Acceptance Criteria

_No criteria specified yet_

## Test Data

### Good Samples
_No good samples defined_

### Bad Samples
_No bad samples defined_

## Notes

_No notes yet_
