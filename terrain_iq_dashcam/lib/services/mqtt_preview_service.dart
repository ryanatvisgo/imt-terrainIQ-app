import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

/// Service for MQTT-based preview mode integration with HTML simulator
/// Allows the HTML simulator to control the Flutter Web app in real-time
class MqttPreviewService extends ChangeNotifier {
  MqttBrowserClient? _client;
  bool _isConnected = false;
  bool _previewEnabled = false;

  // Preview state from HTML simulator
  PreviewState _previewState = PreviewState();

  // MQTT Configuration
  static const String _clientId = 'flutter_dashcam_preview';

  // MQTT Topics
  static const String _topicPreviewEnable = 'terrainiq/simulator/preview/enable';
  static const String _topicPreviewView = 'terrainiq/simulator/preview/view';
  static const String _topicPreviewHazard = 'terrainiq/simulator/preview/hazard';
  static const String _topicPreviewVehicle = 'terrainiq/simulator/preview/vehicle';
  static const String _topicPreviewRecording = 'terrainiq/simulator/preview/recording';
  static const String _topicPreviewOrientation = 'terrainiq/simulator/preview/orientation';
  static const String _topicFlutterStatus = 'terrainiq/flutter/preview/status';

  bool get isConnected => _isConnected;
  bool get previewEnabled => _previewEnabled;
  PreviewState get previewState => _previewState;

  /// Initialize MQTT connection for preview mode
  Future<void> connect() async {
    if (!kIsWeb) {
      debugPrint('MQTT Preview Service only available on web platform');
      return;
    }

    try {
      // Use full WebSocket URL - withPort() has a bug that defaults to port 1883
      _client = MqttBrowserClient('ws://localhost:3301', _clientId);
      _client!.logging(on: true); // Enable logging for debugging
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = true;
      // Set websocket protocols to match what MQTT.js uses
      _client!.websocketProtocols = ['mqtt'];
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      _client!.connectionMessage = connMessage;

      debugPrint('MQTT: Connecting to broker at ws://localhost:3301 via WebSocket');
      final status = await _client!.connect();

      if (status == null || status.state != MqttConnectionState.connected) {
        debugPrint('MQTT: Connection failed - Status: ${status?.state}');
        debugPrint('MQTT: Return code: ${status?.returnCode}');
        _isConnected = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('MQTT: Connection exception - $e');
      debugPrint('MQTT: Stack trace: $stackTrace');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    debugPrint('MQTT: Connected to broker');
    _isConnected = true;

    // Subscribe to preview topics
    _client!.subscribe(_topicPreviewEnable, MqttQos.atLeastOnce);
    _client!.subscribe(_topicPreviewView, MqttQos.atLeastOnce);
    _client!.subscribe(_topicPreviewHazard, MqttQos.atLeastOnce);
    _client!.subscribe(_topicPreviewVehicle, MqttQos.atLeastOnce);
    _client!.subscribe(_topicPreviewRecording, MqttQos.atLeastOnce);
    _client!.subscribe(_topicPreviewOrientation, MqttQos.atLeastOnce);

    // Publish initial status
    _publishStatus();

    // Listen for messages
    _client!.updates!.listen(_onMessage);

    notifyListeners();
  }

  void _onDisconnected() {
    debugPrint('MQTT: Disconnected from broker');
    _isConnected = false;
    _previewEnabled = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT: Subscribed to $topic');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        (message.payload as MqttPublishMessage).payload.message,
      );

      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _handleMessage(topic, data);
      } catch (e) {
        debugPrint('MQTT: Failed to parse message from $topic - $e');
      }
    }
  }

  void _handleMessage(String topic, Map<String, dynamic> data) {
    switch (topic) {
      case _topicPreviewEnable:
        _previewEnabled = data['enabled'] as bool? ?? false;
        debugPrint('MQTT: Preview mode ${_previewEnabled ? "enabled" : "disabled"}');
        _publishStatus();
        break;

      case _topicPreviewView:
        _previewState.page = (data['page'] as num?)?.toInt() ?? 1;
        debugPrint('MQTT: View update - page: ${_previewState.page}');
        break;

      case _topicPreviewHazard:
        _previewState.distance = (data['distance'] as num?)?.toDouble() ?? 0;
        _previewState.severity = (data['severity'] as num?)?.toInt() ?? 0;
        _previewState.hazardType = data['type'] as String? ?? 'POTHOLE AHEAD';
        _previewState.icon = data['icon'] as String? ?? '⚠️';
        _previewState.nextHazardDistance = (data['nextHazardDistance'] as num?)?.toDouble() ?? 0;
        debugPrint('MQTT: Hazard update - distance: ${_previewState.distance}m, severity: ${_previewState.severity}');
        break;

      case _topicPreviewVehicle:
        _previewState.speed = (data['speed'] as num?)?.toDouble() ?? 0;
        _previewState.moving = data['moving'] as bool? ?? false;
        _previewState.latitude = (data['latitude'] as num?)?.toDouble();
        _previewState.longitude = (data['longitude'] as num?)?.toDouble();
        debugPrint('MQTT: Vehicle update - speed: ${_previewState.speed} km/h, moving: ${_previewState.moving}');
        break;

      case _topicPreviewRecording:
        _previewState.recording = data['recording'] as bool? ?? false;
        _previewState.autoRecord = data['autoRecord'] as bool? ?? true;
        debugPrint('MQTT: Recording update - recording: ${_previewState.recording}, auto: ${_previewState.autoRecord}');
        break;

      case _topicPreviewOrientation:
        _previewState.orientation = data['orientation'] as String? ?? 'portrait';
        debugPrint('MQTT: Orientation update - ${_previewState.orientation}');
        break;
    }

    notifyListeners();
  }

  void _publishStatus() {
    if (_client == null || !_isConnected) return;

    final status = jsonEncode({
      'ready': true,
      'mode': _previewEnabled ? 'preview' : 'normal',
      'timestamp': DateTime.now().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(status);

    _client!.publishMessage(
      _topicFlutterStatus,
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    debugPrint('MQTT: Published status');
  }

  /// Disconnect from MQTT broker
  Future<void> disconnect() async {
    if (_client != null) {
      _client!.disconnect();
      _client = null;
    }
    _isConnected = false;
    _previewEnabled = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Preview state data from HTML simulator
class PreviewState {
  int page = 1; // 1 = HUD Only, 2 = HUD + PIP, 3 = Camera Full Screen
  double distance = 450;
  int severity = 5;
  String hazardType = 'POTHOLE AHEAD';
  String icon = '⚠️';
  double nextHazardDistance = 345;
  double speed = 65;
  bool moving = true;
  double? latitude;
  double? longitude;
  bool recording = true;
  bool autoRecord = true;
  String orientation = 'portrait';
}
