const aedes = require('aedes')();
const server = require('net').createServer(aedes.handle);
const httpServer = require('http').createServer();
const ws = require('websocket-stream');

const MQTT_PORT = 1883;
const WS_PORT = 3301;

// TCP server for native MQTT
server.listen(MQTT_PORT, function () {
  console.log(`MQTT Broker listening on port ${MQTT_PORT}`);
});

// WebSocket server for browser clients
ws.createServer({ server: httpServer }, aedes.handle);
httpServer.listen(WS_PORT, function () {
  console.log(`MQTT WebSocket listening on port ${WS_PORT}`);
  console.log(`Web clients can connect to: ws://localhost:${WS_PORT}`);
});

// Log client connections with timestamp
aedes.on('client', function (client) {
  const timestamp = new Date().toISOString();
  console.log(`\n✅ [${timestamp}] Client connected: ${client.id}`);
});

// Log client disconnections with timestamp
aedes.on('clientDisconnect', function (client) {
  const timestamp = new Date().toISOString();
  console.log(`\n❌ [${timestamp}] Client disconnected: ${client.id}`);
});

// Log connection errors
aedes.on('clientError', function (client, err) {
  const timestamp = new Date().toISOString();
  console.log(`\n⚠️  [${timestamp}] Client error (${client.id}): ${err.message}`);
});

// Log keepalive timeouts
aedes.on('keepaliveTimeout', function (client) {
  const timestamp = new Date().toISOString();
  console.log(`\n⏱️  [${timestamp}] Keepalive timeout: ${client.id}`);
});

// Log published messages with payload
aedes.on('publish', async function (packet, client) {
  if (client && !packet.topic.startsWith('$SYS')) {
    const payload = packet.payload.toString();
    console.log(`\n📨 Message from ${client.id}:`);
    console.log(`   Topic: ${packet.topic}`);
    console.log(`   Payload: ${payload}`);
  }
});

console.log('TerrainIQ MQTT Broker started');
console.log('----------------------------------');
console.log('Configuration:');
console.log(`  TCP Port:       ${MQTT_PORT}`);
console.log(`  WebSocket Port: ${WS_PORT}`);
console.log('----------------------------------');
