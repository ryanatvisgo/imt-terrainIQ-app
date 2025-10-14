#!/bin/bash

echo "========================================="
echo "  TerrainIQ Dashcam - Stopping All Services"
echo "========================================="
echo ""

echo "🛑 Stopping MQTT broker..."
pkill -f "node.*mqtt_broker.js" 2>/dev/null && echo "   MQTT broker stopped" || echo "   No MQTT broker running"

echo ""
echo "🛑 Stopping mock server..."
pkill -f "node.*server.js" 2>/dev/null && echo "   Mock server stopped" || echo "   No mock server running"

echo ""
echo "🛑 Stopping Flutter app..."
pkill -f "flutter.*chrome.*3201" 2>/dev/null && echo "   Flutter app stopped" || echo "   No Flutter app running"

echo ""
echo "========================================="
echo "  All services stopped!"
echo "========================================="
echo ""
