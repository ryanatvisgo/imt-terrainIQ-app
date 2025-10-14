# AI Agent Behavioral Rules - TerrainIQ Dashcam

**Version:** 1.0
**Last Updated:** 2025-10-10

## 🔒 CRITICAL RULES - NEVER VIOLATE

### Git Operations
- **NEVER** use `git add .` - ALWAYS stage files individually
- **NEVER** modify configuration files without explicit user permission
- **ALWAYS** ask permission before staging files for commit
- **NEVER** perform destructive operations without warning (force push, hard reset, etc.)
- **NEVER** commit directly to main/master without explicit approval
- **NEVER** skip hooks (--no-verify, --no-gpg-sign) unless explicitly requested

### File Operations
- **NEVER** modify `pubspec.yaml` without explicit permission
- **NEVER** update platform-specific files (ios/, android/, macos/) without verification
- **NEVER** delete files without confirmation
- **ALWAYS** create backups before destructive operations
- **NEVER** modify `.claude/` files without explicit request

### Flutter-Specific Rules
- **NEVER** upgrade Flutter SDK version without permission
- **NEVER** modify platform configuration without testing implications
- **ALWAYS** run `flutter pub get` after dependency changes
- **NEVER** remove permissions from AndroidManifest.xml or Info.plist without approval
- **ALWAYS** test on physical devices when camera/GPS features are involved

## 🎯 SESSION INITIALIZATION PROTOCOL

### Phase 1: Context Loading
1. User runs `./ailearn.sh` (when available)
2. Read `.claude/context.md` (quick overview)
3. Read `.claude/analysis.md` (system deep dive)
4. Read `.claude/AGENT_RULES.md` (this file)
5. Review `terrain_iq_dashcam/README.md` (setup guide)

### Phase 2: Git History Analysis (WHEN GIT IS INITIALIZED)
**NOTE:** This project is not yet a Git repository. Skip this phase until Git is initialized.

When Git is initialized, Claude MUST run and DISPLAY:
```bash
# Recent commits (2 weeks)
git log --oneline --since="2 weeks ago" --no-merges

# Files changed recently
git log --since="2 weeks ago" --no-merges --name-only --pretty=format:"%h %s" | head -50

# Current branch status
git status
```

**Required Report Format:**
```
📊 GIT HISTORY ANALYSIS REPORT
================================
Time Period: [date range]
Total Commits: [count]
Active Branches: [list]

Recent Development Focus:
• [Pattern 1 - e.g., "iOS permission handling updates"]
• [Pattern 2 - e.g., "Storage service refactoring"]
• [Pattern 3 - e.g., "UI improvements"]

Modified Files Summary:
• [Most frequently changed files]
• [New files added]
• [Deleted/moved files]

Current Priorities (inferred):
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

⚠️ Warnings/Concerns:
• [Any concerning patterns or issues]
================================
```

### Phase 3: Behavioral Rules Acknowledgment
Claude MUST explicitly acknowledge:
```
✅ AGENT RULES ACKNOWLEDGED:
• Git operations: Individual file staging only
• Configuration files: No modifications without permission
• Platform files: No changes without verification
• Flutter operations: Pub get after dependency changes
• Testing: Physical device for camera features
```

### Phase 4: Ready for Work
Claude confirms initialization complete and ready for tasks.

## 📋 CODING STANDARDS

### Flutter/Dart Best Practices
- Follow official Dart style guide
- Use meaningful variable/function names
- Add comments for complex logic
- Implement error handling for all services
- Use const constructors where possible
- Avoid unnecessary widget rebuilds

### State Management
- Use Provider for app-wide state
- Keep state close to where it's used
- Avoid global variables
- Use ChangeNotifier for mutable state
- Dispose controllers/listeners properly

### File Organization
- One widget per file for complex widgets
- Group related files in directories
- Use barrel exports (index.dart) when appropriate
- Keep files under 500 lines when possible

### Error Handling
```dart
try {
  // Operation
} catch (e) {
  // Log error
  debugPrint('Error in [function]: $e');
  // User-friendly message
  // Graceful fallback
}
```

### Permission Handling
- Always check permissions before use
- Request permissions with context/reason
- Handle denied permissions gracefully
- Provide settings deep-link when needed

## 🔍 CODE REVIEW CHECKLIST

Before submitting code:
- [ ] Follows Dart style guide
- [ ] No hardcoded values (use constants)
- [ ] Error handling implemented
- [ ] Comments for complex logic
- [ ] No console.log/print statements (use debugPrint)
- [ ] Disposed resources (controllers, streams)
- [ ] Tested on physical device (if camera/GPS)
- [ ] No breaking changes to existing APIs
- [ ] Dependencies properly declared in pubspec.yaml

## 🚨 COMMON PITFALLS TO AVOID

1. **Camera Service**
   - Don't forget to dispose camera controller
   - Check if camera is initialized before use
   - Handle camera already in use errors
   - Request permissions before camera access

2. **Storage Service**
   - Don't hardcode file paths
   - Check available storage before recording
   - Handle file I/O errors gracefully
   - Clean up temp files

3. **Permission Service**
   - Don't assume permissions granted
   - Check permissions on app resume
   - Handle "denied permanently" state
   - Provide clear permission rationale

4. **State Management**
   - Don't forget to call notifyListeners()
   - Avoid setState() on disposed widgets
   - Don't hold references to BuildContext
   - Use context-independent state

## 🔄 WORKFLOW PATTERNS

### Adding New Feature
1. Discuss architecture/approach with user
2. Create/update model if needed
3. Implement service layer logic
4. Create/update UI widgets
5. Update screen to integrate feature
6. Test on physical device
7. Update documentation

### Fixing Bug
1. Reproduce bug and understand root cause
2. Propose fix approach to user
3. Implement fix with error handling
4. Add logging/debugging aids
5. Test fix thoroughly
6. Document fix in comments

### Refactoring
1. Explain refactoring benefits to user
2. Ensure backward compatibility
3. Refactor incrementally
4. Test after each step
5. Update related documentation

## 📚 DOCUMENTATION REQUIREMENTS

### Code Comments
- Public APIs need dartdoc comments
- Complex algorithms need explanatory comments
- TODOs should include context and assignee
- Magic numbers need explanation

### File Headers
```dart
/// [Brief description of file purpose]
///
/// [Longer description if needed]
///
/// Key components:
/// - [Component 1]
/// - [Component 2]
```

### Commit Messages
```
[type]: [concise description]

[Optional detailed explanation]
[Why this change was made]

Related: [issue/ticket if applicable]
```

Types: feat, fix, refactor, docs, style, test, chore

## 🤝 USER INTERACTION GUIDELINES

### Always Ask Before:
- Modifying configuration files
- Upgrading dependencies
- Changing platform-specific code
- Deleting code/files
- Committing to Git
- Running destructive operations

### Provide Context:
- Explain what you're doing and why
- Show code snippets for complex changes
- Highlight potential risks/side effects
- Suggest alternatives when applicable

### Be Proactive:
- Suggest improvements when spotted
- Warn about potential issues
- Recommend best practices
- Offer to update documentation

## ✅ SESSION COMPLETION

At end of session, Claude should:
1. Summarize changes made
2. List any pending TODOs
3. Suggest next steps
4. Update relevant documentation if needed
5. Remind about testing requirements

## 🔐 SECURITY CONSIDERATIONS

- Never commit API keys or secrets
- Don't log sensitive data
- Validate all user inputs
- Use secure storage for sensitive data
- Follow platform security guidelines
- Request minimum necessary permissions

---

**Remember:** These rules ensure consistent, safe, and high-quality development. When in doubt, ask the user!
