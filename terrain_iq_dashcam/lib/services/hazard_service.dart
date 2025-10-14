import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/hazard.dart';
import '../config.dart';
import 'location_service.dart';
import 'mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Service to manage road hazard data and proximity warnings
class HazardService extends ChangeNotifier {
  final LocationService _locationService;
  final MqttService? _mqttService;

  List<Hazard> _hazards = [];
  Timer? _fetchTimer;
  Timer? _highFrequencyTimer;
  DateTime? _lastFetchTime;
  bool _isFetching = false;
  bool _highFrequencyMode = false;

  // Current proximity state
  Hazard? _closestHazard;
  double? _distanceToClosest;
  ProximityLevel _proximityLevel = ProximityLevel.safe;

  // Configurable proximity threshold (default: 500m, range: 100m-500m)
  double _proximityThresholdMeters = 500.0;

  // Getters
  List<Hazard> get hazards => _hazards;
  Hazard? get closestHazard => _closestHazard;
  double? get distanceToClosest => _distanceToClosest;
  ProximityLevel get proximityLevel => _proximityLevel;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get isFetching => _isFetching;
  bool get hasActiveWarning => _proximityLevel != ProximityLevel.safe;
  double get proximityThresholdMeters => _proximityThresholdMeters;
  bool get highFrequencyMode => _highFrequencyMode;

  HazardService(this._locationService, [this._mqttService]);

  /// Set proximity threshold (100m - 500m range)
  void setProximityThreshold(double meters) {
    if (meters < 100 || meters > 500) {
      debugPrint('❌ HazardService: Invalid threshold $meters. Must be 100-500m');
      return;
    }
    _proximityThresholdMeters = meters;
    debugPrint('⚙️ HazardService: Proximity threshold set to ${meters.toStringAsFixed(0)}m');
    notifyListeners();
  }

  /// Initialize hazard service - fetch hazards and start periodic updates
  Future<void> initialize() async {
    debugPrint('⚠️ HazardService: Initializing...');

    // Fetch hazards immediately if we have location
    if (_locationService.currentPosition != null) {
      await fetchHazards();
    }

    // Start periodic fetch timer (every 15 minutes)
    _startPeriodicFetch();

    // Subscribe to MQTT commands if available
    if (_mqttService != null) {
      _subscribeMqttCommands();
    }

    debugPrint('✅ HazardService: Initialized');
  }

  /// Start periodic hazard fetching (every 15 minutes)
  void _startPeriodicFetch() {
    _fetchTimer?.cancel();
    _fetchTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      debugPrint('⏰ HazardService: Periodic fetch triggered');
      await fetchHazards();
    });
  }

  /// Fetch hazards from API with optional radius (default 200km, high-frequency uses 50km)
  /// If merge is true, combines new hazards with existing ones (for high-frequency mode)
  Future<bool> fetchHazards({int radiusKm = 200, bool merge = false}) async {
    if (_isFetching) {
      debugPrint('⚠️ HazardService: Already fetching');
      return false;
    }

    final position = _locationService.currentPosition;
    if (position == null) {
      debugPrint('❌ HazardService: No location available');
      return false;
    }

    _isFetching = true;
    notifyListeners();

    try {
      debugPrint('📡 HazardService: Fetching hazards...');
      debugPrint('   → Location: ${position.latitude}, ${position.longitude}');
      debugPrint('   → Radius: ${radiusKm}km');
      debugPrint('   → Merge mode: $merge');

      final url = Uri.parse('${AppConfig.serverUrl}/get_hazards');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': position.latitude,
          'lon': position.longitude,
          'radius_km': radiusKm,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hazardsList = data['hazards'] as List;

        final newHazards = hazardsList
            .map((json) => Hazard.fromJson(json as Map<String, dynamic>))
            .toList();

        if (merge) {
          // Merge new hazards with existing ones, avoiding duplicates
          _hazards = _mergeHazards(_hazards, newHazards);
          debugPrint('✅ HazardService: Merged ${newHazards.length} new hazards (total: ${_hazards.length})');
        } else {
          // Replace existing hazards
          _hazards = newHazards;
          debugPrint('✅ HazardService: Fetched ${_hazards.length} hazards');
        }

        _lastFetchTime = DateTime.now();

        // Log hazard severity distribution
        final highRisk = _hazards.where((h) => h.severity >= 8).length;
        final mediumRisk = _hazards.where((h) => h.severity >= 5 && h.severity < 8).length;
        final lowRisk = _hazards.where((h) => h.severity < 5).length;
        debugPrint('   → High risk: $highRisk, Medium: $mediumRisk, Low: $lowRisk');

        notifyListeners();
        return true;
      } else {
        debugPrint('❌ HazardService: Fetch failed - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ HazardService: Fetch error: $e');
      return false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Update proximity to hazards based on current location
  /// Call this frequently (every 1s or on location update)
  void updateProximity() {
    final position = _locationService.currentPosition;
    if (position == null || _hazards.isEmpty) {
      _clearProximity();
      return;
    }

    // Find closest hazard
    Hazard? closest;
    double? minDistance;

    for (final hazard in _hazards) {
      final distance = hazard.distanceTo(position.latitude, position.longitude);

      // Only consider hazards within proximity threshold (approaching range)
      if (distance <= _proximityThresholdMeters) {
        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          closest = hazard;
        }
      }
    }

    // Update state
    final previousProximity = _proximityLevel;
    final previousHazard = _closestHazard;

    _closestHazard = closest;
    _distanceToClosest = minDistance;
    _proximityLevel = closest != null
        ? ProximityLevel.fromDistance(minDistance!, closest.zoneRadiusMeters)
        : ProximityLevel.safe;

    // Notify if proximity changed
    if (_proximityLevel != previousProximity || _closestHazard != previousHazard) {
      debugPrint('⚠️ HazardService: Proximity changed to ${_proximityLevel.label}');
      if (closest != null) {
        debugPrint('   → Hazard: ${closest.primaryLabel}');
        debugPrint('   → Severity: ${closest.severity}/10');
        debugPrint('   → Distance: ${minDistance!.toStringAsFixed(0)}m');
      }
      notifyListeners();
    }
  }

  /// Clear proximity state
  void _clearProximity() {
    if (_proximityLevel != ProximityLevel.safe) {
      _closestHazard = null;
      _distanceToClosest = null;
      _proximityLevel = ProximityLevel.safe;
      notifyListeners();
    }
  }

  /// Get hazards within a certain distance (in meters)
  List<Hazard> getHazardsWithinDistance(double distanceMeters) {
    final position = _locationService.currentPosition;
    if (position == null) return [];

    return _hazards.where((hazard) {
      final distance = hazard.distanceTo(position.latitude, position.longitude);
      return distance <= distanceMeters;
    }).toList();
  }

  /// Get hazards by severity
  List<Hazard> getHazardsBySeverity(int minSeverity) {
    return _hazards.where((h) => h.severity >= minSeverity).toList();
  }

  /// Calculate countdown distance (rounded to nearest 5m)
  int? getCountdownDistance() {
    if (_distanceToClosest == null || _proximityLevel == ProximityLevel.insideZone) {
      return null;
    }

    // Round to nearest 5m
    final rounded = (_distanceToClosest! / 5).ceil() * 5;
    return rounded;
  }

  /// Get next hazard in forward direction of travel (within 180° cone ahead)
  /// Returns map with 'hazard', 'distance', 'bearing', 'relativeBearing'
  /// Returns null if no hazard ahead or no heading available
  Map<String, dynamic>? getNextHazardAhead() {
    final position = _locationService.currentPosition;
    final heading = _locationService.heading;

    // Debug logging
    debugPrint('🔍 HazardService.getNextHazardAhead() called');
    debugPrint('   → Position: ${position != null ? "${position.latitude}, ${position.longitude}" : "NULL"}');
    debugPrint('   → Heading: ${heading ?? "NULL"}°');
    debugPrint('   → Total hazards loaded: ${_hazards.length}');

    // Need both position and heading to determine forward direction
    if (position == null || heading == null || _hazards.isEmpty) {
      debugPrint('   ❌ Returning null - missing position, heading, or no hazards');
      return null;
    }

    Hazard? closestAhead;
    double? minDistance;
    double? bearingToClosest;

    int hazardsChecked = 0;
    int hazardsWithin500m = 0;
    int hazardsOutsideCone = 0;
    int hazardsInForwardCone = 0;

    for (final hazard in _hazards) {
      final distance = hazard.distanceTo(position.latitude, position.longitude);
      hazardsChecked++;

      // Skip the hazard we're currently warning about (if any)
      if (_closestHazard != null && hazard == _closestHazard) {
        continue;
      }

      // Calculate bearing to hazard
      final bearing = hazard.bearingFrom(position.latitude, position.longitude);

      // Calculate relative bearing (angle difference from heading)
      double relativeBearing = (bearing - heading + 360) % 360;
      if (relativeBearing > 180) relativeBearing -= 360;

      // Check if hazard is in forward cone (±90° from heading)
      if (relativeBearing.abs() <= 90) {
        hazardsInForwardCone++;
        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          closestAhead = hazard;
          bearingToClosest = bearing;
        }
      } else {
        hazardsOutsideCone++;
      }

      // Track for debug
      if (distance <= _proximityThresholdMeters) {
        hazardsWithin500m++;
      }
    }

    debugPrint('   → Hazards within ${_proximityThresholdMeters.toStringAsFixed(0)}m: $hazardsWithin500m');
    debugPrint('   → Hazards outside forward cone: $hazardsOutsideCone');
    debugPrint('   → Hazards in forward cone: $hazardsInForwardCone');

    if (closestAhead != null && minDistance != null && bearingToClosest != null) {
      double relativeBearing = (bearingToClosest - heading + 360) % 360;
      if (relativeBearing > 180) relativeBearing -= 360;

      debugPrint('   ✅ Found next hazard ahead:');
      debugPrint('      → Label: ${closestAhead.primaryLabel}');
      debugPrint('      → Distance: ${minDistance.toStringAsFixed(0)}m');
      debugPrint('      → Relative bearing: ${relativeBearing.toStringAsFixed(0)}°');

      return {
        'hazard': closestAhead,
        'distance': minDistance,
        'bearing': bearingToClosest,
        'relativeBearing': relativeBearing,
      };
    }

    debugPrint('   ❌ No hazards found in forward cone');
    return null;
  }

  /// Subscribe to MQTT commands for controlling hazard monitoring
  void _subscribeMqttCommands() {
    if (_mqttService?.client == null) return;

    final deviceId = _mqttService!.deviceId;
    final commandTopic = 'terrainiq/device/$deviceId/command';

    debugPrint('📡 HazardService: Subscribing to $commandTopic');

    _mqttService!.client!.subscribe(commandTopic, MqttQos.atLeastOnce);

    _mqttService!.client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final message in messages) {
        final payload = MqttPublishPayload.bytesToStringAsString(
          (message.payload as MqttPublishMessage).payload.message,
        );

        try {
          final command = jsonDecode(payload);
          _handleMqttCommand(command);
        } catch (e) {
          debugPrint('❌ HazardService: Error parsing MQTT command: $e');
        }
      }
    });
  }

  /// Handle MQTT commands
  void _handleMqttCommand(Map<String, dynamic> command) {
    final action = command['action'] as String?;
    debugPrint('📨 HazardService: Received MQTT command: $action');

    if (action == 'enable_high_frequency') {
      final enabled = command['enabled'] as bool? ?? true;
      setHighFrequencyMode(enabled);
    }
  }

  /// Enable or disable high-frequency hazard monitoring (every 5s with 50km radius)
  void setHighFrequencyMode(bool enabled) {
    if (_highFrequencyMode == enabled) return;

    _highFrequencyMode = enabled;

    if (enabled) {
      debugPrint('⚡ HazardService: Enabling high-frequency mode (5s, 50km radius)');
      _startHighFrequencyFetch();
    } else {
      debugPrint('⚡ HazardService: Disabling high-frequency mode');
      _highFrequencyTimer?.cancel();
      _highFrequencyTimer = null;
    }

    notifyListeners();
  }

  /// Start high-frequency hazard fetching (every 5 seconds with 50km radius)
  void _startHighFrequencyFetch() {
    _highFrequencyTimer?.cancel();

    // Fetch immediately
    fetchHazards(radiusKm: 50, merge: true);

    // Then fetch every 5 seconds
    _highFrequencyTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      debugPrint('⏰ HazardService: High-frequency fetch triggered');
      await fetchHazards(radiusKm: 50, merge: true);
    });
  }

  /// Merge two hazard lists, avoiding duplicates based on hazard ID
  List<Hazard> _mergeHazards(List<Hazard> existing, List<Hazard> newHazards) {
    // Create a map of existing hazards by their unique identifier
    // We'll use coordinates + label as a unique key since hazards don't have explicit IDs
    final Map<String, Hazard> hazardMap = {};

    for (final hazard in existing) {
      final key = '${hazard.lat}_${hazard.lon}_${hazard.primaryLabel}';
      hazardMap[key] = hazard;
    }

    // Add or update with new hazards
    for (final hazard in newHazards) {
      final key = '${hazard.lat}_${hazard.lon}_${hazard.primaryLabel}';
      hazardMap[key] = hazard; // This will update if exists, or add if new
    }

    return hazardMap.values.toList();
  }

  @override
  void dispose() {
    debugPrint('⚠️ HazardService: Disposing...');
    _fetchTimer?.cancel();
    _highFrequencyTimer?.cancel();
    super.dispose();
  }
}
