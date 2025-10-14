import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Service for MQTT-based preview mode integration using MQTT.js via JS interop
/// This version uses MQTT.js directly which is proven to work with our Aedes broker
class MqttPreviewServiceJs extends ChangeNotifier {
  js.JsObject? _client;
  bool _isConnected = false;
  bool _previewEnabled = false;

  // Preview state from HTML simulator
  PreviewState _previewState = PreviewState();

  // MQTT Configuration
  static const String _brokerUrl = 'ws://localhost:3301';
  late final String _clientId; // Unique client ID generated per instance

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
      // Generate unique client ID to allow multiple Flutter instances
      final random = Random();
      final randomId = random.nextInt(999999).toString().padLeft(6, '0');
      _clientId = 'flutter_dashcam_preview_$randomId';

      debugPrint('MQTT: Connecting to broker at $_brokerUrl using MQTT.js (clientId: $_clientId)');

      // Get MQTT.js from window object
      final mqtt = js.context['mqtt'];
      if (mqtt == null) {
        debugPrint('MQTT: MQTT.js library not loaded! Add <script src="https://unpkg.com/mqtt/dist/mqtt.min.js"></script> to index.html');
        return;
      }

      // Connect using MQTT.js - same way the simulator does it
      _client = mqtt.callMethod('connect', [
        _brokerUrl,
        js.JsObject.jsify({
          'clientId': _clientId,
          'clean': true,
          'keepalive': 60,
        })
      ]);

      // Set up event listeners - MQTT.js message handler receives (topic, message, packet)
      // Note: All event handlers need to accept optional parameters even if unused
      _client!.callMethod('on', ['connect', js.allowInterop(([dynamic connack]) => _onConnected())]);
      _client!.callMethod('on', ['close', js.allowInterop(([dynamic _]) => _onDisconnected())]);
      _client!.callMethod('on', ['offline', js.allowInterop(() => _onOffline())]);
      _client!.callMethod('on', ['reconnect', js.allowInterop(() => _onReconnect())]);
      _client!.callMethod('on', ['error', js.allowInterop((dynamic error) {
        final timestamp = DateTime.now().toIso8601String();
        debugPrint('❌ MQTT [$timestamp]: Error - $error');
      })]);
      _client!.callMethod('on', ['message', js.allowInterop((String topic, dynamic message, [dynamic packet]) {
        _onMessage(topic, message);
      })]);

      final timestamp = DateTime.now().toIso8601String();
      debugPrint('🔌 MQTT [$timestamp]: Connection initiated to $_brokerUrl');
    } catch (e, stackTrace) {
      debugPrint('MQTT: Connection exception - $e');
      debugPrint('MQTT: Stack trace: $stackTrace');
      _isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('✅ MQTT [$timestamp]: Connected to broker ($_clientId)');
    _isConnected = true;

    // Subscribe to preview topics
    _client!.callMethod('subscribe', [_topicPreviewEnable, js.JsObject.jsify({'qos': 1})]);
    _client!.callMethod('subscribe', [_topicPreviewView, js.JsObject.jsify({'qos': 1})]);
    _client!.callMethod('subscribe', [_topicPreviewHazard, js.JsObject.jsify({'qos': 1})]);
    _client!.callMethod('subscribe', [_topicPreviewVehicle, js.JsObject.jsify({'qos': 1})]);
    _client!.callMethod('subscribe', [_topicPreviewRecording, js.JsObject.jsify({'qos': 1})]);
    _client!.callMethod('subscribe', [_topicPreviewOrientation, js.JsObject.jsify({'qos': 1})]);

    debugPrint('📬 MQTT: Subscribed to 6 preview topics');

    // Publish initial status
    _publishStatus();

    notifyListeners();
  }

  void _onDisconnected() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('❌ MQTT [$timestamp]: Disconnected from broker ($_clientId)');
    _isConnected = false;
    _previewEnabled = false;
    notifyListeners();
  }

  void _onOffline() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📴 MQTT [$timestamp]: Client offline ($_clientId)');
    _isConnected = false;
    notifyListeners();
  }

  void _onReconnect() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔄 MQTT [$timestamp]: Attempting reconnection ($_clientId)');
  }

  void _onMessage(String topic, dynamic messageBytes) {
    // Convert byte array to string
    String payload;
    if (messageBytes is List) {
      // Message comes as byte array, convert to string
      payload = String.fromCharCodes(messageBytes.cast<int>());
    } else {
      payload = messageBytes.toString();
    }

    debugPrint('MQTT: Message received on $topic: $payload');

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleMessage(topic, data);
    } catch (e) {
      debugPrint('MQTT: Failed to parse message from $topic - $e');
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

    _client!.callMethod('publish', [
      _topicFlutterStatus,
      status,
      js.JsObject.jsify({'qos': 1})
    ]);

    debugPrint('MQTT: Published status');
  }

  /// Disconnect from MQTT broker
  Future<void> disconnect() async {
    if (_client != null) {
      _client!.callMethod('end');
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
