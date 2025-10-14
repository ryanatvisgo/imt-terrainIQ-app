import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService extends ChangeNotifier {
  bool _cameraPermissionGranted = false;
  bool _microphonePermissionGranted = false;
  bool _locationPermissionGranted = false;
  bool _storagePermissionGranted = false;
  bool _isRequestingPermissions = false;

  bool get cameraPermissionGranted => _cameraPermissionGranted;
  bool get microphonePermissionGranted => _microphonePermissionGranted;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get storagePermissionGranted => _storagePermissionGranted;

  bool get allPermissionsGranted => 
      _cameraPermissionGranted && 
      _microphonePermissionGranted && 
      _locationPermissionGranted && 
      _storagePermissionGranted;

  Future<void> requestAllPermissions() async {
    // Request permissions sequentially to avoid conflicts
    await requestCameraPermission();
    await requestMicrophonePermission();
    await requestLocationPermission();
    await requestStoragePermission();
    
    // After requesting all permissions, check if they're all granted
    if (allPermissionsGranted) {
      notifyListeners(); // This will trigger UI updates
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    _cameraPermissionGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    _microphonePermissionGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    _locationPermissionGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> requestStoragePermission() async {
    if (kIsWeb) {
      // On web, storage permissions are handled differently
      _storagePermissionGranted = true;
    } else {
      final status = await Permission.storage.request();
      _storagePermissionGranted = status.isGranted;
    }
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    _cameraPermissionGranted = await Permission.camera.isGranted;
    _microphonePermissionGranted = await Permission.microphone.isGranted;
    _locationPermissionGranted = await Permission.location.isGranted;
    
    if (kIsWeb) {
      // On web, assume storage is always available
      _storagePermissionGranted = true;
    } else {
      _storagePermissionGranted = await Permission.storage.isGranted;
    }
    
    notifyListeners();
  }

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs camera, microphone, location, and storage permissions to function as a dashcam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              requestAllPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }
}

