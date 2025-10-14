import 'dart:convert';

/// Represents a road hazard with location, severity, and metadata
class Hazard {
  final double lon;
  final double lat;
  final double zoneRadiusMeters; // Radius of hazard zone in meters
  final DateTime lastDetected;
  final int timesDetected6Months;
  final int severity; // 1-10 scale
  final List<String> labels; // e.g., ["severe washboard", "bumps", "potholes"]
  final List<DriverNote> driverNotes;

  Hazard({
    required this.lon,
    required this.lat,
    required this.zoneRadiusMeters,
    required this.lastDetected,
    required this.timesDetected6Months,
    required this.severity,
    required this.labels,
    required this.driverNotes,
  });

  /// Get hazard color based on severity
  String get severityColor {
    if (severity >= 8) return 'red'; // High risk
    if (severity >= 5) return 'orange'; // Medium risk
    return 'yellow'; // Low risk
  }

  /// Get primary label (first one)
  String get primaryLabel => labels.isNotEmpty ? labels.first : 'Unknown hazard';

  /// Convert from JSON
  factory Hazard.fromJson(Map<String, dynamic> json) {
    return Hazard(
      lon: (json['lon'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      zoneRadiusMeters: (json['zone_m'] as num).toDouble(),
      lastDetected: DateTime.parse(json['last_detected'] as String),
      timesDetected6Months: json['times_detected_6mos'] as int,
      severity: json['severity'] as int,
      labels: (json['labels'] as List).map((e) => e as String).toList(),
      driverNotes: (json['driver_notes'] as List?)
              ?.map((e) => DriverNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lon': lon,
      'lat': lat,
      'zone_m': zoneRadiusMeters,
      'last_detected': lastDetected.toIso8601String(),
      'times_detected_6mos': timesDetected6Months,
      'severity': severity,
      'labels': labels,
      'driver_notes': driverNotes.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculate distance to a point in meters using Haversine formula
  double distanceTo(double targetLat, double targetLon) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(targetLat - lat);
    final dLon = _toRadians(targetLon - lon);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat)) * _cos(_toRadians(targetLat)) *
        _sin(dLon / 2) * _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusKm * c * 1000; // Convert to meters
  }

  /// Check if point is inside hazard zone
  bool containsPoint(double targetLat, double targetLon) {
    return distanceTo(targetLat, targetLon) <= zoneRadiusMeters;
  }

  /// Calculate bearing (direction) from a point TO this hazard in degrees (0-360)
  /// 0° = North, 90° = East, 180° = South, 270° = West
  double bearingFrom(double fromLat, double fromLon) {
    final lat1 = _toRadians(fromLat);
    final lon1 = _toRadians(fromLon);
    final lat2 = _toRadians(lat);
    final lon2 = _toRadians(lon);

    final dLon = lon2 - lon1;

    final y = _sin(dLon) * _cos(lat2);
    final x = _cos(lat1) * _sin(lat2) - _sin(lat1) * _cos(lat2) * _cos(dLon);

    final bearing = _atan2(y, x);

    // Convert from radians to degrees and normalize to 0-360
    return (bearing * 180.0 / 3.141592653589793 + 360) % 360;
  }

  // Math helpers
  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180.0;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
}

/// Driver note attached to a hazard
class DriverNote {
  final DateTime datetime;
  final String notes;
  final String driverName;

  DriverNote({
    required this.datetime,
    required this.notes,
    required this.driverName,
  });

  factory DriverNote.fromJson(Map<String, dynamic> json) {
    return DriverNote(
      datetime: DateTime.parse(json['datetime'] as String),
      notes: json['notes'] as String,
      driverName: json['driver_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datetime': datetime.toIso8601String(),
      'notes': notes,
      'driver_name': driverName,
    };
  }
}

/// Proximity alert level
enum ProximityLevel {
  safe(distance: double.infinity, label: 'Safe'),
  approaching500m(distance: 500, label: '500m'),
  approaching100m(distance: 100, label: '100m'),
  approaching50m(distance: 50, label: '50m'),
  approaching10m(distance: 10, label: '10m'),
  insideZone(distance: 0, label: 'In Hazard Zone');

  const ProximityLevel({required this.distance, required this.label});

  final double distance;
  final String label;

  /// Get proximity level from distance
  static ProximityLevel fromDistance(double distanceMeters, double zoneRadius) {
    if (distanceMeters <= zoneRadius) return insideZone;
    if (distanceMeters <= 10) return approaching10m;
    if (distanceMeters <= 50) return approaching50m;
    if (distanceMeters <= 100) return approaching100m;
    if (distanceMeters <= 500) return approaching500m;
    return safe;
  }
}
