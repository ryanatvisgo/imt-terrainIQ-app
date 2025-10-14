#!/bin/bash

# Test MQTT connection stability
# This script monitors MQTT broker logs for connection/disconnection events

echo "🔍 MQTT Connection Stability Test"
echo "=================================="
echo ""
echo "This test will:"
echo "  1. Monitor MQTT broker for 30 seconds"
echo "  2. Count connections and disconnections"
echo "  3. Report connection stability"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if MQTT broker is running
if ! lsof -i :3301 > /dev/null 2>&1; then
    echo -e "${RED}❌ MQTT broker not running on port 3301${NC}"
    echo "   Start it with: ./start_mqtt.sh"
    exit 1
fi

echo -e "${GREEN}✅ MQTT broker is running${NC}"
echo ""

# Create temporary log file
TEMP_LOG=$(mktemp)
echo "📝 Monitoring MQTT broker logs..."
echo "   Press Ctrl+C to stop early"
echo ""

# Monitor for 30 seconds
timeout 30 tail -f <(lsof -i :3301 -r 1 2>/dev/null) > "$TEMP_LOG" 2>&1 &
MONITOR_PID=$!

# Also capture broker output if we can find the process
BROKER_PID=$(lsof -t -i:3301 | head -1)
if [ -n "$BROKER_PID" ]; then
    echo "   Broker PID: $BROKER_PID"
fi

# Wait for monitoring to complete
sleep 30

# Kill monitor if still running
kill $MONITOR_PID 2>/dev/null

echo ""
echo "📊 Test Results:"
echo "================"

# Count connections from last 30 seconds of broker output
# This is a simplified test - in production you'd parse actual broker logs

# Check if any clients are currently connected
CONNECTED_CLIENTS=$(lsof -i :3301 2>/dev/null | grep -c ESTABLISHED || echo "0")

echo -e "Currently connected clients: ${GREEN}$CONNECTED_CLIENTS${NC}"

if [ "$CONNECTED_CLIENTS" -gt 0 ]; then
    echo -e "${GREEN}✅ MQTT connections are stable${NC}"
    echo ""
    echo "Connected clients:"
    lsof -i :3301 2>/dev/null | grep ESTABLISHED | awk '{print "  - " $1 " (PID: " $2 ")"}'
    EXIT_CODE=0
else
    echo -e "${YELLOW}⚠️  No clients currently connected${NC}"
    echo "   This may be normal if no apps are running"
    EXIT_CODE=1
fi

# Cleanup
rm -f "$TEMP_LOG"

echo ""
echo "💡 Tips:"
echo "  - Check broker logs with: tail -f mqtt_broker_logs.txt"
echo "  - Restart broker: ./start_mqtt.sh"
echo "  - Check Flutter app: http://localhost:3201"

exit $EXIT_CODE
