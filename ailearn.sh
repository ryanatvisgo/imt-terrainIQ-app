#!/bin/bash

# ailearn.sh - Load TerrainIQ Dashcam context for AI assistants
# Tell Claude: "Run ./ailearn.sh" at the start of any session

echo "🤖 Loading TerrainIQ Dashcam context for AI assistant..."
echo "============================================================="

# Check if we're in the right directory
if [[ ! -d ".claude" ]]; then
    echo "❌ Error: .claude directory not found!"
    echo "   Navigate to project root directory first"
    echo "   Expected path: /Users/ryan-bookmarked/platform/intellimass/TerrainIQ/"
    exit 1
fi

CLAUDE_DIR=".claude"

echo ""
echo "📋 QUICK CONTEXT:"
echo "=================="
cat "$CLAUDE_DIR/context.md"

echo ""
echo "🔍 PROJECT STATUS:"
echo "=================="

# Check if Git is initialized
if [[ -d ".git" ]]; then
    echo "Current branch: $(git branch --show-current)"
    echo ""
    echo "Recent changes:"
    git status --short
    echo ""
    echo "Last 5 commits:"
    git log --oneline -5
else
    echo "⚠️  Git repository: NOT INITIALIZED"
    echo "   Recommendation: Initialize Git for version control"
    echo ""
    echo "   To initialize:"
    echo "   $ git init"
    echo "   $ git add ."
    echo "   $ git commit -m 'Initial commit'"
fi

echo ""
echo "📁 Claude Code Documentation:"
echo "=============================="
ls -1 "$CLAUDE_DIR"/*.md 2>/dev/null | while read file; do
    echo "• $(basename "$file")"
done

echo ""
echo "📱 Flutter Project Status:"
echo "==========================="
cd terrain_iq_dashcam 2>/dev/null && {
    echo "Flutter version: $(flutter --version 2>&1 | head -1)"
    echo "Project version: $(grep '^version:' pubspec.yaml | awk '{print $2}')"
    echo ""
    echo "Key dependencies:"
    grep -E '^\s+(camera|geolocator|provider|permission_handler):' pubspec.yaml
    cd ..
} || {
    echo "⚠️  Could not access terrain_iq_dashcam directory"
}

echo ""
echo "✅ CONTEXT LOADED! Ready for AI assistance."
echo "============================================"
echo ""
echo "🚀 QUICK START CHECKLIST FOR AI:"
echo "=================================="
echo "• Read .claude/context.md (already displayed above)"
echo "• Read .claude/analysis.md (comprehensive system overview)"
echo "• Read .claude/AGENT_RULES.md (behavioral guidelines)"
echo "• Read .claude/ai_session_initialization.md (initialization guide)"
echo "• Review terrain_iq_dashcam/README.md (setup instructions)"
echo ""
echo "📚 For detailed help, ask Claude to read:"
echo "• .claude/analysis.md (system architecture and components)"
echo "• .claude/ai_session_initialization.md (AI initialization protocol)"
echo "• terrain_iq_dashcam/README.md (project setup and usage)"
echo "• terrain_iq_dashcam/REQUIREMENTS.md (functional requirements)"
echo "• terrain_iq_dashcam/UI_REQUIREMENTS_MATRIX.md (comprehensive UI feature matrix)"
echo "• terrain_iq_dashcam/API_SPECIFICATION.md (REST API & MQTT documentation)"
echo "• terrain_iq_dashcam/UI_DESIGN_SYSTEM.md (visual design language & components)"
echo "• terrain_iq_dashcam/SCREEN_ARCHITECTURE.md (screen implementation details)"
echo "• terrain_iq_dashcam/lib/ (source code structure)"
echo ""
echo "🧠 AI INITIALIZATION PROCESS:"
echo "=============================="
echo "1. Run this script (./ailearn.sh) ✅"
echo "2. Read the documentation files listed above"
echo "3. Commit foundational knowledge to memory"

if [[ -d ".git" ]]; then
    echo "4. 🔍 MANDATORY: Run git history analysis and show results"
    echo ""
    echo "🔍 GIT HISTORY ANALYSIS REQUIRED!"
    echo "=================================="
    echo "Claude MUST run these commands and DISPLAY results:"
    echo "• git log --oneline --since=\"2 weeks ago\" --no-merges"
    echo "• git log --since=\"2 weeks ago\" --no-merges --name-only --pretty=format:\"%h %s\" | head -50"
    echo "• git status"
    echo ""
    echo "Then provide structured report (see .claude/AGENT_RULES.md for format)"
else
    echo "4. ⚠️  Git not initialized - skip git history analysis for now"
fi

echo "5. Apply critical workflow rules from .claude/AGENT_RULES.md"
echo "6. Verify understanding via initialization checklist"
echo ""
echo "⚠️  MANDATORY SESSION ACKNOWLEDGMENT"
echo "====================================="
echo "After completing initialization, Claude MUST acknowledge:"
echo ""
echo "🔒 CRITICAL BEHAVIORAL RULES:"
echo "• NEVER use 'git add .' - always stage files individually"
echo "• NEVER modify config files without explicit permission"
echo "• ALWAYS ask permission before staging files for commit"
echo "• NEVER do destructive updates without warning"
echo "• NEVER modify pubspec.yaml without approval"
echo "• ALWAYS run 'flutter pub get' after dependency changes"
echo "• ALWAYS test camera features on physical devices"
echo ""
echo "🎯 SESSION INITIALIZATION COMPLETE WHEN:"
if [[ -d ".git" ]]; then
    echo "• Git history analysis shown with structured report"
fi
echo "• All critical behavioral rules acknowledged"
echo "• Ready to work with current project context and priorities"
echo ""
echo "💡 Claude: Show your understanding by providing the complete"
echo "   initialization report including rules acknowledgment!"
echo ""
echo "📋 PROJECT QUICK REFERENCE:"
echo "==========================="
echo "Framework: Flutter (Dart)"
echo "Platform: iOS, Android, Web, Desktop"
echo "State Management: Provider pattern"
echo "Version: 1.0.0+1"
echo "Stage: Active Development"
echo ""
echo "Core Services:"
echo "• CameraService - Video recording management"
echo "• StorageService - File management and storage limits"
echo "• PermissionService - Cross-platform permissions"
echo ""
echo "Key Features Implemented:"
echo "• Camera integration with video recording"
echo "• Permission management"
echo "• Local file storage with auto-cleanup"
echo "• Recording list and basic playback"
echo ""
echo "In Progress:"
echo "• GPS tracking integration"
echo "• Settings UI"
echo "• Enhanced video playback"
echo ""
echo "🔧 Common Development Commands:"
echo "================================"
echo "cd terrain_iq_dashcam"
echo "flutter pub get              # Install dependencies"
echo "flutter run                  # Run on connected device"
echo "flutter doctor               # Check environment"
echo "flutter analyze              # Run static analysis"
echo "flutter build apk --release  # Build Android release"
echo "flutter build ios --release  # Build iOS release"
echo ""
echo "🎉 Ready to assist with TerrainIQ Dashcam development!"
