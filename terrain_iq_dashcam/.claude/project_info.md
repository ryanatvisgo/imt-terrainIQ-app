# TerrainIQ Dashcam - Project Information

## Project Overview

**TerrainIQ Dashcam** is a Flutter iOS application providing real-time road hazard detection and dashcam recording capabilities for drivers.

- **Platform:** iOS (Flutter)
- **Backend:** Node.js server (192.168.8.105:3000)
- **MQTT Broker:** 192.168.8.105:1883

## 🎯 Kanban Board System

This project uses a **folder-based Kanban board** for task management, optimized for AI agent and human collaboration.

### Quick Access

```bash
# View board
./kb show

# View specific column
./kb show --column backlog

# View statistics
./kb stats

# Get help
./kb --help
```

### Workflow for AI Agents

**Before starting any work:**

1. **Check available tasks**
   ```bash
   ./kb show --column ready
   ```

2. **Assign task to yourself**
   ```bash
   ./kb assign TASK-XXX agent
   ```

3. **Move to in_progress**
   ```bash
   ./kb move TASK-XXX in_progress
   ```

4. **View task details**
   ```bash
   ./kb details TASK-XXX
   ```

5. **Do the work** (implement, test, document)

6. **Add completion note**
   ```bash
   ./kb update TASK-XXX --add-note "Implementation complete, tests passing"
   ```

7. **Move to review**
   ```bash
   ./kb move TASK-XXX review
   ```

8. **After validation, move to done**
   ```bash
   ./kb move TASK-XXX done
   ```

### Board Columns

- **backlog/** - Tasks that need to be done
- **ready/** - Tasks ready to be worked on (prioritized)
- **in_progress/** - Tasks currently being worked on
- **review/** - Tasks awaiting review/validation
- **done/** - Completed tasks

### Current Tasks

Check current board status:
```bash
./kb show
./kb stats
```

### Task Management Commands

- `./kb add` - Add new task (interactive mode)
- `./kb move TASK-XXX column` - Move task between columns
- `./kb assign TASK-XXX agent` - Assign to agent/human
- `./kb update TASK-XXX --title "New title"` - Update task
- `./kb update TASK-XXX --add-note "Note text"` - Add note
- `./kb update TASK-XXX --add-tag "tag"` - Add tag
- `./kb details TASK-XXX` - Show full task details
- `./kb delete TASK-XXX` - Delete task

### Best Practices

1. **Always check ready column first** - Work on prioritized tasks
2. **Assign before starting** - Prevents duplicate work
3. **Add notes regularly** - Document progress and blockers
4. **Move to review, not done** - Human validation required
5. **Update metadata** - Keep priority, type, and assignee current

### Documentation

Full documentation available in: `kanban/README.md`

## 📁 Project Structure

```
.
├── lib/                    # Flutter application source
│   ├── main.dart          # App entry point
│   ├── config.dart        # Configuration
│   ├── models/            # Data models (Hazard, VideoRecording)
│   ├── screens/           # UI screens
│   ├── services/          # Business logic services
│   └── widgets/           # Reusable UI components
├── kanban/                # Kanban board system
│   ├── README.md          # Kanban documentation
│   ├── board-metadata.json
│   ├── kanban.py          # CLI tool
│   └── [columns]/         # Task folders
├── app_simulator.html     # Interactive web simulator
├── REQUIREMENTS.md        # Project requirements
├── kb                     # Kanban activation script
└── mock_server/           # Development server

```

## 🔧 Key Services

- **CameraService** - Camera and recording management
- **LocationService** - GPS tracking and heading
- **HazardService** - Hazard detection and proximity warnings
- **MotionService** - Accelerometer and movement detection
- **MqttService** - Real-time MQTT communication
- **ServerService** - HTTP API communication

## 🎨 Interactive Simulator

An interactive web-based simulator demonstrates app functionality:

```bash
# Open simulator in browser
open app_simulator.html
```

Features:
- Interactive controls for distance, severity, speed
- Three view modes (HUD, HUD+PIP, Camera+Overlay)
- 12 pre-configured scenarios with "Try It" buttons
- Portrait/Landscape orientation toggle
- Full requirements documentation

## 🚀 Development Workflow

### 1. Check Kanban Board
```bash
./kb show
```

### 2. Find Task in Ready Column
```bash
./kb show --column ready
```

### 3. Assign and Start Work
```bash
./kb assign TASK-XXX agent
./kb move TASK-XXX in_progress
```

### 4. Implement Changes
- Follow acceptance criteria
- Write tests
- Update documentation

### 5. Update Task Status
```bash
./kb update TASK-XXX --add-note "Implementation complete"
./kb move TASK-XXX review
```

### 6. Create Git Commit
```bash
git add .
git commit -m "Implement TASK-XXX: [description]"
```

### 7. After Review
```bash
./kb move TASK-XXX done
```

## 📖 Important Files

- **REQUIREMENTS.md** - Comprehensive requirements documentation
- **README.md** - Project setup and running instructions
- **TEST_DOCUMENTATION.md** - Testing procedures
- **kanban/README.md** - Kanban board documentation

## 🔗 Backend Endpoints

- `POST /get_hazards` - Fetch hazards within radius
- `POST /add_hazard` - Add new hazard
- `DELETE /remove_hazard/:id` - Remove hazard
- `GET /all_hazards` - Get all hazards
- `GET /hazard-map` - Web interface

## 📊 Priority Levels

- **critical** - Urgent, blocking issues
- **high** - Important tasks
- **medium** - Normal priority
- **low** - Nice-to-have

## 🏷️ Task Types

- **feature** - New functionality
- **bug** - Bug fixes
- **test** - Testing tasks
- **docs** - Documentation
- **refactor** - Code refactoring

## 💡 Tips for AI Agents

1. **Start with Kanban** - Always check `./kb show` first
2. **Read task details** - Use `./kb details TASK-XXX` to understand requirements
3. **Document progress** - Add notes frequently with `./kb update`
4. **Follow workflow** - backlog → ready → in_progress → review → done
5. **Git integration** - Commit task changes with clear messages
6. **Ask for clarification** - If task requirements are unclear, ask user

## 🆘 Getting Help

- Kanban help: `./kb --help`
- Full Kanban docs: `cat kanban/README.md`
- Project requirements: `cat REQUIREMENTS.md`
- Interactive simulator: `open app_simulator.html`

---

**Remember:** Always check the Kanban board first to see what tasks are available and prioritized!
