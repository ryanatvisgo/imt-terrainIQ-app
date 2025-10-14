# Kanban Board - TerrainIQ Dashcam Development

A folder-based Kanban board system optimized for AI agent and human collaboration workflows.

## 📁 Directory Structure

```
kanban/
├── README.md              # This file
├── board-metadata.json    # Board configuration
├── kanban.py             # CLI tool (executable)
├── backlog/              # Tasks to be done
├── ready/                # Tasks ready to work on
├── in_progress/          # Tasks being worked on
├── review/               # Tasks awaiting validation
└── done/                 # Completed tasks
```

Each task is stored as an individual JSON file (e.g., `TASK-001.json`) in its respective column folder.

## 🎯 Why Folder-Based?

### Benefits

1. **Git-Friendly** - No merge conflicts when multiple people/agents work simultaneously
2. **Parallel Work** - Each task is independent; move tasks without affecting others
3. **Scalable** - Performance doesn't degrade with task count
4. **Visual** - Folder structure mirrors the Kanban board
5. **Simple** - Just file operations, no database required
6. **AI-Friendly** - Perfect for autonomous agent workflows
7. **Transparent** - Track task evolution through git history

## 🚀 Quick Start

### Installation

1. Install dependencies:
```bash
pip install click==8.1.7 rich==13.7.0
```

2. Verify installation:
```bash
python kanban/kanban.py --help
```

3. View the board:
```bash
python kanban/kanban.py show
```

### First Task

```bash
# Add your first task
python kanban/kanban.py add \
  --title "Create Settings screen design" \
  --description "Design the Settings screen with configuration options" \
  --type feature \
  --priority high \
  --assignee agent

# View details
python kanban/kanban.py details TASK-001

# Move through workflow
python kanban/kanban.py move TASK-001 ready
python kanban/kanban.py assign TASK-001 agent
python kanban/kanban.py move TASK-001 in_progress
```

## 📖 Commands Reference

### Show Board

Display the entire board or a specific column:

```bash
# Show all columns
python kanban/kanban.py show

# Show specific column
python kanban/kanban.py show --column in_progress
```

### Add Task

Add a new task to the backlog (interactive mode):

```bash
python kanban/kanban.py add
```

Or specify all fields inline:

```bash
python kanban/kanban.py add \
  --title "Task title" \
  --description "Detailed description" \
  --type feature \
  --priority high \
  --assignee agent \
  --use-case "UC-001"
```

**Task Types:**
- `feature` - New functionality
- `bug` - Bug fix
- `test` - Testing tasks
- `docs` - Documentation
- `refactor` - Code refactoring

**Priority Levels:**
- `critical` - Urgent, blocking issues
- `high` - Important tasks
- `medium` - Normal priority (default)
- `low` - Nice-to-have

**Assignees:**
- `agent` - AI agent task
- `human` - Human developer task
- `unassigned` - Not yet assigned

### Move Task

Move a task between columns:

```bash
python kanban/kanban.py move TASK-001 in_progress
```

Available columns: `backlog`, `ready`, `in_progress`, `review`, `done`

### Assign Task

Assign task to agent or human:

```bash
python kanban/kanban.py assign TASK-001 agent
python kanban/kanban.py assign TASK-002 human
```

### View Details

Show detailed information about a task:

```bash
python kanban/kanban.py details TASK-001
```

### Update Task

Update task properties:

```bash
# Update title
python kanban/kanban.py update TASK-001 --title "New title"

# Update description
python kanban/kanban.py update TASK-001 --description "New description"

# Change priority
python kanban/kanban.py update TASK-001 --priority critical

# Change type
python kanban/kanban.py update TASK-001 --type bug

# Add note (with timestamp)
python kanban/kanban.py update TASK-001 --add-note "Completed implementation"

# Add tag
python kanban/kanban.py update TASK-001 --add-tag "backend"
```

### Statistics

View board statistics:

```bash
python kanban/kanban.py stats
```

Shows:
- Task count per column
- Breakdown by assignee (agent/human/unassigned)
- Priority breakdown

### Delete Task

Delete a task permanently (requires confirmation):

```bash
python kanban/kanban.py delete TASK-001
```

### Debug Commands

List all task files:

```bash
python kanban/kanban.py list-files
```

## 🤖 Workflow for AI Agents

### Standard Task Workflow

```bash
# 1. Check available tasks
python kanban/kanban.py show --column ready

# 2. Assign task to self
python kanban/kanban.py assign TASK-005 agent

# 3. Move to in_progress
python kanban/kanban.py move TASK-005 in_progress

# 4. View task details
python kanban/kanban.py details TASK-005

# 5. Do the work...
# [Implement the feature/fix]

# 6. Add completion note
python kanban/kanban.py update TASK-005 --add-note "Implementation complete, tests passing"

# 7. Move to review
python kanban/kanban.py move TASK-005 review

# 8. After validation, move to done
python kanban/kanban.py move TASK-005 done
```

### Best Practices for Agents

1. **Always check ready column first** - Work on prioritized tasks
2. **Assign before starting** - Prevents duplicate work
3. **Add notes regularly** - Document progress and blockers
4. **Move to review** - Don't move directly to done
5. **Update completion notes** - Summarize what was done

## 👤 Workflow for Human Developers

Same workflow as agents, but use `--assignee human` when assigning tasks.

```bash
# Find unassigned high-priority tasks
python kanban/kanban.py show | grep "unassigned" | grep "high"

# Assign to yourself
python kanban/kanban.py assign TASK-010 human

# Follow standard workflow
python kanban/kanban.py move TASK-010 in_progress
```

## 📝 Task File Format

Each task is stored as JSON:

```json
{
  "id": "TASK-001",
  "title": "Implement Settings screen",
  "description": "Create Settings screen with config options",
  "type": "feature",
  "priority": "high",
  "assignee": "agent",
  "use_case": "UC-001",
  "test_data": {
    "good_samples": [],
    "bad_samples": []
  },
  "acceptance_criteria": [
    "Settings screen renders correctly",
    "All options are configurable",
    "Settings persist after restart"
  ],
  "validation_status": "pending",
  "created_at": "2025-10-12T10:00:00",
  "updated_at": "2025-10-12T10:30:00",
  "completed_at": null,
  "tags": ["ui", "settings"],
  "notes": [
    "[2025-10-12 10:30] Started implementation",
    "[2025-10-12 12:00] UI complete, testing"
  ]
}
```

## 🔄 Git Integration

### Committing Task Changes

Tasks are files, so commit them like any code:

```bash
# After creating a task
git add kanban/backlog/TASK-001.json
git commit -m "Add task: Implement Settings screen"

# After moving a task
git add kanban/ready/TASK-001.json
git rm kanban/backlog/TASK-001.json
git commit -m "Move TASK-001 to ready"

# After completing a task
git add kanban/done/TASK-001.json
git rm kanban/in_progress/TASK-001.json
git commit -m "Complete TASK-001: Settings screen implemented"
```

### Batch Operations

Work on multiple tasks and commit together:

```bash
# Complete multiple tasks
python kanban/kanban.py move TASK-001 done
python kanban/kanban.py move TASK-002 done
python kanban/kanban.py move TASK-003 review

# Commit all changes
git add kanban/
git commit -m "Update task status: completed TASK-001, TASK-002"
```

## 🎨 Best Practices

### Creating Tasks

1. **Be Specific** - Clear, actionable titles
2. **Add Context** - Detailed descriptions
3. **Set Priority** - Help prioritize work
4. **Define Success** - Clear acceptance criteria
5. **Link Use Cases** - Connect to requirements

Good Example:
```bash
python kanban/kanban.py add \
  --title "Add screen navigation to Examples tab" \
  --description "Implement buttons to toggle between Hazard, Camera, Settings, and Nav views for each scenario" \
  --type feature \
  --priority high \
  --assignee agent
```

Bad Example:
```bash
python kanban/kanban.py add \
  --title "Fix stuff" \
  --description "Make it work" \
  --type feature \
  --priority medium
```

### Working on Tasks

1. **One task at a time** - Move to in_progress only when actively working
2. **Update regularly** - Add notes for progress/blockers
3. **Test before review** - Ensure it works before moving to review
4. **Clean up** - Remove debug code, update docs

### Reviewing Tasks

1. **Check acceptance criteria** - Verify all criteria met
2. **Test functionality** - Manual or automated testing
3. **Review code quality** - Clean, maintainable code
4. **Validate documentation** - README/docs updated
5. **Move to done or back** - Accept or request changes

## 🔧 Troubleshooting

### Common Issues

**"board-metadata.json not found"**
```bash
# Make sure you're in the kanban directory or use full path
cd kanban && python kanban.py show
```

**"Task not found"**
```bash
# List all tasks to find it
python kanban/kanban.py list-files

# Check if task exists in different column
python kanban/kanban.py show
```

**"Corrupted JSON"**
```bash
# Validate JSON file
python3 -m json.tool kanban/backlog/TASK-001.json

# Fix manually or restore from git
git checkout kanban/backlog/TASK-001.json
```

**Wrong task number sequence**
```bash
# Edit board-metadata.json manually
# Update "next_task_number" to correct value
```

### Recovery

If the board gets into a bad state:

```bash
# 1. List all files
python kanban/kanban.py list-files

# 2. Check for JSON errors
for f in kanban/*/*.json; do python3 -m json.tool "$f" > /dev/null || echo "Error in $f"; done

# 3. Restore from git if needed
git checkout kanban/
```

## 📊 Advanced Usage

### Query Tasks with jq

```bash
# Find all high-priority tasks
find kanban -name "*.json" -exec cat {} \; | jq 'select(.priority=="high")'

# Find all agent-assigned tasks
find kanban -name "*.json" -exec cat {} \; | jq 'select(.assignee=="agent")'

# Count tasks by type
find kanban -name "*.json" -exec cat {} \; | jq -r '.type' | sort | uniq -c
```

### Bulk Operations

```bash
# Move all ready tasks to in_progress (use with caution)
for task in kanban/ready/TASK-*.json; do
  task_id=$(basename "$task" .json)
  python kanban/kanban.py move "$task_id" in_progress
done
```

### Export to CSV

```bash
# Export all tasks to CSV
echo "ID,Title,Type,Priority,Assignee,Column" > tasks.csv
for col in backlog ready in_progress review done; do
  for task in kanban/$col/TASK-*.json; do
    if [ -f "$task" ]; then
      id=$(jq -r '.id' "$task")
      title=$(jq -r '.title' "$task")
      type=$(jq -r '.type' "$task")
      priority=$(jq -r '.priority' "$task")
      assignee=$(jq -r '.assignee' "$task")
      echo "$id,$title,$type,$priority,$assignee,$col" >> tasks.csv
    fi
  done
done
```

## 🛠️ Customization

You can customize the board by editing `board-metadata.json`:

- **Column names** - Change display names
- **Task template** - Add custom fields
- **Workflow** - Add/remove columns
- **Validation rules** - Add custom validation

## 📚 Integration with Project

### From Root Directory

Create `activate.sh` in project root:

```bash
#!/bin/bash
# Activate and run kanban CLI
python kanban/kanban.py "$@"
```

Make it executable:
```bash
chmod +x activate.sh
```

Usage:
```bash
./activate.sh show
./activate.sh add --title "New task"
./activate.sh move TASK-001 done
```

### With Virtual Environment

If using a virtual environment:

```bash
#!/bin/bash
# Activate venv and run kanban
source venv/bin/activate
python kanban/kanban.py "$@"
deactivate
```

## 🌟 Tips & Tricks

1. **Aliases** - Add to your shell config:
   ```bash
   alias kb='python kanban/kanban.py'
   alias kbs='python kanban/kanban.py show'
   alias kba='python kanban/kanban.py add'
   ```

2. **Quick Status** - Check board status anytime:
   ```bash
   kb stats
   ```

3. **Task Templates** - Create script for common task types:
   ```bash
   #!/bin/bash
   # new-feature.sh
   python kanban/kanban.py add \
     --title "$1" \
     --description "$2" \
     --type feature \
     --priority high \
     --assignee agent
   ```

4. **Git Hooks** - Auto-update kanban on commit:
   ```bash
   # .git/hooks/post-commit
   #!/bin/bash
   python kanban/kanban.py stats
   ```

## 📞 Support

For issues or questions:
- Check this README
- Review task files for corruption
- Verify git history for changes
- Restore from git if needed

## 🎯 Current Project Status

View real-time board status:
```bash
python kanban/kanban.py show
python kanban/kanban.py stats
```

---

**Last Updated:** 2025-10-12
**Version:** 2.0.0
**System:** Folder-based Kanban
