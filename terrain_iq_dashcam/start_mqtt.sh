#!/bin/bash

# Kill any existing MQTT broker processes
echo "🔄 Stopping existing MQTT broker..."
pkill -f "node.*mqtt_broker.js" 2>/dev/null || echo "   No existing broker found"

# Wait a moment for the process to terminate
sleep 1

# Start the MQTT broker
echo "🚀 Starting MQTT broker..."
node mqtt_broker.js
