#!/bin/bash

# TerrainIQ MQTT Log Monitor
# Shows live MQTT communication with 1-second refresh
# Log automatically rotates to keep only last 5 minutes of data

LOG_FILE="mqtt_log.txt"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_PATH="$SCRIPT_DIR/$LOG_FILE"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Clear screen and show header
clear
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚗 TerrainIQ MQTT Monitor${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Watching:${NC} $LOG_FILE"
echo -e "${YELLOW}Refresh:${NC} 1 second"
echo -e "${YELLOW}Retention:${NC} Last 5 minutes (300 lines max)"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# Check if log file exists
if [ ! -f "$LOG_PATH" ]; then
    echo -e "${RED}⚠️  Log file not found: $LOG_FILE${NC}"
    echo "Make sure the MQTT server is running."
    echo ""
    echo "To start the server:"
    echo "  node server_mqtt.js"
    exit 1
fi

# Tail the log file with follow mode (-f)
# Shows last 30 lines initially, then follows new additions
tail -f -n 30 "$LOG_PATH"
