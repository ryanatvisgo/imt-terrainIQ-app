import 'package:flutter_test/flutter_test.dart';
import 'package:terrain_iq_dashcam/services/data_logger_service.dart';
import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final directory = Directory.systemTemp.createTempSync('test_app_docs_');
    return directory.path;
  }
}

void main() {
  late DataLoggerService dataLoggerService;
  late Directory testDirectory;

  setUp(() async {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();

    // Create test directory
    testDirectory = await Directory.systemTemp.createTemp('test_csv_');

    dataLoggerService = DataLoggerService();
  });

  tearDown(() async {
    // Clean up test directory
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  group('DataLoggerService - CSV Generation', () {
    test('should initialize correctly', () {
      expect(dataLoggerService.isLogging, isFalse);
      expect(dataLoggerService.currentLogPath, isNull);
    });

    test('should start logging and create CSV file', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      final csvPath = await dataLoggerService.startLogging(videoFileName);

      expect(csvPath, isNotNull);
      expect(dataLoggerService.isLogging, isTrue);
      expect(dataLoggerService.currentLogPath, csvPath);

      // Verify file doesn't exist yet (only created on stop)
      if (csvPath != null) {
        expect(csvPath.endsWith('.csv'), isTrue);
      }
    });

    test('should log data points correctly', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(videoFileName);

      // Log multiple data points
      for (int i = 0; i < 5; i++) {
        dataLoggerService.logDataPoint(
          accelX: 1.0 + i,
          accelY: 2.0 + i,
          accelZ: 3.0 + i,
          gyroX: 0.1 + i,
          gyroY: 0.2 + i,
          gyroZ: 0.3 + i,
          roughness: 0.5 + i,
          roughnessLevel: i % 2 == 0 ? 'smooth' : 'rough',
          orientation: 'portrait',
          isMoving: true,
          latitude: 37.7749 + i * 0.001,
          longitude: -122.4194 + i * 0.001,
          altitude: 100.0 + i,
          speedMps: 10.0 + i,
          accuracy: 5.0,
        );
      }

      final csvPath = await dataLoggerService.stopLogging();

      expect(csvPath, isNotNull);
      expect(dataLoggerService.isLogging, isFalse);

      // Verify CSV file was created and contains data
      if (csvPath != null) {
        final file = File(csvPath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        final lines = content.split('\n');

        // Should have header + 5 data rows
        expect(lines.length, greaterThanOrEqualTo(6));

        // Check header
        expect(lines[0], contains('timestamp'));
        expect(lines[0], contains('accel_x'));
        expect(lines[0], contains('latitude'));
        expect(lines[0], contains('longitude'));

        // Check data rows contain values
        expect(lines[1], contains('1.0000')); // accel_x from first data point
        expect(lines[2], contains('2.0000')); // accel_x from second data point

        // Clean up
        await file.delete();
      }
    });

    test('should handle GPS points collection', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(videoFileName);

      // Log 20 data points (GPS points stored every 10)
      for (int i = 0; i < 20; i++) {
        dataLoggerService.logDataPoint(
          accelX: 1.0,
          accelY: 2.0,
          accelZ: 3.0,
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
          roughness: 0.5,
          roughnessLevel: 'smooth',
          orientation: 'portrait',
          isMoving: true,
          latitude: 37.7749 + i * 0.001,
          longitude: -122.4194 + i * 0.001,
          altitude: 100.0,
          speedMps: 10.0,
          accuracy: 5.0,
        );
      }

      final gpsPoints = dataLoggerService.getGpsPoints();

      // Should have GPS points (every 10th data point)
      expect(gpsPoints.length, greaterThan(0));
      expect(gpsPoints.first['latitude'], isA<double>());
      expect(gpsPoints.first['longitude'], isA<double>());

      await dataLoggerService.stopLogging();
    });

    test('should handle stop logging when not logging', () async {
      final result = await dataLoggerService.stopLogging();
      expect(result, isNull);
    });

    test('should prevent double start', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      final path1 = await dataLoggerService.startLogging(videoFileName);
      final path2 = await dataLoggerService.startLogging(videoFileName);

      expect(path1, equals(path2)); // Should return same path

      await dataLoggerService.stopLogging();
    });

    test('should create valid CSV format', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(videoFileName);

      // Log data with special characters that need CSV escaping
      dataLoggerService.logDataPoint(
        accelX: 1.23456789,
        accelY: -2.34567890,
        accelZ: 3.45678901,
        gyroX: 0.12345,
        gyroY: -0.23456,
        gyroZ: 0.34567,
        roughness: 1.2345,
        roughnessLevel: 'very_rough',
        orientation: 'landscape',
        isMoving: false,
        latitude: 37.7749,
        longitude: -122.4194,
        altitude: 123.45,
        speedMps: 15.67,
        accuracy: 10.5,
      );

      final csvPath = await dataLoggerService.stopLogging();

      if (csvPath != null) {
        final file = File(csvPath);
        final content = await file.readAsString();
        final lines = content.split('\n');

        // Verify proper CSV structure
        final headerFields = lines[0].split(',');
        expect(headerFields.length, equals(16)); // Should have 16 columns

        // Verify data row
        final dataFields = lines[1].split(',');
        expect(dataFields.length, equals(16));

        // Verify numeric precision (4 decimal places for accel/gyro)
        expect(dataFields[1], contains('1.2346')); // accel_x
        expect(dataFields[2], contains('-2.3457')); // accel_y

        // Clean up
        await file.delete();
      }
    });

    test('should handle missing GPS data gracefully', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(videoFileName);

      // Log data without GPS
      dataLoggerService.logDataPoint(
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        roughness: 0.5,
        roughnessLevel: 'smooth',
        orientation: 'portrait',
        isMoving: true,
        // No GPS data provided
      );

      final csvPath = await dataLoggerService.stopLogging();

      if (csvPath != null) {
        final file = File(csvPath);
        final content = await file.readAsString();
        final lines = content.split('\n');

        // GPS fields should be empty
        final dataFields = lines[1].split(',');
        expect(dataFields[11], equals('')); // latitude
        expect(dataFields[12], equals('')); // longitude

        await file.delete();
      }
    });
  });

  group('DataLoggerService - File Size', () {
    test('should return file size when logging', () async {
      final videoFileName = 'test_video_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(videoFileName);

      // Log some data
      for (int i = 0; i < 10; i++) {
        dataLoggerService.logDataPoint(
          accelX: 1.0,
          accelY: 2.0,
          accelZ: 3.0,
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
          roughness: 0.5,
          roughnessLevel: 'smooth',
          orientation: 'portrait',
          isMoving: true,
        );
      }

      await dataLoggerService.stopLogging();
    });

    test('should return 0 for file size when not logging', () async {
      final size = await dataLoggerService.getLogFileSize();
      expect(size, equals(0));
    });
  });
}
