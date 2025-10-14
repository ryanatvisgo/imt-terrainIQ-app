import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';

/// Device-level logging service for tracking app events, errors, and exceptions
/// Logs are stored independently and uploaded to server periodically
class DeviceLoggerService extends ChangeNotifier {
  Directory? _logsDirectory;
  Directory? _pendingLogsDirectory;
  Directory? _uploadedLogsDirectory;

  File? _currentLogFile;
  String? _deviceId;
  Map<String, dynamic>? _deviceInfo;

  bool _isInitialized = false;

  static const String _logsFolder = 'device_logs';
  static const String _pendingFolder = 'pending';
  static const String _uploadedFolder = 'uploaded';
  static const int _maxLogFileSize = 1024 * 1024; // 1MB

  bool get isInitialized => _isInitialized;

  /// Initialize the logging service
  Future<void> initialize() async {
    try {
      debugPrint('🔵 DeviceLoggerService: Initializing...');

      // Get device info
      await _loadDeviceInfo();

      // Setup directory structure
      final directory = await getApplicationDocumentsDirectory();
      _logsDirectory = Directory(path.join(directory.path, _logsFolder));
      _pendingLogsDirectory = Directory(path.join(_logsDirectory!.path, _pendingFolder));
      _uploadedLogsDirectory = Directory(path.join(_logsDirectory!.path, _uploadedFolder));

      // Create directories if they don't exist
      if (!await _logsDirectory!.exists()) {
        await _logsDirectory!.create(recursive: true);
      }
      if (!await _pendingLogsDirectory!.exists()) {
        await _pendingLogsDirectory!.create(recursive: true);
      }
      if (!await _uploadedLogsDirectory!.exists()) {
        await _uploadedLogsDirectory!.create(recursive: true);
      }

      // Create or open today's log file
      await _initializeTodaysLogFile();

      _isInitialized = true;

      // Log the initialization
      await logEvent(
        'app_startup',
        'Device logger initialized successfully',
        metadata: {'device_id': _deviceId},
      );

      debugPrint('✅ DeviceLoggerService: Initialized successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ DeviceLoggerService: Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Load device information
  Future<void> _loadDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        _deviceInfo = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'os_version': iosInfo.systemVersion,
          'is_physical': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceId = androidInfo.id;
        _deviceInfo = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'os_version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'is_physical': androidInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      _deviceId = 'unknown';
      _deviceInfo = {'platform': 'Unknown', 'error': e.toString()};
    }
  }

  /// Initialize today's log file
  Future<void> _initializeTodaysLogFile() async {
    final today = DateTime.now();
    final dateStr = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final fileName = 'log_$dateStr.jsonl';

    _currentLogFile = File(path.join(_pendingLogsDirectory!.path, fileName));

    // Check if file size exceeds limit, rotate if needed
    if (await _currentLogFile!.exists()) {
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxLogFileSize) {
        // Rotate log file
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final rotatedFileName = 'log_${dateStr}_$timestamp.jsonl';
        final rotatedFile = File(path.join(_pendingLogsDirectory!.path, rotatedFileName));
        await _currentLogFile!.rename(rotatedFile.path);

        // Create new log file
        _currentLogFile = File(path.join(_pendingLogsDirectory!.path, fileName));
      }
    }
  }

  /// Log an event
  Future<void> logEvent(
    String eventType,
    String message, {
    Map<String, dynamic>? metadata,
    String level = 'info',
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ DeviceLoggerService: Not initialized, skipping log');
      return;
    }

    try {
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': _deviceId,
        'event_type': eventType,
        'level': level,
        'message': message,
        'metadata': metadata ?? {},
        'device_info': _deviceInfo,
      };

      // Write as JSON line
      final jsonLine = '${json.encode(logEntry)}\n';
      await _currentLogFile!.writeAsString(jsonLine, mode: FileMode.append);

      // Check if we need to rotate log file
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxLogFileSize) {
        await _initializeTodaysLogFile();
      }

      debugPrint('📝 Log: [$level] $eventType - $message');
    } catch (e) {
      debugPrint('❌ DeviceLoggerService: Error writing log: $e');
    }
  }

  /// Log an error
  Future<void> logError(
    String eventType,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      eventType,
      'Error: ${error.toString()}',
      metadata: {
        ...?metadata,
        'error': error.toString(),
        'stack_trace': stackTrace?.toString(),
      },
      level: 'error',
    );
  }

  /// Log an exception with context
  Future<void> logException(
    String context,
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent(
      'exception',
      'Exception in $context: ${exception.toString()}',
      metadata: {
        ...?metadata,
        'context': context,
        'exception': exception.toString(),
        'exception_type': exception.runtimeType.toString(),
        'stack_trace': stackTrace?.toString(),
      },
      level: 'error',
    );
  }

  /// Log recording started
  Future<void> logRecordingStarted(String fileName, {bool isAutoRecording = false}) async {
    await logEvent(
      'recording_started',
      'Recording started: $fileName',
      metadata: {
        'file_name': fileName,
        'is_auto_recording': isAutoRecording,
      },
    );
  }

  /// Log recording ended
  Future<void> logRecordingEnded(
    String fileName,
    Duration duration,
    int fileSizeBytes,
  ) async {
    await logEvent(
      'recording_ended',
      'Recording ended: $fileName',
      metadata: {
        'file_name': fileName,
        'duration_seconds': duration.inSeconds,
        'file_size_bytes': fileSizeBytes,
      },
    );
  }

  /// Log file upload started
  Future<void> logUploadStarted(String fileName, int fileSizeBytes) async {
    await logEvent(
      'upload_started',
      'Upload started: $fileName',
      metadata: {
        'file_name': fileName,
        'file_size_bytes': fileSizeBytes,
      },
    );
  }

  /// Log file upload completed
  Future<void> logUploadCompleted(
    String fileName,
    String serverUrl,
    Duration uploadDuration,
  ) async {
    await logEvent(
      'upload_completed',
      'Upload completed: $fileName',
      metadata: {
        'file_name': fileName,
        'server_url': serverUrl,
        'upload_duration_seconds': uploadDuration.inSeconds,
      },
    );
  }

  /// Log file upload failed
  Future<void> logUploadFailed(String fileName, String error) async {
    await logEvent(
      'upload_failed',
      'Upload failed: $fileName',
      metadata: {
        'file_name': fileName,
        'error': error,
      },
      level: 'error',
    );
  }

  /// Get all pending log files
  Future<List<File>> getPendingLogFiles() async {
    if (_pendingLogsDirectory == null || !await _pendingLogsDirectory!.exists()) {
      return [];
    }

    try {
      final files = await _pendingLogsDirectory!
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.jsonl'))
          .cast<File>()
          .toList();

      // Exclude current log file
      return files.where((file) => file.path != _currentLogFile?.path).toList();
    } catch (e) {
      debugPrint('❌ DeviceLoggerService: Error getting pending log files: $e');
      return [];
    }
  }

  /// Mark a log file as uploaded
  Future<void> markLogAsUploaded(File logFile) async {
    try {
      final fileName = path.basename(logFile.path);
      final uploadedFile = File(path.join(_uploadedLogsDirectory!.path, fileName));

      await logFile.rename(uploadedFile.path);
      debugPrint('✅ DeviceLoggerService: Log file marked as uploaded: $fileName');
    } catch (e) {
      debugPrint('❌ DeviceLoggerService: Error marking log as uploaded: $e');
    }
  }

  /// Delete old uploaded logs (older than 30 days)
  Future<void> cleanupOldLogs() async {
    if (_uploadedLogsDirectory == null || !await _uploadedLogsDirectory!.exists()) {
      return;
    }

    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 30));

      final files = await _uploadedLogsDirectory!
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          debugPrint('🗑️ DeviceLoggerService: Deleted old log file: ${path.basename(file.path)}');
        }
      }
    } catch (e) {
      debugPrint('❌ DeviceLoggerService: Error cleaning up old logs: $e');
    }
  }

  /// Get log statistics
  Future<Map<String, dynamic>> getLogStatistics() async {
    try {
      final pendingFiles = await getPendingLogFiles();
      final uploadedFiles = await _uploadedLogsDirectory!
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      int pendingSize = 0;
      for (final file in pendingFiles) {
        pendingSize += await file.length();
      }

      int uploadedSize = 0;
      for (final file in uploadedFiles) {
        uploadedSize += await file.length();
      }

      return {
        'pending_files': pendingFiles.length,
        'pending_size_bytes': pendingSize,
        'uploaded_files': uploadedFiles.length,
        'uploaded_size_bytes': uploadedSize,
        'current_log_file': path.basename(_currentLogFile?.path ?? 'none'),
      };
    } catch (e) {
      debugPrint('❌ DeviceLoggerService: Error getting log statistics: $e');
      return {};
    }
  }

  @override
  void dispose() {
    debugPrint('🔵 DeviceLoggerService: Disposing...');
    super.dispose();
  }
}
