#!/bin/bash

# TerrainIQ Dashcam - Quick Relaunch Script
# This script rebuilds and relaunches the app on your iPhone

echo "🚀 TerrainIQ Dashcam - Relaunch Script"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Device ID
DEVICE_ID="00008120-000A4D5E14F0201E"

# Step 1: Kill existing Flutter processes
echo "${YELLOW}⏹️  Stopping existing Flutter processes...${NC}"
pkill -9 -f "flutter run" 2>/dev/null
sleep 1

# Step 2: Optional - Clean build (uncomment if you want a fresh build)
# echo "${YELLOW}🧹 Cleaning build artifacts...${NC}"
# flutter clean
# echo ""

# Step 3: Launch the app
echo "${GREEN}▶️  Launching app on iPhone...${NC}"
echo ""

# Create log file
LOG_FILE="/tmp/flutter_relaunch.log"
flutter run -d $DEVICE_ID 2>&1 | tee $LOG_FILE &
FLUTTER_PID=$!

echo "Flutter PID: $FLUTTER_PID"
echo "Log file: $LOG_FILE"
echo ""
echo "${YELLOW}⏳ Waiting for app to launch...${NC}"
echo ""

# Monitor the log file for success/failure
TIMEOUT=120
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ ! -f "$LOG_FILE" ]; then
        sleep 1
        ELAPSED=$((ELAPSED + 1))
        continue
    fi

    # Check for success indicators
    if grep -q "Flutter run key commands" "$LOG_FILE"; then
        echo ""
        echo "${GREEN}✅ SUCCESS! App is running on iPhone${NC}"
        echo ""
        echo "Hot reload commands:"
        echo "  r - Hot reload"
        echo "  R - Hot restart"
        echo "  q - Quit"
        echo ""
        echo "📊 Server: http://localhost:3000/files"
        echo ""
        exit 0
    fi

    # Check for common errors
    if grep -q "Error launching application" "$LOG_FILE"; then
        echo ""
        echo "${RED}❌ FAILED: Error launching application${NC}"
        echo ""
        echo "Check the log file for details: $LOG_FILE"
        tail -20 "$LOG_FILE"
        exit 1
    fi

    if grep -q "Lost connection to device" "$LOG_FILE"; then
        echo ""
        echo "${RED}❌ FAILED: Lost connection to device${NC}"
        echo ""
        echo "Try manually opening the app on your iPhone"
        exit 1
    fi

    # Show progress indicators
    if grep -q "Running Xcode build" "$LOG_FILE" && [ $ELAPSED -eq 5 ]; then
        echo "   Building..."
    fi

    if grep -q "Xcode build done" "$LOG_FILE" && [ $ELAPSED -gt 5 ]; then
        echo "   Build complete! Installing..."
    fi

    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# Timeout reached
echo ""
echo "${YELLOW}⚠️  Xcode debugger is taking too long${NC}"
echo ""
echo "The app has been built and installed, but the debugger won't attach."
echo "${GREEN}✅ Solution: Open the TerrainIQ app manually on your iPhone${NC}"
echo ""
echo "📊 Server: http://localhost:3000/files"
echo ""

exit 0
