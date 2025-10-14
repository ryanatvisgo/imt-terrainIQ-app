#!/usr/bin/env node

/**
 * Simple MQTT Broker for TerrainIQ Dashcam Simulator
 * Provides MQTT over TCP (1883) and WebSocket (9001)
 */

const aedes = require('aedes')();
const net = require('net');
const http = require('http');
const ws = require('websocket-stream');

const MQTT_PORT = 1883;
const WS_PORT = 9001;

// MQTT over TCP
const mqttServer = net.createServer(aedes.handle);
mqttServer.listen(MQTT_PORT, () => {
  console.log('✅ MQTT Broker listening on port', MQTT_PORT);
});

// MQTT over WebSocket
const httpServer = http.createServer();
ws.createServer({ server: httpServer }, aedes.handle);
httpServer.listen(WS_PORT, () => {
  console.log('✅ MQTT WebSocket listening on port', WS_PORT);
  console.log('');
  console.log('📡 MQTT Broker Ready!');
  console.log('   MQTT:      mqtt://localhost:' + MQTT_PORT);
  console.log('   WebSocket: ws://localhost:' + WS_PORT);
  console.log('');
});

// Event handlers
aedes.on('client', (client) => {
  console.log('🔌 Client connected:', client.id);
});

aedes.on('clientDisconnect', (client) => {
  console.log('🔌 Client disconnected:', client.id);
});

aedes.on('publish', (packet, client) => {
  if (client && !packet.topic.startsWith('$SYS')) {
    console.log('📨 Message from', client.id, '→', packet.topic);
  }
});

aedes.on('subscribe', (subscriptions, client) => {
  subscriptions.forEach((sub) => {
    console.log('📬 Client', client.id, 'subscribed to:', sub.topic);
  });
});

// Error handlers
mqttServer.on('error', (err) => {
  console.error('❌ MQTT Server Error:', err);
  process.exit(1);
});

httpServer.on('error', (err) => {
  console.error('❌ HTTP Server Error:', err);
  process.exit(1);
});

process.on('SIGINT', () => {
  console.log('');
  console.log('🛑 Shutting down MQTT broker...');
  aedes.close(() => {
    console.log('✅ MQTT broker closed');
    process.exit(0);
  });
});

console.log('🚀 Starting MQTT Broker...');
