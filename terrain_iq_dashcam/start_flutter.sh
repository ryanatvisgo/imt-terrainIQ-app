#!/bin/bash

# Kill any existing Flutter web server processes
echo "🔄 Stopping existing Flutter app..."
pkill -f "flutter.*web.*3201" 2>/dev/null || echo "   No existing Flutter app found"

# Wait a moment for the process to terminate
sleep 2

# Start Flutter app in headless web-server mode (no browser popup)
# Access via iframe in HTML simulator or directly at http://localhost:3201
echo "🚀 Starting Flutter app on port 3201 (headless mode)..."
echo "   Access via: http://localhost:3201"
echo "   Or embedded in simulator iframe"
flutter run -d web-server --web-port=3201 --web-hostname=0.0.0.0
