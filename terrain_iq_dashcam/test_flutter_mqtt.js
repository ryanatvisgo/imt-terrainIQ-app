/**
 * Browser test script for Flutter MQTT integration
 * This script connects to the MQTT broker and sends various messages
 * to test that the Flutter app responds to real-time setting changes
 */

const mqtt = require('mqtt');

// Configuration
const MQTT_BROKER = 'ws://localhost:3301';
const CLIENT_ID = 'test_flutter_mqtt_' + Math.random().toString(16).substr(2, 8);

// MQTT Topics
const TOPICS = {
  PREVIEW_ENABLE: 'terrainiq/simulator/preview/enable',
  PREVIEW_VIEW: 'terrainiq/simulator/preview/view',
  PREVIEW_HAZARD: 'terrainiq/simulator/preview/hazard',
  PREVIEW_VEHICLE: 'terrainiq/simulator/preview/vehicle',
  PREVIEW_RECORDING: 'terrainiq/simulator/preview/recording',
  PREVIEW_ORIENTATION: 'terrainiq/simulator/preview/orientation',
  FLUTTER_STATUS: 'terrainiq/flutter/preview/status'
};

console.log('='.repeat(60));
console.log('Flutter MQTT Integration Test');
console.log('='.repeat(60));
console.log(`Connecting to: ${MQTT_BROKER}`);
console.log(`Client ID: ${CLIENT_ID}`);
console.log('='.repeat(60));

// Connect to MQTT broker
const client = mqtt.connect(MQTT_BROKER, {
  clientId: CLIENT_ID,
  clean: true,
  keepalive: 60
});

client.on('connect', () => {
  console.log('\n✅ Connected to MQTT broker');

  // Subscribe to Flutter status messages
  client.subscribe(TOPICS.FLUTTER_STATUS, { qos: 1 }, (err) => {
    if (err) {
      console.error('❌ Failed to subscribe to Flutter status:', err);
    } else {
      console.log('✅ Subscribed to Flutter status topic\n');
    }
  });

  // Enable preview mode
  console.log('📤 Step 1: Enabling preview mode...');
  client.publish(TOPICS.PREVIEW_ENABLE, JSON.stringify({ enabled: true }), { qos: 1 });

  // Test sequence - gradually change settings and give time to observe
  let step = 1;

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Setting view to HUD Only (page 1)...`);
    client.publish(TOPICS.PREVIEW_VIEW, JSON.stringify({ page: 1 }), { qos: 1 });
  }, 2000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Setting hazard - Low severity (3), 500m distance...`);
    client.publish(TOPICS.PREVIEW_HAZARD, JSON.stringify({
      distance: 500,
      severity: 3,
      type: 'POTHOLE AHEAD',
      nextHazardDistance: 750,
      icon: '⚠️'
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Background should be YELLOW-GREEN (low severity)');
  }, 4000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Increasing severity to 6 (medium)...`);
    client.publish(TOPICS.PREVIEW_HAZARD, JSON.stringify({
      distance: 400,
      severity: 6,
      type: 'ROUGH ROAD AHEAD',
      nextHazardDistance: 650,
      icon: '🌊'
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Background should change to ORANGE (medium severity)');
  }, 7000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: High severity warning (9)...`);
    client.publish(TOPICS.PREVIEW_HAZARD, JSON.stringify({
      distance: 200,
      severity: 9,
      type: 'CRITICAL HAZARD',
      nextHazardDistance: 500,
      icon: '🚨'
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Background should change to RED (high severity)');
  }, 10000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Changing view to HUD + Camera PIP (page 2)...`);
    client.publish(TOPICS.PREVIEW_VIEW, JSON.stringify({ page: 2 }), { qos: 1 });
    console.log('   👁️  OBSERVE: Camera thumbnail should appear in bottom-right corner');
  }, 13000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Updating vehicle - 85 km/h, moving...`);
    client.publish(TOPICS.PREVIEW_VEHICLE, JSON.stringify({
      speed: 85,
      moving: true,
      latitude: 49.8203,
      longitude: -119.4916,
      heading: 45
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Speed should change to "85 km/h" in header');
  }, 16000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Vehicle stopped...`);
    client.publish(TOPICS.PREVIEW_VEHICLE, JSON.stringify({
      speed: 0,
      moving: false,
      latitude: 49.8203,
      longitude: -119.4916,
      heading: 45
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Speed should change to "STOPPED" in header');
  }, 19000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Changing to Camera Full Screen (page 3)...`);
    client.publish(TOPICS.PREVIEW_VIEW, JSON.stringify({ page: 3 }), { qos: 1 });
    console.log('   👁️  OBSERVE: Should show full-screen camera with hazard overlay');
  }, 22000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Switching to landscape orientation...`);
    client.publish(TOPICS.PREVIEW_ORIENTATION, JSON.stringify({ orientation: 'landscape' }), { qos: 1 });
    console.log('   👁️  OBSERVE: Layout should switch to landscape mode');
  }, 25000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Back to portrait orientation...`);
    client.publish(TOPICS.PREVIEW_ORIENTATION, JSON.stringify({ orientation: 'portrait' }), { qos: 1 });
    console.log('   👁️  OBSERVE: Layout should switch back to portrait mode');
  }, 28000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Toggle recording off...`);
    client.publish(TOPICS.PREVIEW_RECORDING, JSON.stringify({
      recording: false,
      autoRecord: true,
      manualOverride: false
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Recording indicator should disappear from header');
  }, 31000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Toggle recording on...`);
    client.publish(TOPICS.PREVIEW_RECORDING, JSON.stringify({
      recording: true,
      autoRecord: false,
      manualOverride: true
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Red recording indicator should reappear');
  }, 34000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Back to HUD view (page 1)...`);
    client.publish(TOPICS.PREVIEW_VIEW, JSON.stringify({ page: 1 }), { qos: 1 });
  }, 37000);

  setTimeout(() => {
    step++;
    console.log(`\n📤 Step ${step}: Setting to all clear state...`);
    client.publish(TOPICS.PREVIEW_HAZARD, JSON.stringify({
      distance: 800,
      severity: 1,
      type: 'ALL CLEAR',
      nextHazardDistance: 0,
      icon: '✅'
    }), { qos: 1 });
    console.log('   👁️  OBSERVE: Background should change to GREEN (all clear)');
  }, 40000);

  // End test
  setTimeout(() => {
    console.log('\n' + '='.repeat(60));
    console.log('✅ Test sequence complete!');
    console.log('='.repeat(60));
    console.log('\nDisconnecting...');
    client.end();
    process.exit(0);
  }, 43000);
});

client.on('message', (topic, message) => {
  if (topic === TOPICS.FLUTTER_STATUS) {
    console.log('\n📥 Received Flutter status:', message.toString());
  }
});

client.on('error', (err) => {
  console.error('\n❌ MQTT Error:', err.message);
  process.exit(1);
});

client.on('close', () => {
  console.log('\n👋 Disconnected from MQTT broker');
});

// Handle Ctrl+C gracefully
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Test interrupted by user');
  client.end();
  process.exit(0);
});
