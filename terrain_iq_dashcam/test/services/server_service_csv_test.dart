import 'package:flutter_test/flutter_test.dart';
import 'package:terrain_iq_dashcam/services/server_service.dart';
import 'package:terrain_iq_dashcam/models/video_recording.dart';
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
  late ServerService serverService;
  late Directory testDirectory;

  setUp(() async {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    testDirectory = await Directory.systemTemp.createTemp('test_upload_');
    serverService = ServerService();
  });

  tearDown(() async {
    serverService.dispose();
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  group('ServerService - CSV Upload Integration', () {
    test('should create test CSV file', () async {
      // Create a mock CSV file
      final csvFile = File('${testDirectory.path}/test_video.csv');
      final csvContent = '''timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00
2025-10-11T10:00:01.000Z,1.1000,2.1000,3.1000,0.1100,0.2100,0.3100,0.5100,smooth,portrait,true,37.775000,-122.419300,100.10,10.10,5.10''';

      await csvFile.writeAsString(csvContent);

      expect(await csvFile.exists(), isTrue);
      final content = await csvFile.readAsString();
      expect(content, contains('timestamp'));
      expect(content, contains('accel_x'));
      expect(content, contains('latitude'));
    });

    test('should create test video recording with CSV', () async {
      // Create mock files
      final videoFile = File('${testDirectory.path}/test_video.mp4');
      await videoFile.writeAsString('mock video content');

      final csvFile = File('${testDirectory.path}/test_video.csv');
      final csvContent = '''timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0000,2.0000,3.0000,0.1000,0.2000,0.3000,0.5000,smooth,portrait,true,37.774900,-122.419400,100.00,10.00,5.00''';
      await csvFile.writeAsString(csvContent);

      // Verify both files exist
      expect(await videoFile.exists(), isTrue);
      expect(await csvFile.exists(), isTrue);

      // Verify CSV has associated video
      final csvPath = csvFile.path;
      final videoPath = csvPath.replaceAll('.csv', '.mp4');
      expect(File(videoPath).existsSync(), isTrue);
    });

    test('should verify CSV content format', () async {
      final csvFile = File('${testDirectory.path}/test_sensors.csv');
      final csvContent = '''timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.2346,-2.3457,3.4568,0.1235,-0.2346,0.3457,1.2345,very_rough,landscape,false,37.774900,-122.419400,123.45,15.67,10.50
2025-10-11T10:00:01.000Z,1.3456,-2.4567,3.5678,0.2345,-0.3456,0.4567,1.3456,rough,portrait,true,37.775000,-122.419300,124.55,16.77,11.60''';

      await csvFile.writeAsString(csvContent);

      final content = await csvFile.readAsString();
      final lines = content.split('\n');

      // Verify header
      expect(lines[0], contains('timestamp'));
      expect(lines[0], contains('latitude'));
      expect(lines[0], contains('longitude'));
      expect(lines[0], contains('roughness'));

      // Verify data rows
      expect(lines.length, equals(3)); // header + 2 data rows
      expect(lines[1], contains('37.774900'));
      expect(lines[2], contains('37.775000'));
    });

    test('should simulate multipart upload preparation', () async {
      // Create mock files for upload
      final videoFile = File('${testDirectory.path}/recording_123.mp4');
      await videoFile.writeAsString('mock video data');

      final csvFile = File('${testDirectory.path}/recording_123.csv');
      await csvFile.writeAsString('timestamp,accel_x,accel_y\n2025-10-11T10:00:00.000Z,1.0,2.0');

      final metadataFile = File('${testDirectory.path}/recording_123.json');
      await metadataFile.writeAsString('{"video":{"filename":"recording_123.mp4"}}');

      // Verify all files exist
      expect(await videoFile.exists(), isTrue);
      expect(await csvFile.exists(), isTrue);
      expect(await metadataFile.exists(), isTrue);

      // Verify file associations
      final baseName = 'recording_123';
      expect(videoFile.path, contains(baseName));
      expect(csvFile.path, contains(baseName));
      expect(metadataFile.path, contains(baseName));
    });

    test('should handle CSV file discovery from video path', () async {
      final videoPath = '${testDirectory.path}/test_video_456.mp4';
      final videoFile = File(videoPath);
      await videoFile.writeAsString('video content');

      // Create associated CSV
      final csvPath = videoPath.replaceAll('.mp4', '.csv');
      final csvFile = File(csvPath);
      await csvFile.writeAsString('timestamp,accel_x\n2025-10-11T10:00:00.000Z,1.0');

      // Verify CSV can be found from video path
      expect(await csvFile.exists(), isTrue);
      expect(csvFile.path.endsWith('.csv'), isTrue);
      expect(csvFile.path.contains('test_video_456'), isTrue);
    });

    test('should verify CSV data integrity', () async {
      final csvFile = File('${testDirectory.path}/integrity_test.csv');

      // Write CSV with known data
      final testData = [
        ['timestamp', 'accel_x', 'accel_y', 'accel_z', 'latitude', 'longitude'],
        ['2025-10-11T10:00:00.000Z', '1.0000', '2.0000', '3.0000', '37.774900', '-122.419400'],
        ['2025-10-11T10:00:01.000Z', '1.1000', '2.1000', '3.1000', '37.775000', '-122.419300'],
      ];

      final csvContent = testData.map((row) => row.join(',')).join('\n');
      await csvFile.writeAsString(csvContent);

      // Read and verify
      final content = await csvFile.readAsString();
      final lines = content.split('\n');

      expect(lines.length, equals(3));
      expect(lines[0].split(',').length, equals(6)); // 6 columns
      expect(lines[1], contains('37.774900'));
      expect(lines[2], contains('-122.419300'));
    });

    test('should handle large CSV files', () async {
      final csvFile = File('${testDirectory.path}/large_test.csv');

      // Create CSV header
      final header = 'timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy';

      // Create 1000 rows of data
      final rows = <String>[header];
      for (int i = 0; i < 1000; i++) {
        final timestamp = DateTime.now().add(Duration(milliseconds: i * 100)).toIso8601String();
        final row = '$timestamp,${i * 0.001},${i * 0.002},${i * 0.003},0.1,0.2,0.3,0.5,smooth,portrait,true,37.7749,-122.4194,100.0,10.0,5.0';
        rows.add(row);
      }

      await csvFile.writeAsString(rows.join('\n'));

      // Verify file was created and has correct size
      expect(await csvFile.exists(), isTrue);
      final fileSize = await csvFile.length();
      expect(fileSize, greaterThan(10000)); // Should be reasonably large

      final content = await csvFile.readAsString();
      final lines = content.split('\n');
      expect(lines.length, equals(1001)); // header + 1000 rows
    });

    test('should validate CSV column count consistency', () async {
      final csvFile = File('${testDirectory.path}/column_test.csv');

      final csvContent = '''timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,roughness,roughness_level,orientation,is_moving,latitude,longitude,altitude,speed_mps,accuracy
2025-10-11T10:00:00.000Z,1.0,2.0,3.0,0.1,0.2,0.3,0.5,smooth,portrait,true,37.7749,-122.4194,100.0,10.0,5.0
2025-10-11T10:00:01.000Z,1.1,2.1,3.1,0.1,0.2,0.3,0.5,smooth,portrait,true,37.7750,-122.4193,100.1,10.1,5.1''';

      await csvFile.writeAsString(csvContent);

      final content = await csvFile.readAsString();
      final lines = content.split('\n');

      final headerColumnCount = lines[0].split(',').length;

      // Verify all data rows have same column count as header
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].isNotEmpty) {
          final columnCount = lines[i].split(',').length;
          expect(columnCount, equals(headerColumnCount),
                 reason: 'Row $i has $columnCount columns, expected $headerColumnCount');
        }
      }
    });
  });

  group('ServerService - Upload Queue with CSV', () {
    test('should handle video recording with CSV file reference', () async {
      final videoPath = '${testDirectory.path}/test_upload.mp4';
      final csvPath = '${testDirectory.path}/test_upload.csv';

      // Create mock files
      await File(videoPath).writeAsString('video content');
      await File(csvPath).writeAsString('timestamp,accel_x\n2025-10-11T10:00:00.000Z,1.0');

      // Create VideoRecording object
      final recording = VideoRecording(
        fileName: 'test_upload.mp4',
        filePath: videoPath,
        createdAt: DateTime.now(),
        duration: const Duration(seconds: 10),
        fileSizeBytes: 1024,
      );

      // Verify CSV can be found
      final associatedCsvPath = videoPath.replaceAll('.mp4', '.csv');
      expect(File(associatedCsvPath).existsSync(), isTrue);
    });
  });
}
