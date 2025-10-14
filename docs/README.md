# TerrainIQ Dashcam Documentation

Welcome to the TerrainIQ Dashcam documentation repository.

## Documentation Structure

This directory contains comprehensive documentation for the TerrainIQ Dashcam project, organized by topic:

### 📁 Directory Overview

```
docs/
├── api/              # API documentation (future)
├── architecture/     # Architecture decisions and diagrams
├── deployment/       # Deployment guides and release process
├── mobile/           # Mobile platform-specific documentation
└── README.md         # This file
```

## Quick Links

### For Developers

**Getting Started:**
- Read `terrain_iq_dashcam/README.md` for setup instructions
- Review `.claude/context.md` for quick project overview
- Study `.claude/analysis.md` for comprehensive system understanding

**AI Assistant Setup:**
- Run `./ailearn.sh` to load project context
- Follow `.claude/ai_session_initialization.md` for initialization
- Adhere to `.claude/AGENT_RULES.md` for behavioral guidelines

### For AI Assistants (Claude, GPT, etc.)

**Initialization Checklist:**
1. Run `./ailearn.sh` from project root
2. Read `.claude/context.md` - Quick overview
3. Read `.claude/analysis.md` - Detailed system analysis
4. Read `.claude/AGENT_RULES.md` - Behavioral rules
5. Read `.claude/ai_session_initialization.md` - Initialization guide

## Core Documentation Files

### In `.claude/` Directory

| File | Purpose | When to Read |
|------|---------|--------------|
| `context.md` | Quick project context and overview | Start of every session |
| `analysis.md` | Comprehensive system analysis (13 sections) | Deep understanding needed |
| `AGENT_RULES.md` | AI behavioral guidelines and constraints | Before making changes |
| `ai_session_initialization.md` | Structured initialization checklist | First time or re-initialization |
| `project-initialization-log.record` | Initialization history and audit log | Troubleshooting or verification |

### In `terrain_iq_dashcam/` Directory

| File | Purpose |
|------|---------|
| `README.md` | Setup instructions, usage guide, troubleshooting |
| `pubspec.yaml` | Dependencies, version, configuration |
| `lib/` | Source code (Dart) |

## Documentation Topics

### Architecture

**Location:** `.claude/analysis.md` (Section 2: Architecture Overview)

Covers:
- High-level architecture diagram
- Design patterns (Service Layer, Provider, Repository, Observer)
- Component relationships
- Data flow

### Core Components

**Location:** `.claude/analysis.md` (Section 3: Core Components)

Details on:
- CameraService - Video recording management
- StorageService - File management and storage limits
- PermissionService - Cross-platform permission handling
- VideoRecording Model - Recording metadata
- UI Components - Screens and widgets

### Dependencies

**Location:** `.claude/analysis.md` (Section 6: Dependencies)

Lists all:
- Flutter packages and versions
- Platform requirements
- Dev dependencies

### Platform-Specific Implementation

**Location:** `.claude/analysis.md` (Section 7: Platform-Specific Implementation)

iOS and Android:
- Configuration requirements
- Permission declarations
- Build settings
- Platform constraints

### State Management

**Location:** `.claude/analysis.md` (Section 8: State Management)

Explains:
- Provider pattern implementation
- State notification flow
- Service lifecycle
- Widget state consumption

### Development Workflow

**Location:** `.claude/analysis.md` (Section 11: Development Workflow)

Includes:
- Setup instructions
- Development commands
- Debugging tools
- Testing procedures

## Common Tasks

### Setting Up Development Environment

1. Read `terrain_iq_dashcam/README.md`
2. Install Flutter SDK
3. Run `flutter doctor`
4. Navigate to `terrain_iq_dashcam/`
5. Run `flutter pub get`
6. Connect device and run `flutter run`

### Working with AI Assistants

1. Run `./ailearn.sh` from project root
2. AI reads initialization files
3. AI acknowledges behavioral rules
4. Begin development work

### Adding New Features

1. Review `.claude/analysis.md` for architecture understanding
2. Follow `.claude/AGENT_RULES.md` for coding standards
3. Implement in appropriate service layer
4. Update UI components
5. Test on physical devices (iOS & Android)
6. Update documentation

### Troubleshooting

**Build Issues:**
- Check `.claude/analysis.md` Section 12 (Known Issues)
- Run `flutter doctor`
- Run `flutter clean && flutter pub get`

**Permission Issues:**
- Review platform-specific configuration in `.claude/analysis.md` Section 7
- Check Info.plist (iOS) or AndroidManifest.xml (Android)

**Camera Issues:**
- Requires physical device (not emulator)
- Check permission handling in code
- Review CameraService implementation

## Future Documentation

### Planned Documentation

- [ ] API reference documentation (`docs/api/`)
- [ ] Architecture decision records (`docs/architecture/`)
- [ ] Deployment and release guides (`docs/deployment/`)
- [ ] iOS-specific guide (`docs/mobile/ios.md`)
- [ ] Android-specific guide (`docs/mobile/android.md`)
- [ ] Testing guide (unit, widget, integration tests)
- [ ] Performance optimization guide
- [ ] Contribution guidelines
- [ ] Changelog and version history

## Contributing to Documentation

When updating documentation:

1. Keep `.claude/context.md` current for quick reference
2. Update `.claude/analysis.md` for architectural changes
3. Reflect changes in `terrain_iq_dashcam/README.md` for user-facing updates
4. Add specialized docs to appropriate `docs/` subdirectories
5. Update this README if documentation structure changes

## Documentation Standards

- Use Markdown format (`.md` files)
- Include code examples where applicable
- Keep quick reference files concise
- Provide detailed explanations in analysis files
- Update modification dates in headers
- Link between related documents

## Questions?

- For project context: Read `.claude/context.md`
- For technical details: Read `.claude/analysis.md`
- For AI assistance: Run `./ailearn.sh`
- For setup help: Read `terrain_iq_dashcam/README.md`

---

**Last Updated:** 2025-10-10
**Maintained By:** TerrainIQ Development Team
