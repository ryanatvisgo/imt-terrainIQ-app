import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

/// Service to handle MQTT communication with the server
/// Publishes real-time updates about device location, status, and proximity
class MqttService extends ChangeNotifier {
  MqttServerClient? _client;
  String _deviceId = '';
  bool _isConnected = false;
  Timer? _reconnectTimer;

  // Connection settings
  static const String _broker = '192.168.8.105'; // Mac IP address (same as server)
  static const int _port = 1883;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  // Getters
  bool get isConnected => _isConnected;
  String get deviceId => _deviceId;
  MqttServerClient? get client => _client;

  /// Initialize and connect to MQTT broker
  Future<void> initialize() async {
    // Generate device ID from platform info
    try {
      _deviceId = Platform.isAndroid ? 'android' : 'ios';
      _deviceId += '_${DateTime.now().millisecondsSinceEpoch % 10000}';
    } catch (e) {
      _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    debugPrint('🔌 MqttService: Initializing with device ID: $_deviceId');

    await _connect();
  }

  /// Connect to MQTT broker
  Future<void> _connect() async {
    try {
      _client = MqttServerClient(_broker, _deviceId);
      _client!.port = _port;
      _client!.logging(on: false);
      _client!.keepAlivePeriod = 30;
      _client!.autoReconnect = true;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onAutoReconnect = _onAutoReconnect;
      _client!.onAutoReconnected = _onAutoReconnected;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_deviceId)
          .withWillTopic('terrainiq/device/$_deviceId/status')
          .withWillMessage('{"online": false}')
          .withWillQos(MqttQos.atLeastOnce)
          .keepAliveFor(30)
          .startClean();

      _client!.connectionMessage = connMessage;

      debugPrint('🔌 MqttService: Connecting to broker at $_broker:$_port...');
      await _client!.connect();
    } catch (e) {
      debugPrint('❌ MqttService: Connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Handle successful connection
  void _onConnected() {
    debugPrint('✅ MqttService: Connected to broker');
    _isConnected = true;
    _reconnectTimer?.cancel();
    notifyListeners();

    // Publish online status
    publishStatus(isOnline: true);
  }

  /// Handle disconnection
  void _onDisconnected() {
    debugPrint('📴 MqttService: Disconnected from broker');
    _isConnected = false;
    notifyListeners();
  }

  /// Handle auto-reconnect attempt
  void _onAutoReconnect() {
    debugPrint('🔄 MqttService: Auto-reconnecting...');
  }

  /// Handle successful auto-reconnect
  void _onAutoReconnected() {
    debugPrint('✅ MqttService: Auto-reconnected');
    _isConnected = true;
    notifyListeners();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      debugPrint('🔄 MqttService: Attempting to reconnect...');
      await _connect();
    });
  }

  /// Publish location update (called frequently - every 5s)
  void publishLocation({
    required double? lat,
    required double? lon,
    double? altitude,
    double? speed,
    double? accuracy,
  }) {
    if (!_isConnected || lat == null || lon == null) return;

    final data = {
      'lat': lat,
      'lon': lon,
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _publish('terrainiq/device/$_deviceId/location', data);
  }

  /// Publish status update (called frequently - every 5s)
  void publishStatus({
    bool? isMoving,
    bool? isRecording,
    String? orientation,
    bool? isOnline,
  }) {
    if (!_isConnected) return;

    final data = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (isMoving != null) data['is_moving'] = isMoving;
    if (isRecording != null) data['is_recording'] = isRecording;
    if (orientation != null) data['orientation'] = orientation;
    if (isOnline != null) data['online'] = isOnline;

    _publish('terrainiq/device/$_deviceId/status', data);
  }

  /// Publish proximity alert (called when proximity changes)
  void publishProximity({
    required String proximityLevel,
    required double? distanceToHazard,
    String? hazardLabel,
    int? hazardSeverity,
  }) {
    if (!_isConnected) return;

    final data = {
      'proximity_level': proximityLevel,
      'distance_to_hazard': distanceToHazard,
      'hazard_label': hazardLabel,
      'hazard_severity': hazardSeverity,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _publish('terrainiq/device/$_deviceId/proximity', data);
    debugPrint('⚠️ MqttService: Published proximity alert - $proximityLevel');
  }

  /// Publish health pulse (called every 60s)
  void publishHeartbeat({
    required int batteryLevel,
    required bool isCharging,
    required double availableStorageMb,
    required int uploadQueueSize,
  }) {
    if (!_isConnected) return;

    final data = {
      'battery_level': batteryLevel,
      'is_charging': isCharging,
      'available_storage_mb': availableStorageMb,
      'upload_queue_size': uploadQueueSize,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _publish('terrainiq/device/$_deviceId/heartbeat', data);
    debugPrint('💓 MqttService: Published health pulse');
  }

  /// Publish recording state change
  void publishRecordingState({
    required String state, // 'started' or 'stopped'
    String? fileName,
  }) {
    if (!_isConnected) return;

    final data = {
      'state': state,
      'file_name': fileName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _publish('terrainiq/device/$_deviceId/recording', data);
    debugPrint('🎥 MqttService: Published recording state - $state');
  }

  /// Internal method to publish MQTT messages
  void _publish(String topic, Map<String, dynamic> data) {
    if (_client == null || !_isConnected) return;

    try {
      final payload = jsonEncode(data);
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      debugPrint('❌ MqttService: Error publishing to $topic: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🔌 MqttService: Disposing...');
    _reconnectTimer?.cancel();

    // Publish offline status before disconnecting
    if (_isConnected) {
      publishStatus(isOnline: false);
    }

    _client?.disconnect();
    super.dispose();
  }
}
