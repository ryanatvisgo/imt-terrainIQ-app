#!/bin/bash

# Kill any existing Flutter Chrome processes
echo "🔄 Stopping existing Flutter app..."
pkill -f "flutter.*chrome.*3201" 2>/dev/null || echo "   No existing Flutter app found"

# Wait a moment for the process to terminate
sleep 2

# Start Flutter app
echo "🚀 Starting Flutter app on port 3201..."
flutter run -d chrome --web-port=3201
