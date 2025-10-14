import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_recording.dart';

class StorageService extends ChangeNotifier {
  List<VideoRecording> _recordings = [];
  String? _recordingsDirectory;
  int _maxStorageGB = 10; // Default 10GB limit
  bool _autoDeleteOldRecordings = true;
  Map<String, Map<String, dynamic>> _uploadStatusMap = {}; // fileName -> {status, url}

  List<VideoRecording> get recordings => _recordings;
  String? get recordingsDirectory => _recordingsDirectory;
  int get maxStorageGB => _maxStorageGB;
  bool get autoDeleteOldRecordings => _autoDeleteOldRecordings;

  Future<void> initialize() async {
    await _setupRecordingsDirectory();
    await _loadSettings();
    await _loadRecordings();
  }

  Future<void> _setupRecordingsDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    _recordingsDirectory = path.join(appDir.path, 'recordings');
    await Directory(_recordingsDirectory!).create(recursive: true);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _maxStorageGB = prefs.getInt('max_storage_gb') ?? 10;
    _autoDeleteOldRecordings = prefs.getBool('auto_delete_old') ?? true;

    // Load upload status map
    final uploadStatusJson = prefs.getString('upload_status_map');
    if (uploadStatusJson != null) {
      try {
        final decoded = jsonDecode(uploadStatusJson) as Map<String, dynamic>;
        _uploadStatusMap = decoded.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map))
        );
        debugPrint('📋 StorageService: Loaded ${_uploadStatusMap.length} upload statuses');
      } catch (e) {
        debugPrint('⚠️ StorageService: Error loading upload status: $e');
      }
    }
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_storage_gb', _maxStorageGB);
    await prefs.setBool('auto_delete_old', _autoDeleteOldRecordings);

    // Save upload status map
    final uploadStatusJson = jsonEncode(_uploadStatusMap);
    await prefs.setString('upload_status_map', uploadStatusJson);
  }

  Future<void> _loadRecordings() async {
    if (_recordingsDirectory == null) return;

    try {
      final Directory dir = Directory(_recordingsDirectory!);
      final List<FileSystemEntity> files = await dir.list().toList();

      _recordings = files
          .where((file) => file is File && path.extension(file.path) == '.mp4')
          .map((file) {
            final recording = VideoRecording.fromFile(file as File);
            // Apply upload status if it exists
            final status = _uploadStatusMap[recording.fileName];
            if (status != null) {
              return recording.copyWith(
                uploadStatus: UploadStatus.values.firstWhere(
                  (e) => e.toString() == status['status'],
                  orElse: () => UploadStatus.notUploaded,
                ),
                serverUrl: status['url'] as String?,
              );
            }
            return recording;
          })
          .toList();

      // Sort by creation date (newest first)
      _recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('📋 StorageService: Loaded ${_recordings.length} recordings');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }
  }

  Future<void> addRecording(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        final VideoRecording recording = VideoRecording.fromFile(file);
        _recordings.insert(0, recording); // Add to beginning
        notifyListeners();
        
        // Check storage limits
        if (_autoDeleteOldRecordings) {
          await _enforceStorageLimits();
        }
      }
    } catch (e) {
      debugPrint('Error adding recording: $e');
    }
  }

  Future<void> deleteRecording(VideoRecording recording) async {
    try {
      final File file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
        _recordings.remove(recording);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  Future<void> _enforceStorageLimits() async {
    final int maxBytes = _maxStorageGB * 1024 * 1024 * 1024;
    int currentSize = await _getTotalStorageUsed();

    while (currentSize > maxBytes && _recordings.isNotEmpty) {
      final VideoRecording oldest = _recordings.last;
      await deleteRecording(oldest);
      currentSize = await _getTotalStorageUsed();
    }
  }

  Future<int> _getTotalStorageUsed() async {
    int totalSize = 0;
    for (final recording in _recordings) {
      try {
        final File file = File(recording.filePath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      } catch (e) {
        debugPrint('Error getting file size: $e');
      }
    }
    return totalSize;
  }

  Future<int> getTotalStorageUsed() async {
    return await _getTotalStorageUsed();
  }

  void updateMaxStorage(int gb) {
    _maxStorageGB = gb;
    saveSettings();
    notifyListeners();
  }

  void updateAutoDelete(bool autoDelete) {
    _autoDeleteOldRecordings = autoDelete;
    saveSettings();
    notifyListeners();
  }

  Future<void> clearAllRecordings() async {
    try {
      for (final recording in List.from(_recordings)) {
        await deleteRecording(recording);
      }
    } catch (e) {
      debugPrint('Error clearing all recordings: $e');
    }
  }

  /// Mark a recording as uploading
  void markAsUploading(VideoRecording recording) {
    final index = _recordings.indexWhere((r) => r.filePath == recording.filePath);
    if (index != -1) {
      _recordings[index] = recording.copyWith(uploadStatus: UploadStatus.uploading);
      _updateUploadStatus(recording.fileName, UploadStatus.uploading, null);
      notifyListeners();
    }
  }

  /// Mark a recording as uploaded with server URL
  Future<void> markAsUploaded(VideoRecording recording, String serverUrl) async {
    final index = _recordings.indexWhere((r) => r.filePath == recording.filePath);
    if (index != -1) {
      _recordings[index] = recording.copyWith(
        uploadStatus: UploadStatus.uploaded,
        serverUrl: serverUrl,
      );
      _updateUploadStatus(recording.fileName, UploadStatus.uploaded, serverUrl);
      await saveSettings();
      notifyListeners();
      debugPrint('✅ StorageService: Marked ${recording.fileName} as uploaded');
    }
  }

  /// Mark a recording as failed
  void markAsFailed(VideoRecording recording) {
    final index = _recordings.indexWhere((r) => r.filePath == recording.filePath);
    if (index != -1) {
      _recordings[index] = recording.copyWith(uploadStatus: UploadStatus.failed);
      _updateUploadStatus(recording.fileName, UploadStatus.failed, null);
      notifyListeners();
    }
  }

  /// Delete local file but keep record if uploaded
  Future<void> deleteLocalFile(VideoRecording recording) async {
    try {
      if (!recording.isUploaded) {
        debugPrint('⚠️ StorageService: Cannot delete local file - not uploaded');
        return;
      }

      final File file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ StorageService: Local file deleted - ${recording.fileName}');

        // Update recording to mark as not existing locally
        final index = _recordings.indexWhere((r) => r.filePath == recording.filePath);
        if (index != -1) {
          _recordings[index] = recording.copyWith(existsLocally: false);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error deleting local file: $e');
    }
  }

  /// Internal method to update upload status map
  void _updateUploadStatus(String fileName, UploadStatus status, String? url) {
    _uploadStatusMap[fileName] = {
      'status': status.toString(),
      'url': url,
    };
  }

  /// Get a recording by file path
  VideoRecording? getRecordingByPath(String filePath) {
    try {
      return _recordings.firstWhere((r) => r.filePath == filePath);
    } catch (e) {
      return null;
    }
  }
}

