# AI Session Initialization Guide - TerrainIQ Dashcam

**Version:** 1.0
**Last Updated:** 2025-10-10
**Purpose:** Guide AI assistants (Claude, GPT, etc.) through proper session initialization

---

## 🎯 INITIALIZATION OVERVIEW

This document provides a structured checklist for AI assistants to properly initialize when working on the TerrainIQ Dashcam project. Following this process ensures the AI has complete context and operates according to project rules.

---

## ✅ INITIALIZATION CHECKLIST

### Phase 1: Context Loading (5 minutes)

- [ ] Read `.claude/context.md` - Quick project overview
- [ ] Read `.claude/analysis.md` - Comprehensive system analysis
- [ ] Read `.claude/AGENT_RULES.md` - Behavioral rules and constraints
- [ ] Read `terrain_iq_dashcam/README.md` - Setup and usage instructions
- [ ] Review `terrain_iq_dashcam/pubspec.yaml` - Dependencies and configuration

**Purpose:** Gain foundational understanding of project architecture, current status, and critical constraints.

### Phase 2: Git History Analysis (WHEN AVAILABLE)

**NOTE:** This project is currently not a Git repository. Skip this phase until Git is initialized.

Once Git is initialized, perform this analysis:

```bash
# Recent commit history
git log --oneline --since="2 weeks ago" --no-merges

# Changed files
git log --since="2 weeks ago" --no-merges --name-only --pretty=format:"%h %s" | head -50

# Current status
git status

# Active branches
git branch -a
```

**Required Output Format:**

```
📊 GIT HISTORY ANALYSIS
=======================
Period: [Start Date] to [End Date]
Commits: [Number]
Active Branch: [Branch Name]

🔍 Recent Development Focus:
• [Focus Area 1]
• [Focus Area 2]
• [Focus Area 3]

📁 Most Modified Files:
• [File 1] - [Change Description]
• [File 2] - [Change Description]
• [File 3] - [Change Description]

🎯 Inferred Current Priorities:
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

⚠️ Observations:
• [Any concerns or patterns]
=======================
```

### Phase 3: Behavioral Rules Acknowledgment

Explicitly acknowledge understanding of critical rules:

```
✅ BEHAVIORAL RULES ACKNOWLEDGED:

🔒 Git Operations:
• NEVER use 'git add .' - stage files individually
• NEVER modify config files without permission
• ALWAYS ask before staging files for commit
• NEVER perform destructive operations without warning

📱 Flutter Operations:
• NEVER modify pubspec.yaml without permission
• NEVER change platform files without verification
• ALWAYS run 'flutter pub get' after dependency changes
• NEVER upgrade Flutter SDK without approval

🧪 Testing:
• ALWAYS test camera features on physical devices
• NEVER assume emulator support for camera/GPS
• ALWAYS verify changes on both iOS and Android

📝 Code Standards:
• Follow Dart style guide
• Implement error handling
• Add comments for complex logic
• Use const constructors where possible
```

### Phase 4: Project Status Verification

Verify current project state:

```bash
# Flutter environment
flutter doctor

# Current dependencies
flutter pub get

# Check for diagnostics
flutter analyze
```

**Report Status:**
```
🔧 PROJECT STATUS CHECK
=======================
Flutter Version: [Version]
Dart Version: [Version]
Dependencies: [✅ Up-to-date / ⚠️ Outdated]
Analysis Issues: [Count or ✅ None]
Connected Devices: [List or ❌ None]
=======================
```

### Phase 5: Ready Confirmation

**AI Must Confirm:**

```
✅ INITIALIZATION COMPLETE

📚 Context Loaded:
• Project architecture understood
• Current implementation status known
• Critical constraints acknowledged
• Behavioral rules committed

🎯 Ready for:
• Feature development
• Bug fixes
• Code review
• Documentation updates
• Testing assistance

⚠️ Will NOT do without permission:
• Modify configuration files
• Upgrade dependencies
• Change platform-specific code
• Commit to Git (when initialized)

💬 How can I assist you with TerrainIQ Dashcam?
```

---

## 🔍 QUICK REFERENCE: KEY PROJECT INFO

### Technology Stack
- **Framework:** Flutter 3.9.2 (Dart)
- **State Management:** Provider pattern
- **Platform:** iOS, Android (primary), Web/Desktop (secondary)

### Core Services
1. **CameraService** - Video recording management
2. **StorageService** - File management and storage limits
3. **PermissionService** - Cross-platform permissions

### Current Status
- **Version:** 1.0.0+1
- **Stage:** Active Development
- **Git:** Not initialized (recommendation: initialize)

### Critical Paths
- **Source:** `terrain_iq_dashcam/lib/`
- **Docs:** `.claude/` and `docs/`
- **Platform:** `terrain_iq_dashcam/ios/` and `terrain_iq_dashcam/android/`

### Entry Point
- `terrain_iq_dashcam/lib/main.dart`

---

## 🚀 COMMON INITIALIZATION SCENARIOS

### Scenario 1: New AI Session (Claude, GPT, etc.)

**User says:** "Help me with the TerrainIQ Dashcam project"

**AI should:**
1. Run through initialization checklist
2. Read all required documentation
3. Perform project status check
4. Acknowledge rules
5. Confirm ready with summary
6. Ask how to help

### Scenario 2: Quick Question

**User says:** "How does the storage service work?"

**AI should:**
1. Read `.claude/context.md` (quick context)
2. Read `.claude/analysis.md` (detailed info)
3. Review `lib/services/storage_service.dart`
4. Provide detailed answer with code references

### Scenario 3: Feature Development

**User says:** "Add GPS tracking to video recordings"

**AI should:**
1. Complete full initialization checklist
2. Review current GPS-related code
3. Read VideoRecording model
4. Propose implementation plan
5. Confirm plan with user
6. Implement with testing guidance

### Scenario 4: Bug Fix

**User says:** "Camera crashes on iOS"

**AI should:**
1. Complete initialization
2. Read CameraService implementation
3. Review iOS-specific configuration
4. Check permission handling
5. Analyze error patterns
6. Propose fix with testing steps

### Scenario 5: Code Review

**User says:** "Review my storage cleanup code"

**AI should:**
1. Read AGENT_RULES.md (code standards)
2. Review code against Flutter best practices
3. Check error handling
4. Verify disposal patterns
5. Provide detailed feedback

---

## 📋 POST-INITIALIZATION WORKFLOW

### For Each User Request:

1. **Understand Request**
   - Clarify ambiguities
   - Confirm scope
   - Identify affected components

2. **Plan Approach**
   - Review relevant code
   - Consider architecture impact
   - Identify testing requirements
   - Propose solution

3. **Seek Approval**
   - Present plan to user
   - Highlight risks/tradeoffs
   - Get confirmation before proceeding

4. **Execute Work**
   - Follow code standards
   - Implement error handling
   - Add documentation
   - Update tests

5. **Verify Result**
   - Test on physical devices
   - Verify both iOS and Android
   - Check for regressions
   - Update documentation

6. **Report Completion**
   - Summarize changes
   - List testing steps
   - Note any follow-up items

---

## 🔧 TROUBLESHOOTING INITIALIZATION

### Issue: Can't Find Documentation

**Solution:**
- Check `.claude/` directory exists
- Verify in correct project root
- Files may not be initialized yet
- Ask user to run initialization

### Issue: Git Not Available

**Solution:**
- This is expected (not initialized)
- Skip git-related initialization
- Note in session that Git should be initialized
- Proceed with other initialization steps

### Issue: Flutter Doctor Shows Errors

**Solution:**
- Note issues in initialization report
- Inform user of environment problems
- Proceed with caution
- Recommend fixing before major work

### Issue: Can't Access Source Files

**Solution:**
- Verify working directory
- Check file paths in context.md
- Confirm project structure
- Ask user for correct paths

---

## 🎓 LEARNING RESOURCES

### Flutter Documentation
- Official Docs: https://docs.flutter.dev
- Camera Package: https://pub.dev/packages/camera
- Provider: https://pub.dev/packages/provider

### Dart Language
- Language Tour: https://dart.dev/guides/language
- Effective Dart: https://dart.dev/guides/language/effective-dart
- Style Guide: https://dart.dev/guides/language/effective-dart/style

### Platform-Specific
- iOS Camera: AVFoundation documentation
- Android Camera: Camera2 API documentation
- Permissions: platform_handler package docs

---

## 📝 INITIALIZATION SCRIPT

For automated initialization, AI can use this workflow:

```
FUNCTION initialize_ai_session():

  STEP 1: Load Context
    READ .claude/context.md
    READ .claude/analysis.md
    READ .claude/AGENT_RULES.md
    READ terrain_iq_dashcam/README.md

  STEP 2: Analyze Git (if available)
    IF git_repository_exists:
      RUN git log analysis
      GENERATE report
    ELSE:
      SKIP (note in report)

  STEP 3: Acknowledge Rules
    CONFIRM behavioral rules
    COMMIT to memory

  STEP 4: Check Project Status
    RUN flutter doctor
    RUN flutter analyze
    CHECK devices

  STEP 5: Report Ready
    DISPLAY initialization summary
    CONFIRM ready for work
    ASK how to help

  RETURN initialization_complete
```

---

## ✅ SESSION COMPLETION CHECKLIST

At end of work session:

- [ ] All changes documented
- [ ] Code follows standards
- [ ] Tests provided or updated
- [ ] Documentation updated
- [ ] User notified of completion
- [ ] Next steps identified
- [ ] Pending TODOs noted

---

## 🔄 RE-INITIALIZATION

**When to re-initialize:**
- New chat session
- Project structure changed
- Major dependency updates
- Long time since last session
- Uncertainty about current state

**Quick re-initialization:**
1. Read `.claude/context.md` (refresh memory)
2. Check git history (if available)
3. Verify current project status
4. Confirm ready

---

**End of Initialization Guide**

*Follow this guide to ensure consistent, informed, and safe AI assistance on the TerrainIQ Dashcam project.*
