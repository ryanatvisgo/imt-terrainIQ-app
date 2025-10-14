#!/bin/bash

echo "========================================="
echo "  TerrainIQ Dashcam - Starting All Services"
echo "========================================="
echo ""

# Kill existing processes
echo "🔄 Stopping existing services..."
pkill -f "node.*mqtt_broker.js" 2>/dev/null
pkill -f "node.*server.js" 2>/dev/null
pkill -f "flutter.*chrome.*3201" 2>/dev/null
echo "   All existing services stopped"
sleep 2

# Start MQTT Broker in background
echo ""
echo "🚀 Starting MQTT broker on ws://localhost:3301..."
node mqtt_broker.js > logs/mqtt.log 2>&1 &
MQTT_PID=$!
echo "   MQTT broker started (PID: $MQTT_PID)"
sleep 1

# Start Mock Server in background
echo ""
echo "🚀 Starting mock server on http://localhost:3000..."
(cd mock_server && node server.js) > logs/server.log 2>&1 &
SERVER_PID=$!
echo "   Mock server started (PID: $SERVER_PID)"
sleep 1

# Start Flutter App in background
echo ""
echo "🚀 Starting Flutter app on http://localhost:3201..."
flutter run -d chrome --web-port=3201 > logs/flutter.log 2>&1 &
FLUTTER_PID=$!
echo "   Flutter app started (PID: $FLUTTER_PID)"

echo ""
echo "========================================="
echo "  All services started successfully!"
echo "========================================="
echo ""
echo "📊 Service URLs:"
echo "   • Simulator:    http://localhost:3000/app_simulator.html"
echo "   • Mock Server:  http://localhost:3000"
echo "   • Flutter App:  http://localhost:3201"
echo "   • MQTT Broker:  ws://localhost:3301"
echo ""
echo "📝 Log files:"
echo "   • MQTT:   logs/mqtt.log"
echo "   • Server: logs/server.log"
echo "   • Flutter: logs/flutter.log"
echo ""
echo "💡 To view logs in real-time:"
echo "   tail -f logs/mqtt.log"
echo "   tail -f logs/server.log"
echo "   tail -f logs/flutter.log"
echo ""
echo "🛑 To stop all services:"
echo "   pkill -f \"node.*mqtt_broker.js\""
echo "   pkill -f \"node.*server.js\""
echo "   pkill -f \"flutter.*chrome.*3201\""
echo ""
