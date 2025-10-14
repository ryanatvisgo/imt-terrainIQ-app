import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/video_recording.dart';
import '../config.dart';

/// Service to handle server communication (heartbeats and video uploads)
class ServerService extends ChangeNotifier {
  // Server configuration - uses config.dart (toggle useNgrok to switch)
  static String get _baseUrl => AppConfig.serverUrl;
  static const String _heartbeatEndpoint = '/heartbeat';
  static const String _uploadEndpoint = '/upload';
  static const String _logUploadEndpoint = '/logs';

  // Heartbeat timers
  Timer? _heartbeatTimer;
  bool _isRecording = false;
  static const Duration _recordingHeartbeatInterval = Duration(seconds: 60);
  static const Duration _idleHeartbeatInterval = Duration(seconds: 300);

  // Upload queue - now stores VideoRecording objects
  final List<VideoRecording> _uploadQueue = [];
  bool _isUploading = false;
  bool _wifiOnlyMode = true;
  bool _deleteAfterUpload = false;

  // Connectivity
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.none];

  // Callbacks
  Function(VideoRecording, String)? onUploadSuccess;
  Function(VideoRecording)? onUploadStart;
  Function(VideoRecording, String)? onUploadFailed;

  // Getters
  bool get wifiOnlyMode => _wifiOnlyMode;
  bool get isUploading => _isUploading;
  bool get deleteAfterUpload => _deleteAfterUpload;
  int get uploadQueueSize => _uploadQueue.length;
  bool get hasWifiConnection => _currentConnectivity.contains(ConnectivityResult.wifi);

  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('🔵 ServerService: Initializing...');

    // Check initial connectivity
    _currentConnectivity = await _connectivity.checkConnectivity();
    debugPrint('📡 ServerService: Initial connectivity: $_currentConnectivity');

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _currentConnectivity = results;
      debugPrint('📡 ServerService: Connectivity changed to $_currentConnectivity');
      notifyListeners();

      // Try to process upload queue if WiFi is available
      if (hasWifiConnection && _uploadQueue.isNotEmpty) {
        _processUploadQueue();
      }
    });

    // Start idle heartbeat
    _startHeartbeat(false);

    debugPrint('✅ ServerService: Initialized');
  }

  /// Load existing recordings and queue unuploaded ones for upload
  Future<void> queueUnuploadedRecordings(List<VideoRecording> recordings) async {
    debugPrint('📋 ServerService: Checking ${recordings.length} recordings for uploads...');

    final unuploaded = recordings.where((r) =>
      r.uploadStatus == UploadStatus.notUploaded &&
      r.existsLocally
    ).toList();

    debugPrint('📤 ServerService: Found ${unuploaded.length} unuploaded recordings');

    for (final recording in unuploaded) {
      queueVideoUpload(recording);
    }
  }

  /// Set whether to delete local files after upload
  void setDeleteAfterUpload(bool enabled) {
    _deleteAfterUpload = enabled;
    debugPrint('🗑️ ServerService: Delete after upload ${enabled ? "enabled" : "disabled"}');
    notifyListeners();
  }

  /// Set WiFi-only mode for uploads
  void setWifiOnlyMode(bool enabled) {
    _wifiOnlyMode = enabled;
    debugPrint('📡 ServerService: WiFi-only mode ${enabled ? "enabled" : "disabled"}');
    notifyListeners();

    // Try to process queue if mode changed and we have connectivity
    if (!enabled && _uploadQueue.isNotEmpty) {
      _processUploadQueue();
    }
  }

  /// Start/update heartbeat based on recording status
  void _startHeartbeat(bool isRecording) {
    _heartbeatTimer?.cancel();

    final interval = isRecording ? _recordingHeartbeatInterval : _idleHeartbeatInterval;
    debugPrint('💓 ServerService: Starting heartbeat (${interval.inSeconds}s interval, recording: $isRecording)');

    _heartbeatTimer = Timer.periodic(interval, (_) {
      _sendHeartbeat(isRecording);
    });

    // Send initial heartbeat immediately
    _sendHeartbeat(isRecording);
  }

  /// Send heartbeat to server
  Future<void> _sendHeartbeat(bool isRecording) async {
    try {
      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'status': isRecording ? 'recording' : 'idle',
        'upload_queue_size': _uploadQueue.length,
      };

      debugPrint('💓 ServerService: Sending heartbeat - ${payload['status']}');

      final response = await http
          .post(
            Uri.parse('$_baseUrl$_heartbeatEndpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('✅ ServerService: Heartbeat sent successfully');
      } else {
        debugPrint('⚠️ ServerService: Heartbeat failed - ${response.statusCode}');
      }
    } catch (e) {
      // Heartbeat failures are not critical, just log them
      debugPrint('⚠️ ServerService: Heartbeat error: $e');
    }
  }

  /// Notify that recording status changed
  void setRecordingStatus(bool isRecording) {
    if (_isRecording != isRecording) {
      _isRecording = isRecording;
      _startHeartbeat(isRecording);
      notifyListeners();
    }
  }

  /// Add a video to the upload queue
  void queueVideoUpload(VideoRecording recording) {
    if (!_uploadQueue.any((r) => r.filePath == recording.filePath)) {
      _uploadQueue.add(recording);
      debugPrint('📤 ServerService: Video queued for upload - ${recording.fileName}');
      notifyListeners();

      // Try to process queue immediately if conditions are met
      _processUploadQueue();
    }
  }

  /// Process the upload queue
  Future<void> _processUploadQueue() async {
    if (_isUploading || _uploadQueue.isEmpty) {
      return;
    }

    // Check if we should upload based on connectivity
    if (_wifiOnlyMode && !hasWifiConnection) {
      debugPrint('⏸️ ServerService: Upload paused - waiting for WiFi');
      return;
    }

    _isUploading = true;
    notifyListeners();

    while (_uploadQueue.isNotEmpty) {
      final recording = _uploadQueue.first;

      try {
        onUploadStart?.call(recording);
        final serverUrl = await _uploadVideo(recording);

        if (serverUrl != null) {
          _uploadQueue.removeAt(0);
          onUploadSuccess?.call(recording, serverUrl);
          debugPrint('✅ ServerService: Upload successful, removed from queue');
        } else {
          onUploadFailed?.call(recording, 'Upload failed');
          debugPrint('⚠️ ServerService: Upload failed, keeping in queue');
          break; // Stop processing on failure
        }
      } catch (e) {
        onUploadFailed?.call(recording, e.toString());
        debugPrint('❌ ServerService: Upload error: $e');
        break; // Stop processing on error
      }

      notifyListeners();
    }

    _isUploading = false;
    notifyListeners();
  }

  /// Upload a video file to the server
  /// Returns server URL if successful, null otherwise
  Future<String?> _uploadVideo(VideoRecording recording) async {
    try {
      debugPrint('📤 ServerService: Uploading video - ${recording.fileName}');

      final file = File(recording.filePath);
      if (!await file.exists()) {
        debugPrint('❌ ServerService: Video file not found');
        return null;
      }

      final fileSize = await file.length();
      debugPrint('📤 ServerService: File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_uploadEndpoint'),
      );

      // Add video file
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        recording.filePath,
      ));

      // Add CSV data file if it exists
      final csvPath = recording.filePath.replaceAll('.mp4', '.csv');
      final csvFile = File(csvPath);
      if (await csvFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'csv',
          csvPath,
        ));
        debugPrint('📊 ServerService: Adding CSV data');
      }

      // Add metadata JSON file if it exists
      final metadataPath = recording.filePath.replaceAll('.mp4', '.json');
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath(
          'metadata',
          metadataPath,
        ));
        debugPrint('📋 ServerService: Adding metadata');
      }

      // Add metadata fields
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      request.fields['file_size'] = fileSize.toString();

      // Send request
      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final videoUrl = responseData['video_url'] as String?;

        debugPrint('✅ ServerService: Upload successful - URL: $videoUrl');

        // Delete local file after successful upload if enabled
        if (videoUrl != null && _deleteAfterUpload) {
          await _deleteLocalVideo(recording.filePath);
        }

        return videoUrl;
      } else {
        debugPrint('❌ ServerService: Upload failed - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ ServerService: Upload error: $e');
      return null;
    }
  }

  /// Delete local video file
  Future<void> _deleteLocalVideo(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ ServerService: Local video deleted - $localPath');
      }

      // Also delete associated CSV file if it exists
      final csvPath = localPath.replaceAll('.mp4', '.csv');
      final csvFile = File(csvPath);
      if (await csvFile.exists()) {
        await csvFile.delete();
        debugPrint('🗑️ ServerService: CSV file deleted - $csvPath');
      }

      // Also delete associated metadata JSON file if it exists
      final metadataPath = localPath.replaceAll('.mp4', '.json');
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
        debugPrint('🗑️ ServerService: Metadata file deleted - $metadataPath');
      }
    } catch (e) {
      debugPrint('❌ ServerService: Error deleting local video: $e');
    }
  }

  /// Get server URL for viewing
  String getServerUrl() => _baseUrl;

  /// Manually trigger upload queue processing
  Future<void> processUploads() async {
    await _processUploadQueue();
  }

  /// Upload device log file to server
  /// Returns true if successful, false otherwise
  Future<bool> uploadLogFile(File logFile) async {
    try {
      debugPrint('📝 ServerService: Uploading log file - ${logFile.path}');

      if (!await logFile.exists()) {
        debugPrint('❌ ServerService: Log file not found');
        return false;
      }

      final fileSize = await logFile.length();
      debugPrint('📝 ServerService: Log file size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_logUploadEndpoint'),
      );

      // Add log file
      request.files.add(await http.MultipartFile.fromPath(
        'log',
        logFile.path,
      ));

      // Add metadata
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      request.fields['file_size'] = fileSize.toString();
      request.fields['file_name'] = logFile.path.split('/').last;

      // Send request with shorter timeout for logs
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        debugPrint('✅ ServerService: Log upload successful');
        return true;
      } else {
        debugPrint('❌ ServerService: Log upload failed - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ServerService: Log upload error: $e');
      return false;
    }
  }

  /// Upload all pending log files
  /// Returns number of successfully uploaded logs
  Future<int> uploadPendingLogs(List<File> logFiles) async {
    if (logFiles.isEmpty) {
      debugPrint('📝 ServerService: No pending logs to upload');
      return 0;
    }

    debugPrint('📝 ServerService: Uploading ${logFiles.length} pending log files...');

    int successCount = 0;

    for (final logFile in logFiles) {
      final success = await uploadLogFile(logFile);
      if (success) {
        successCount++;
      } else {
        // Stop on first failure to avoid overwhelming the server
        debugPrint('⚠️ ServerService: Stopping log upload due to failure');
        break;
      }

      // Small delay between uploads to avoid overwhelming server
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('✅ ServerService: Uploaded $successCount/${logFiles.length} log files');
    return successCount;
  }

  @override
  void dispose() {
    debugPrint('🔵 ServerService: Disposing...');
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
