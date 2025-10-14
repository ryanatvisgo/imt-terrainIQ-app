#!/bin/bash

# TerrainIQ Dashcam - HTML Simulator + Flutter Web Integration Launcher
# This script starts all required services for the integrated simulator

set -e

echo "🚀 TerrainIQ Dashcam Simulator Launcher"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if mosquitto is installed
if ! command -v mosquitto &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Mosquitto MQTT broker not found${NC}"
    echo "Install with: brew install mosquitto (macOS) or apt-get install mosquitto (Linux)"
    echo ""
    echo "Continuing without MQTT (HTML-only mode will work)..."
    MQTT_AVAILABLE=false
else
    MQTT_AVAILABLE=true
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter not found${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down services..."

    # Kill background jobs
    jobs -p | xargs -r kill 2>/dev/null || true

    # Stop mosquitto if we started it
    if [ "$MQTT_AVAILABLE" = true ]; then
        if pgrep -x "mosquitto" > /dev/null; then
            echo "Stopping Mosquitto..."
            brew services stop mosquitto &>/dev/null || sudo systemctl stop mosquitto &>/dev/null || true
        fi
    fi

    echo "✅ Cleanup complete"
    exit 0
}

trap cleanup EXIT INT TERM

# Start Mosquitto MQTT Broker
if [ "$MQTT_AVAILABLE" = true ]; then
    echo "📡 Starting MQTT Broker (Mosquitto)..."

    # Check if already running
    if pgrep -x "mosquitto" > /dev/null; then
        echo -e "${GREEN}✓ Mosquitto already running${NC}"
    else
        # Try to start with brew services (macOS) or systemctl (Linux)
        if command -v brew &> /dev/null; then
            brew services start mosquitto &>/dev/null && echo -e "${GREEN}✓ Mosquitto started via Homebrew${NC}" || true
        elif command -v systemctl &> /dev/null; then
            sudo systemctl start mosquitto &>/dev/null && echo -e "${GREEN}✓ Mosquitto started via systemd${NC}" || true
        fi
    fi

    # Verify ports are open
    sleep 2
    if lsof -i :9001 &>/dev/null && lsof -i :1883 &>/dev/null; then
        echo -e "${GREEN}✓ MQTT broker listening on ports 1883 (MQTT) and 9001 (WebSocket)${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: MQTT ports may not be fully available${NC}"
    fi
    echo ""
fi

# Start Flutter Web App
echo "📱 Starting Flutter Web App..."
cd terrain_iq_dashcam

# Kill any existing flutter web process on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Start Flutter Web in background
flutter run -d chrome --web-port 8080 &>/dev/null &
FLUTTER_PID=$!

echo -e "${GREEN}✓ Flutter Web starting on http://localhost:8080${NC}"
echo "   Preview mode: http://localhost:8080/#/preview"
echo ""

# Wait for Flutter to be ready
echo "⏳ Waiting for Flutter Web to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Flutter Web is ready!${NC}"
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Flutter Web failed to start${NC}"
        exit 1
    fi
done
echo ""

# Start HTML Simulator
echo "🎮 Starting HTML Simulator..."
cd ..

# Kill any existing process on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Start simple HTTP server for HTML simulator
python3 -m http.server 3001 &>/dev/null &
SIMULATOR_PID=$!

echo -e "${GREEN}✓ HTML Simulator running on http://localhost:3001${NC}"
echo ""

# Summary
echo "========================================"
echo "✅ All Services Running!"
echo "========================================"
echo ""
echo "📊 Service URLs:"
echo "  • HTML Simulator:  http://localhost:3001/app_simulator.html"
echo "  • Flutter Web:     http://localhost:8080"
echo "  • Flutter Preview: http://localhost:8080/#/preview"
if [ "$MQTT_AVAILABLE" = true ]; then
    echo "  • MQTT Broker:     localhost:1883 (MQTT) / localhost:9001 (WebSocket)"
fi
echo ""
echo "🎯 Next Steps:"
echo "  1. Open http://localhost:3001/app_simulator.html in your browser"
if [ "$MQTT_AVAILABLE" = true ]; then
    echo "  2. Check MQTT status (should show 'Connected' in green)"
    echo "  3. Click 'Flutter App' button to switch to live Flutter UI"
    echo "  4. Adjust controls and watch Flutter app respond in real-time!"
else
    echo "  2. Use HTML Simulator mode (MQTT not available)"
    echo "  3. Install Mosquitto to enable Flutter App mode"
fi
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Keep script running
wait
