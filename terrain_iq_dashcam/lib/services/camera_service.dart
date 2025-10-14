import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _currentRecordingPath;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use the rear camera (index 0) for dashcam functionality
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera not initialized');
    }

    try {
      if (kIsWeb) {
        // On web, use a simpler file naming approach
        final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
        _currentRecordingPath = fileName;
      } else {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String recordingsDir = path.join(appDir.path, 'recordings');
        
        // Create recordings directory if it doesn't exist
        await Directory(recordingsDir).create(recursive: true);

        final String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
        _currentRecordingPath = path.join(recordingsDir, fileName);
      }

      await _controller!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;
      
      // Move the file to our recordings directory
      if (_currentRecordingPath != null) {
        await videoFile.saveTo(_currentRecordingPath!);
        final String savedPath = _currentRecordingPath!;
        _currentRecordingPath = null;
        notifyListeners();
        return savedPath;
      }
      
      notifyListeners();
      return videoFile.path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isRecording = false;
    super.dispose();
  }

  // Toggle recording state
  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }
}
