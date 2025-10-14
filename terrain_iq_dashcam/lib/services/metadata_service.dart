import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

/// Service to create and manage metadata JSON files for video recordings
class MetadataService {
  /// Generate metadata JSON file for a recording
  ///
  /// Creates a JSON file containing:
  /// - Video information (filename, size, duration)
  /// - Device information (model, OS, app version)
  /// - GPS summary (start/end location, distance, avg speed)
  /// - Recording context (manual/auto, timestamp)
  Future<String?> createMetadataFile({
    required String videoFilePath,
    required int videoSizeBytes,
    required Duration videoDuration,
    required List<Map<String, dynamic>> gpsPoints,
    required bool wasAutoRecorded,
  }) async {
    try {
      debugPrint('📝 MetadataService: Creating metadata for $videoFilePath');

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Calculate GPS summary
      final gpsSummary = _calculateGpsSummary(gpsPoints);

      // Create metadata object
      final metadata = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),

        'video': {
          'filename': path.basename(videoFilePath),
          'size_bytes': videoSizeBytes,
          'duration_seconds': videoDuration.inSeconds,
          'format': 'mp4',
          'codec': 'h264',
        },

        'device': deviceInfo,

        'recording': {
          'type': wasAutoRecorded ? 'auto' : 'manual',
          'timestamp': DateTime.now().toIso8601String(),
        },

        'gps': gpsSummary,

        'data_files': {
          'csv': path.basename(videoFilePath).replaceAll('.mp4', '.csv'),
          'json': path.basename(videoFilePath).replaceAll('.mp4', '.json'),
        },
      };

      // Write JSON file
      final jsonFilePath = videoFilePath.replaceAll('.mp4', '.json');
      final jsonFile = File(jsonFilePath);

      final jsonString = JsonEncoder.withIndent('  ').convert(metadata);
      await jsonFile.writeAsString(jsonString);

      debugPrint('✅ MetadataService: Metadata created - $jsonFilePath');
      return jsonFilePath;
    } catch (e) {
      debugPrint('❌ MetadataService: Error creating metadata: $e');
      return null;
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'platform': 'iOS',
        'model': iosInfo.model,
        'name': iosInfo.name,
        'os_version': iosInfo.systemVersion,
        'is_physical': iosInfo.isPhysicalDevice,
        'identifier': iosInfo.identifierForVendor ?? 'unknown',
      };
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'platform': 'Android',
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'os_version': androidInfo.version.release,
        'sdk': androidInfo.version.sdkInt,
        'is_physical': androidInfo.isPhysicalDevice,
        'identifier': androidInfo.id,
      };
    }

    return {
      'platform': 'Unknown',
      'model': 'Unknown',
    };
  }

  /// Calculate GPS summary from points
  Map<String, dynamic> _calculateGpsSummary(List<Map<String, dynamic>> gpsPoints) {
    if (gpsPoints.isEmpty) {
      return {
        'point_count': 0,
        'has_data': false,
      };
    }

    final firstPoint = gpsPoints.first;
    final lastPoint = gpsPoints.last;

    // Calculate total distance
    double totalDistance = 0.0;
    for (int i = 1; i < gpsPoints.length; i++) {
      totalDistance += _calculateDistance(
        gpsPoints[i - 1]['latitude'],
        gpsPoints[i - 1]['longitude'],
        gpsPoints[i]['latitude'],
        gpsPoints[i]['longitude'],
      );
    }

    // Calculate average speed
    final speeds = gpsPoints
        .map((p) => p['speed_mps'] as double)
        .where((s) => s > 0)
        .toList();
    final avgSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a + b) / speeds.length;
    final maxSpeed = speeds.isEmpty ? 0.0 : speeds.reduce((a, b) => a > b ? a : b);

    return {
      'point_count': gpsPoints.length,
      'has_data': true,

      'start_location': {
        'latitude': firstPoint['latitude'],
        'longitude': firstPoint['longitude'],
        'timestamp': firstPoint['timestamp'],
      },

      'end_location': {
        'latitude': lastPoint['latitude'],
        'longitude': lastPoint['longitude'],
        'timestamp': lastPoint['timestamp'],
      },

      'distance_meters': totalDistance.toStringAsFixed(2),
      'avg_speed_mps': avgSpeed.toStringAsFixed(2),
      'max_speed_mps': maxSpeed.toStringAsFixed(2),
      'avg_speed_kmh': (avgSpeed * 3.6).toStringAsFixed(2),
      'max_speed_kmh': (maxSpeed * 3.6).toStringAsFixed(2),

      'points': gpsPoints.map((p) => {
        'time': p['timestamp'],
        'lat': p['latitude'],
        'lon': p['longitude'],
        'alt': p['altitude'],
        'speed': p['speed_mps'],
        'accuracy': p['accuracy'],
      }).toList(),
    };
  }

  /// Calculate distance between two GPS coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() * _toRadians(lat2).cos() *
        (dLon / 2).sin() * (dLon / 2).sin();

    final c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180.0);
}
