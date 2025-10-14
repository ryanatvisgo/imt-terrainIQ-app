import 'package:flutter/foundation.dart';
import 'dart:async';
import 'mqtt_service.dart';
import 'location_service.dart';
import 'motion_service.dart';
import 'hazard_service.dart';
import 'camera_service.dart';
import '../models/hazard.dart';

/// Service that periodically publishes device state to MQTT
class MqttPublisherService {
  final MqttService _mqttService;
  final LocationService _locationService;
  final MotionService _motionService;
  final HazardService _hazardService;
  final CameraService _cameraService;

  Timer? _locationTimer;
  Timer? _statusTimer;
  Timer? _heartbeatTimer;

  ProximityLevel? _lastProximityLevel;

  MqttPublisherService({
    required MqttService mqttService,
    required LocationService locationService,
    required MotionService motionService,
    required HazardService hazardService,
    required CameraService cameraService,
  })  : _mqttService = mqttService,
        _locationService = locationService,
        _motionService = motionService,
        _hazardService = hazardService,
        _cameraService = cameraService;

  /// Start publishing data to MQTT
  void startPublishing() {
    debugPrint('📡 MqttPublisherService: Starting periodic publishing');

    // Publish location every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _publishLocation();
    });

    // Publish status every 5 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _publishStatus();
      _checkProximityChange();
    });

    // Publish heartbeat every 60 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _publishHeartbeat();
    });

    // Publish immediately on start
    _publishLocation();
    _publishStatus();
  }

  /// Publish location data
  void _publishLocation() {
    _mqttService.publishLocation(
      lat: _locationService.latitude,
      lon: _locationService.longitude,
      altitude: _locationService.altitude,
      speed: _locationService.speed,
      accuracy: _locationService.accuracy,
    );
  }

  /// Publish status data
  void _publishStatus() {
    _mqttService.publishStatus(
      isMoving: _motionService.isMoving,
      isRecording: _cameraService.isRecording,
      orientation: _motionService.orientation,
    );
  }

  /// Check if proximity has changed and publish if so
  void _checkProximityChange() {
    final currentProximity = _hazardService.proximityLevel;

    if (currentProximity != _lastProximityLevel) {
      _lastProximityLevel = currentProximity;

      final hazard = _hazardService.closestHazard;
      final distance = _hazardService.distanceToClosest;

      _mqttService.publishProximity(
        proximityLevel: currentProximity.label,
        distanceToHazard: distance,
        hazardLabel: hazard?.primaryLabel,
        hazardSeverity: hazard?.severity,
      );
    }
  }

  /// Publish heartbeat (health pulse)
  void _publishHeartbeat() {
    // For now, publish basic info
    // In production, you'd get real battery/storage info
    _mqttService.publishHeartbeat(
      batteryLevel: 85, // TODO: Get real battery level
      isCharging: false, // TODO: Get real charging status
      availableStorageMb: 5000, // TODO: Get real available storage
      uploadQueueSize: 0, // TODO: Get real queue size
    );
  }

  /// Publish recording state change
  void publishRecordingStateChange(String state, {String? fileName}) {
    _mqttService.publishRecordingState(
      state: state,
      fileName: fileName,
    );
  }

  /// Stop publishing
  void stopPublishing() {
    debugPrint('📡 MqttPublisherService: Stopping periodic publishing');
    _locationTimer?.cancel();
    _statusTimer?.cancel();
    _heartbeatTimer?.cancel();
  }

  void dispose() {
    stopPublishing();
  }
}
