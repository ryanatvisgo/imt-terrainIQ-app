import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service to log sensor data to CSV files alongside video recordings
class DataLoggerService extends ChangeNotifier {
  File? _currentLogFile;
  List<List<dynamic>> _csvData = [];
  Timer? _logTimer;
  bool _isLogging = false;

  // GPS tracking
  List<Map<String, dynamic>> _gpsPoints = [];

  // CSV headers
  static const List<String> _csvHeaders = [
    'timestamp',
    'accel_x',
    'accel_y',
    'accel_z',
    'gyro_x',
    'gyro_y',
    'gyro_z',
    'roughness',
    'roughness_level',
    'orientation',
    'is_moving',
    'latitude',
    'longitude',
    'altitude',
    'speed_mps',
    'accuracy',
  ];

  bool get isLogging => _isLogging;
  String? get currentLogPath => _currentLogFile?.path;

  /// Start logging data to a CSV file
  /// Returns the path to the created CSV file
  Future<String?> startLogging(String videoFileName) async {
    if (_isLogging) {
      debugPrint('⚠️ DataLoggerService: Already logging');
      return _currentLogFile?.path;
    }

    try {
      debugPrint('🔵 DataLoggerService: Starting logging for $videoFileName');

      // Get the app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final videosDir = Directory(path.join(directory.path, 'videos'));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // Create CSV file with same name as video but .csv extension
      final csvFileName = '$videoFileName.csv';
      _currentLogFile = File(path.join(videosDir.path, csvFileName));

      // Initialize CSV data with headers
      _csvData = [_csvHeaders];

      _isLogging = true;
      notifyListeners();

      debugPrint('✅ DataLoggerService: Logging started - ${_currentLogFile!.path}');
      return _currentLogFile!.path;
    } catch (e) {
      debugPrint('❌ DataLoggerService: Error starting logging: $e');
      return null;
    }
  }

  /// Log a data point
  void logDataPoint({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double roughness,
    required String roughnessLevel,
    required String orientation,
    required bool isMoving,
    double? latitude,
    double? longitude,
    double? altitude,
    double? speedMps,
    double? accuracy,
  }) {
    if (!_isLogging) {
      return;
    }

    final timestamp = DateTime.now();
    final row = [
      timestamp.toIso8601String(),
      accelX.toStringAsFixed(4),
      accelY.toStringAsFixed(4),
      accelZ.toStringAsFixed(4),
      gyroX.toStringAsFixed(4),
      gyroY.toStringAsFixed(4),
      gyroZ.toStringAsFixed(4),
      roughness.toStringAsFixed(4),
      roughnessLevel,
      orientation,
      isMoving.toString(),
      latitude?.toStringAsFixed(6) ?? '',
      longitude?.toStringAsFixed(6) ?? '',
      altitude?.toStringAsFixed(2) ?? '',
      speedMps?.toStringAsFixed(2) ?? '',
      accuracy?.toStringAsFixed(2) ?? '',
    ];

    _csvData.add(row);

    // Store GPS points for metadata (every 1 second)
    if (latitude != null && longitude != null && _csvData.length % 10 == 0) {
      _gpsPoints.add({
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude ?? 0.0,
        'speed_mps': speedMps ?? 0.0,
        'accuracy': accuracy ?? 0.0,
      });
    }
  }

  /// Get GPS points collected during recording
  List<Map<String, dynamic>> getGpsPoints() => List.from(_gpsPoints);

  /// Stop logging and save the CSV file
  Future<String?> stopLogging() async {
    if (!_isLogging) {
      debugPrint('⚠️ DataLoggerService: Not currently logging');
      return null;
    }

    try {
      debugPrint('🔵 DataLoggerService: Stopping logging...');

      // Convert CSV data to string
      final csvString = const ListToCsvConverter().convert(_csvData);

      // Write to file
      await _currentLogFile!.writeAsString(csvString);

      final filePath = _currentLogFile!.path;
      final rowCount = _csvData.length - 1; // Subtract header row

      _isLogging = false;
      _csvData = [];
      _gpsPoints = [];
      final logFile = _currentLogFile;
      _currentLogFile = null;

      notifyListeners();

      debugPrint('✅ DataLoggerService: Logging stopped - $rowCount data points saved to $filePath');
      return logFile!.path;
    } catch (e) {
      debugPrint('❌ DataLoggerService: Error stopping logging: $e');
      _isLogging = false;
      _csvData = [];
      _currentLogFile = null;
      notifyListeners();
      return null;
    }
  }

  /// Start periodic logging (e.g., every 100ms)
  void startPeriodicLogging({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double roughness,
    required String roughnessLevel,
    required String orientation,
    required bool isMoving,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    _logTimer?.cancel();
    _logTimer = Timer.periodic(interval, (_) {
      logDataPoint(
        accelX: accelX,
        accelY: accelY,
        accelZ: accelZ,
        gyroX: gyroX,
        gyroY: gyroY,
        gyroZ: gyroZ,
        roughness: roughness,
        roughnessLevel: roughnessLevel,
        orientation: orientation,
        isMoving: isMoving,
      );
    });
  }

  /// Stop periodic logging
  void stopPeriodicLogging() {
    _logTimer?.cancel();
    _logTimer = null;
  }

  /// Get CSV file size in bytes
  Future<int> getLogFileSize() async {
    if (_currentLogFile == null || !await _currentLogFile!.exists()) {
      return 0;
    }
    return await _currentLogFile!.length();
  }

  @override
  void dispose() {
    debugPrint('🔵 DataLoggerService: Disposing...');
    _logTimer?.cancel();
    if (_isLogging) {
      stopLogging();
    }
    super.dispose();
  }
}
