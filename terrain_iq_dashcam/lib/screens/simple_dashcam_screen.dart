import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../services/motion_service.dart';
import '../services/data_logger_service.dart';
import '../services/device_logger_service.dart';
import '../services/server_service.dart';
import '../services/location_service.dart';
import '../services/hazard_service.dart';
import '../services/mqtt_service.dart';
import '../services/mqtt_publisher_service.dart';
import '../models/video_recording.dart';
import 'settings_screen.dart';
import 'driving_mode_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleDashcamScreen extends StatefulWidget {
  const SimpleDashcamScreen({super.key});

  @override
  State<SimpleDashcamScreen> createState() => _SimpleDashcamScreenState();
}

class _SimpleDashcamScreenState extends State<SimpleDashcamScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isInitializing = true;
  bool _showFullscreenCamera = false;
  bool _autoRecordEnabled = false;
  Timer? _motionCheckTimer;
  Timer? _dataLogTimer;
  Timer? _countdownUpdateTimer; // Timer to update countdown display
  Timer? _proximityCheckTimer; // Timer to check hazard proximity
  late TabController _recordingsTabController;
  bool _isRecordingInProgress = false; // Prevent double-clicks
  bool _wasMovingLastCheck = false; // Track motion state to detect changes
  MqttPublisherService? _mqttPublisher;

  // Upload status tracking
  String _uploadStatus = 'idle'; // idle, connecting, uploading, error
  int _retryCountdown = 0;
  Timer? _retryCountdownTimer;
  Timer? _uploadProgressTimer;
  double _uploadProgress = 0.0;
  int _uploadingFileSize = 0;
  String _uploadingFileName = '';

  @override
  void initState() {
    super.initState();
    _recordingsTabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final motionService = Provider.of<MotionService>(context, listen: false);
    final serverService = Provider.of<ServerService>(context, listen: false);
    final deviceLogger = Provider.of<DeviceLoggerService>(context, listen: false);

    // Log screen initialization
    await deviceLogger.logEvent('screen_initialized', 'SimpleDashcamScreen initialized');

    // Try to initialize camera directly - this will trigger iOS permission dialog
    try {
      await cameraService.initializeCamera();
      debugPrint('✅ Camera initialized successfully');
      await deviceLogger.logEvent('camera_initialized', 'Camera initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Camera initialization failed: $e');
      await deviceLogger.logError('camera_init_failed', e, stackTrace: stackTrace);
    }

    try {
      await storageService.initialize();
      await motionService.initialize();
      // Server service already initialized in splash screen
    } catch (e, stackTrace) {
      await deviceLogger.logError('service_init_failed', e, stackTrace: stackTrace);
    }

    // Setup upload callbacks with logging
    serverService.onUploadStart = (recording) {
      storageService.markAsUploading(recording);
      deviceLogger.logUploadStarted(recording.fileName, recording.fileSizeBytes);
      if (mounted) {
        setState(() {
          _uploadStatus = 'uploading';
          _uploadingFileName = recording.fileName;
          _uploadingFileSize = recording.fileSizeBytes;
          _uploadProgress = 0.0;
        });
        _simulateUploadProgress();
      }
    };

    serverService.onUploadSuccess = (recording, serverUrl) async {
      final uploadDuration = DateTime.now().difference(recording.createdAt);
      await deviceLogger.logUploadCompleted(recording.fileName, serverUrl, uploadDuration);
      await storageService.markAsUploaded(recording, serverUrl);
      // Optionally delete local file if configured
      if (serverService.deleteAfterUpload) {
        await storageService.deleteLocalFile(recording);
      }
      if (mounted) {
        setState(() {
          _uploadStatus = 'idle';
          _uploadProgress = 0.0;
        });
      }
    };

    serverService.onUploadFailed = (recording, error) {
      deviceLogger.logUploadFailed(recording.fileName, error);
      storageService.markAsFailed(recording);
      if (mounted) {
        setState(() {
          _uploadStatus = 'error';
          _startRetryCountdown();
        });
      }
    };

    // Queue unuploaded recordings for upload
    await serverService.queueUnuploadedRecordings(storageService.recordings);

    // Start motion check timer for auto-record
    _startMotionCheckTimer();

    // Start proximity check timer for hazard detection
    final hazardService = Provider.of<HazardService>(context, listen: false);
    _startProximityCheckTimer(hazardService);

    // MQTT DISABLED: Uncomment below to enable real-time telemetry
    // final mqttService = Provider.of<MqttService>(context, listen: false);
    // final locationService = Provider.of<LocationService>(context, listen: false);
    // _mqttPublisher = MqttPublisherService(
    //   mqttService: mqttService,
    //   locationService: locationService,
    //   motionService: motionService,
    //   hazardService: hazardService,
    //   cameraService: cameraService,
    // );
    // _mqttPublisher!.startPublishing();

    setState(() {
      _isInitializing = false;
    });
  }

  void _startMotionCheckTimer() {
    _motionCheckTimer?.cancel();
    _motionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAutoRecordConditions();

      final cameraService = Provider.of<CameraService>(context, listen: false);
      final motionService = Provider.of<MotionService>(context, listen: false);

      // DISABLED: Auto-navigate to driving mode (was causing screen to keep popping up)
      // User can still manually swipe right to enter Driving Mode
      // Track motion state changes for debugging
      if (motionService.isMoving && !_wasMovingLastCheck) {
        _wasMovingLastCheck = true;
        debugPrint('🚗 Motion started (auto-nav disabled, swipe right for Driving Mode)');
      } else if (!motionService.isMoving && _wasMovingLastCheck) {
        _wasMovingLastCheck = false;
        debugPrint('🛑 Motion stopped');
      }

      // Log idle duration if recording and approaching stop threshold
      if (cameraService.isRecording && motionService.lastMovementTime != null) {
        final idleDuration = DateTime.now().difference(motionService.lastMovementTime!);
        if (idleDuration.inSeconds >= 25 && idleDuration.inSeconds <= 35) {
          debugPrint('⏱️ Idle counter: ${idleDuration.inSeconds}s (moving: ${motionService.isMoving})');
        }
      }
    });
  }

  void _startProximityCheckTimer(HazardService hazardService) {
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      hazardService.updateProximity();
    });
  }

  Future<void> _checkAutoRecordConditions() async {
    if (!_autoRecordEnabled) return;

    final cameraService = Provider.of<CameraService>(context, listen: false);
    final motionService = Provider.of<MotionService>(context, listen: false);

    // Check if we should start recording
    if (!cameraService.isRecording && motionService.shouldStartRecording) {
      debugPrint('🚗 Auto-record: Starting recording (motion detected)');
      debugPrint('   → Orientation: ${motionService.orientation}, Valid: ${motionService.isValidRecordingPosition}');
      debugPrint('   → Moving: ${motionService.isMoving}, First movement: ${motionService.firstMovementTime}');
      await _startRecording(cameraService);
    }
    // Check if we should stop recording
    else if (cameraService.isRecording && motionService.shouldStopRecording) {
      debugPrint('🛑 Auto-record: Stopping recording (idle or invalid orientation)');
      debugPrint('   → Orientation: ${motionService.orientation}, Valid: ${motionService.isValidRecordingPosition}');
      debugPrint('   → Moving: ${motionService.isMoving}, Last movement: ${motionService.lastMovementTime}');
      if (motionService.lastMovementTime != null) {
        final idleDuration = DateTime.now().difference(motionService.lastMovementTime!);
        debugPrint('   → Idle duration: ${idleDuration.inSeconds}s');
      }
      await _stopRecording(cameraService);

      // Exit fullscreen if we're in it
      if (mounted && _showFullscreenCamera) {
        setState(() {
          _showFullscreenCamera = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _motionCheckTimer?.cancel();
    _dataLogTimer?.cancel();
    _countdownUpdateTimer?.cancel();
    _proximityCheckTimer?.cancel();
    _retryCountdownTimer?.cancel();
    _uploadProgressTimer?.cancel();
    _mqttPublisher?.dispose();
    _recordingsTabController.dispose();
    super.dispose();
  }

  void _startRetryCountdown() {
    _retryCountdown = 60;
    _retryCountdownTimer?.cancel();
    _retryCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _retryCountdown--;
          if (_retryCountdown <= 0) {
            timer.cancel();
            _uploadStatus = 'connecting';
            // Server service will automatically retry
          }
        });
      }
    });
  }

  void _simulateUploadProgress() {
    _uploadProgressTimer?.cancel();
    _uploadProgress = 0.0;

    // Simulate progress based on file size (larger files take longer)
    final totalTimeSeconds = (_uploadingFileSize / 1024 / 1024 * 2).clamp(5, 60); // 2 seconds per MB, 5-60 seconds range
    final incrementPerSecond = 1.0 / totalTimeSeconds;

    _uploadProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _uploadProgress += incrementPerSecond;
          if (_uploadProgress >= 1.0) {
            _uploadProgress = 1.0;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _showFullscreenCamera ? null : AppBar(
        title: const Text('TerrainIQ Dashcam'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _showFullscreenCamera
          ? _buildFullscreenCamera()
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildCameraView(),
                _buildRecordingsView(),
              ],
            ),
      bottomNavigationBar: _showFullscreenCamera ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Recordings',
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Consumer3<CameraService, PermissionService, MotionService>(
      builder: (context, cameraService, permissionService, motionService, child) {
        if (!cameraService.isInitialized) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Camera not available'),
                const SizedBox(height: 8),
                Text(
                  'Camera: ${permissionService.cameraPermissionGranted ? "Granted" : "Denied"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Microphone: ${permissionService.microphonePermissionGranted ? "Granted" : "Denied"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('🔵 REQUEST PERMISSIONS BUTTON PRESSED');
                    await permissionService.requestAllPermissions();
                    debugPrint('🟢 Permissions requested - Camera: ${permissionService.cameraPermissionGranted}');

                    if (permissionService.cameraPermissionGranted) {
                      debugPrint('🟢 Initializing camera...');
                      final cameraService = Provider.of<CameraService>(context, listen: false);
                      await cameraService.initializeCamera();
                      debugPrint('🟢 Camera initialized: ${cameraService.isInitialized}');
                      setState(() {}); // Trigger rebuild
                    } else {
                      debugPrint('🔴 Camera permission not granted');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camera permission denied. Please allow in Settings.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Request Permissions'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            // Swipe right to enter Driving Mode (hazard warning HUD)
            if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DrivingModeScreen(),
                ),
              );
            }
          },
          child: Stack(
            children: [
              // Background
              Container(color: Colors.black),

              // Main content area
              if (!cameraService.isRecording)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ready to Record',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Swipe hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe,
                            color: Colors.white.withOpacity(0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Swipe right for Hazard Mode',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Auto-record toggle and motion status
              if (!cameraService.isRecording)
                _buildAutoRecordToggle(motionService),

              // PIP camera preview during recording
              if (cameraService.isRecording)
                _buildPIPCameraPreview(cameraService),

              // Record button at bottom
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildRecordButton(cameraService),
                ),
              ),

              // Recording indicator
              if (cameraService.isRecording)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                        SizedBox(width: 8),
                        Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoRecordToggle(MotionService motionService) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Positioned(
      top: isLandscape ? 20 : 80,
      left: 20,
      right: isLandscape ? null : 20,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12 : 16,
          vertical: isLandscape ? 8 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(isLandscape ? 20 : 12),
          border: Border.all(
            color: _autoRecordEnabled ? Colors.green : Colors.grey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: isLandscape
            ? _buildCompactToggle(motionService)
            : _buildExpandedToggle(motionService),
      ),
    );
  }

  Widget _buildCompactToggle(MotionService motionService) {
    final roughnessColor = _getRoughnessColor(motionService.getRoughnessLevel());
    final roughnessLevel = motionService.getRoughnessLevel();
    final warmingProgress = _getWarmingUpProgress(motionService);
    final showWarming = warmingProgress > 0.0 && warmingProgress < 1.0 && _autoRecordEnabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Auto-record switch
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _autoRecordEnabled,
            onChanged: (value) {
              setState(() {
                _autoRecordEnabled = value;
              });
              debugPrint('🔄 Auto-record ${value ? "enabled" : "disabled"}');
            },
            activeColor: Colors.green,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),

        // Warming up indicator (compact)
        if (showWarming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value: warmingProgress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${(3 * (1.0 - warmingProgress)).ceil()}s',
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        if (showWarming) const SizedBox(width: 8),

        // Status indicators (only show when not warming up)
        if (!showWarming) ...[
          _buildStatusDot(
            motionService.isMoving ? Icons.directions_car : Icons.pause_circle_outline,
            motionService.isMoving ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          _buildStatusDot(
            Icons.phone_android,
            motionService.isValidRecordingPosition ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
        ],

        // Enhanced roughness indicator for landscape
        _buildEnhancedRoughnessIndicator(roughnessLevel, roughnessColor),
      ],
    );
  }

  /// Build enhanced roughness indicator for landscape mode
  Widget _buildEnhancedRoughnessIndicator(String level, Color color) {
    final isVeryRough = level == 'very_rough';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: isVeryRough ? 2 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.waves,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            level.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on roughness level
  Color _getRoughnessColor(String level) {
    switch (level) {
      case 'smooth':
        return Colors.green;
      case 'moderate':
        return Colors.yellow;
      case 'rough':
        return Colors.orange;
      case 'very_rough':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusDot(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 14,
      ),
    );
  }

  Widget _buildExpandedToggle(MotionService motionService) {
    final warmingProgress = _getWarmingUpProgress(motionService);
    final showWarming = warmingProgress > 0.0 && warmingProgress < 1.0 && _autoRecordEnabled;
    final secondsRemaining = (3 * (1.0 - warmingProgress)).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Auto-Record on Motion',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Switch(
              value: _autoRecordEnabled,
              onChanged: (value) {
                setState(() {
                  _autoRecordEnabled = value;
                });
                debugPrint('🔄 Auto-record ${value ? "enabled" : "disabled"}');
              },
              activeColor: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Warming up indicator (when motion detected but < 3s)
        if (showWarming)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.motion_photos_on, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Detecting motion... ${secondsRemaining}s',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: warmingProgress,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                  minHeight: 4,
                ),
              ],
            ),
          ),

        // Motion status
        Row(
          children: [
            Icon(
              motionService.isMoving ? Icons.directions_car : Icons.pause_circle_outline,
              color: motionService.isMoving ? Colors.green : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              motionService.isMoving ? 'Moving' : 'Stopped',
              style: TextStyle(
                color: motionService.isMoving ? Colors.green : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Orientation status
        Row(
          children: [
            Icon(
              Icons.phone_android,
              color: motionService.isValidRecordingPosition ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Orientation: ${motionService.orientation}',
              style: TextStyle(
                color: motionService.isValidRecordingPosition ? Colors.green : Colors.orange,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Roughness indicator with color coding
        Row(
          children: [
            Icon(
              Icons.waves,
              color: _getRoughnessColor(motionService.getRoughnessLevel()),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Road: ${motionService.getRoughnessLevel().replaceAll('_', ' ')}',
              style: TextStyle(
                color: _getRoughnessColor(motionService.getRoughnessLevel()),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Calculate idle countdown progress (0.0 = just stopped, 1.0 = about to auto-stop)
  double _getIdleCountdownProgress(MotionService motionService) {
    if (motionService.lastMovementTime == null || motionService.isMoving) {
      return 0.0;
    }

    final idleDuration = DateTime.now().difference(motionService.lastMovementTime!);
    const maxIdleSeconds = 30; // Match _idleTimeout in MotionService
    final progress = (idleDuration.inSeconds / maxIdleSeconds).clamp(0.0, 1.0);
    return progress;
  }

  /// Calculate warming up progress (0.0 = just started detecting, 1.0 = ready to record)
  double _getWarmingUpProgress(MotionService motionService) {
    if (motionService.firstMovementTime == null || !motionService.isMoving) {
      return 0.0;
    }

    final warmingDuration = DateTime.now().difference(motionService.firstMovementTime!);
    const maxWarmUpSeconds = 3; // Match _sustainedMotionDuration in MotionService
    final progress = (warmingDuration.inSeconds / maxWarmUpSeconds).clamp(0.0, 1.0);
    return progress;
  }

  Widget _buildPIPCameraPreview(CameraService cameraService) {
    return Consumer2<MotionService, LocationService>(
      builder: (context, motionService, locationService, child) {
        final countdownProgress = _getIdleCountdownProgress(motionService);
        final showCountdown = countdownProgress > 0.0;
        final secondsRemaining = (30 * (1.0 - countdownProgress)).round();

        // Get camera view info
        final cameraInfo = motionService.getCameraViewInfo(locationService.heading);
        final view = cameraInfo['view'] ?? 'unknown';
        final compassDir = cameraInfo['compassDirection'] ?? '-';
        final speedKmh = (locationService.speed ?? 0) * 3.6; // m/s to km/h

        return Positioned(
          top: 80,
          right: 20,
          child: GestureDetector(
            onTap: () {
              // Tap to go fullscreen
              setState(() {
                _showFullscreenCamera = true;
              });
            },
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right to go fullscreen
                setState(() {
                  _showFullscreenCamera = true;
                });
              }
            },
            child: Container(
              width: 150,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(cameraService.controller!),

                    // Camera placement info at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                        ),
                        child: Text(
                          '${view.replaceAll('_', ' ')} → $compassDir (${speedKmh.toStringAsFixed(0)} km/h)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Idle countdown progress bar at bottom
                    if (showCountdown)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Countdown text
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, color: Colors.orange, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${secondsRemaining}s',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Progress bar
                            LinearProgressIndicator(
                              value: countdownProgress,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                countdownProgress > 0.8 ? Colors.red : Colors.orange,
                              ),
                              minHeight: 3,
                            ),
                          ],
                        ),
                      ),

                    // Tap hint (only show when not showing countdown)
                    if (!showCountdown)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Tap',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullscreenCamera() {
    return Consumer3<CameraService, MotionService, LocationService>(
      builder: (context, cameraService, motionService, locationService, child) {
        if (!cameraService.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final countdownProgress = _getIdleCountdownProgress(motionService);
        final showCountdown = countdownProgress > 0.0;
        final secondsRemaining = (30 * (1.0 - countdownProgress)).round();

        // Get camera view info
        final cameraInfo = motionService.getCameraViewInfo(locationService.heading);
        final view = cameraInfo['view'] ?? 'unknown';
        final compassDir = cameraInfo['compassDirection'] ?? '-';
        final speedKmh = (locationService.speed ?? 0) * 3.6; // m/s to km/h

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(cameraService.controller!),

            // Camera placement info at top center
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${view.replaceAll('_', ' ')} → $compassDir (${speedKmh.toStringAsFixed(0)} km/h)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Back arrow
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFullscreenCamera = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Stop button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await _stopRecording(cameraService);
                    setState(() {
                      _showFullscreenCamera = false;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            // Recording indicator
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: 8),
                    Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Idle countdown progress bar at bottom
            if (showCountdown)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Auto-stop in ${secondsRemaining}s',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: countdownProgress,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          countdownProgress > 0.8 ? Colors.red : Colors.orange,
                        ),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecordButton(CameraService cameraService) {
    return GestureDetector(
      onTap: () async {
        if (cameraService.isRecording) {
          await _stopRecording(cameraService);
        } else {
          await _startRecording(cameraService);
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cameraService.isRecording ? Colors.red : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          cameraService.isRecording ? Icons.stop : Icons.videocam,
          color: cameraService.isRecording ? Colors.white : Colors.red,
          size: 40,
        ),
      ),
    );
  }

  Future<void> _startRecording(CameraService cameraService) async {
    // Prevent double-clicks - silently ignore if already recording or in progress
    if (_isRecordingInProgress || cameraService.isRecording) {
      debugPrint('⏸️ Start recording ignored - already recording or in progress');
      return;
    }

    _isRecordingInProgress = true;

    final deviceLogger = Provider.of<DeviceLoggerService>(context, listen: false);

    try {
      await cameraService.startRecording();

      // Start CSV logging
      final dataLoggerService = Provider.of<DataLoggerService>(context, listen: false);
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}';
      await dataLoggerService.startLogging(fileName);

      // Log recording started
      await deviceLogger.logRecordingStarted(
        fileName,
        isAutoRecording: _autoRecordEnabled,
      );

      // Notify server that recording started
      final serverService = Provider.of<ServerService>(context, listen: false);
      serverService.setRecordingStatus(true);

      // Start periodic data logging (every 100ms)
      _dataLogTimer?.cancel();
      _dataLogTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final motionService = Provider.of<MotionService>(context, listen: false);
        final locationService = Provider.of<LocationService>(context, listen: false);
        dataLoggerService.logDataPoint(
          accelX: motionService.accelX,
          accelY: motionService.accelY,
          accelZ: motionService.accelZ,
          gyroX: motionService.gyroX,
          gyroY: motionService.gyroY,
          gyroZ: motionService.gyroZ,
          roughness: motionService.calculateRoughness(),
          roughnessLevel: motionService.getRoughnessLevel(),
          orientation: motionService.orientation,
          isMoving: motionService.isMoving,
          latitude: locationService.latitude,
          longitude: locationService.longitude,
          altitude: locationService.altitude,
          speedMps: locationService.speed,
          accuracy: locationService.accuracy,
        );
      });

      // Start countdown display update timer (every second)
      _countdownUpdateTimer?.cancel();
      _countdownUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {}); // Trigger rebuild to update countdown display
        }
      });

      // Navigate to Driving Mode when recording starts
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DrivingModeScreen(),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error starting recording: $e');
      await deviceLogger.logException('recording_start_failed', e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isRecordingInProgress = false;
    }
  }

  Future<void> _stopRecording(CameraService cameraService) async {
    // Prevent double-clicks - silently ignore if not recording or operation in progress
    if (_isRecordingInProgress || !cameraService.isRecording) {
      debugPrint('⏸️ Stop recording ignored - not recording or operation in progress');
      return;
    }

    _isRecordingInProgress = true;

    final deviceLogger = Provider.of<DeviceLoggerService>(context, listen: false);
    final startTime = DateTime.now();

    try {
      // Stop periodic data logging
      _dataLogTimer?.cancel();
      _countdownUpdateTimer?.cancel();

      final filePath = await cameraService.stopRecording();
      if (filePath != null && mounted) {
        // Stop CSV logging
        final dataLoggerService = Provider.of<DataLoggerService>(context, listen: false);
        await dataLoggerService.stopLogging();

        // Notify server that recording stopped
        final serverService = Provider.of<ServerService>(context, listen: false);
        serverService.setRecordingStatus(false);

        // Add to storage service
        final storageService = Provider.of<StorageService>(context, listen: false);
        await storageService.addRecording(filePath);

        // Get recording info and log it
        final recording = storageService.getRecordingByPath(filePath);
        if (recording != null) {
          final duration = DateTime.now().difference(startTime);
          await deviceLogger.logRecordingEnded(
            recording.fileName,
            duration,
            recording.fileSizeBytes,
          );

          // Queue video for upload
          serverService.queueVideoUpload(recording);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording saved and queued for upload!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Switch to recordings tab if not in auto-record mode
        if (!_autoRecordEnabled) {
          setState(() {
            _selectedIndex = 1;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error stopping recording: $e');
      await deviceLogger.logException('recording_stop_failed', e, stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isRecordingInProgress = false;
    }
  }

  Widget _buildRecordingsView() {
    return Consumer2<StorageService, ServerService>(
      builder: (context, storageService, serverService, child) {
        final hasUnsentVideos = storageService.recordings
            .any((r) => r.uploadStatus != UploadStatus.uploaded);

        return Column(
          children: [
            // Tab Bar
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _recordingsTabController,
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1E88E5),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.upload),
                        const SizedBox(width: 8),
                        const Text('Sending'),
                        if (serverService.uploadQueueSize > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${serverService.uploadQueueSize}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text('Sent'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Upload Status Indicator
            if (hasUnsentVideos)
              _buildUploadStatusIndicator(serverService),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _recordingsTabController,
                children: [
                  _buildSendingTab(storageService, serverService),
                  _buildSentTab(storageService),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadStatusIndicator(ServerService serverService) {
    IconData icon;
    Color color;
    String message;
    Widget? trailing;

    switch (_uploadStatus) {
      case 'connecting':
        icon = Icons.wifi_find;
        color = Colors.blue;
        message = 'Connecting...';
        trailing = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
        );
        break;

      case 'uploading':
        icon = Icons.cloud_upload;
        color = Colors.green;
        final sizeMB = (_uploadingFileSize / 1024 / 1024).toStringAsFixed(1);
        final percent = (_uploadProgress * 100).toInt();
        message = 'Sending: ${sizeMB}MB';
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.green.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ],
        );
        break;

      case 'error':
        icon = Icons.error_outline;
        color = Colors.orange;
        message = 'Unable to connect';
        trailing = Text(
          'Retry in ${_retryCountdown}s',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        );
        break;

      default: // idle
        if (serverService.uploadQueueSize == 0) {
          icon = Icons.check_circle_outline;
          color = Colors.grey;
          message = 'No files to send';
        } else {
          icon = Icons.schedule;
          color = Colors.orange;
          message = '${serverService.uploadQueueSize} file${serverService.uploadQueueSize > 1 ? "s" : ""} queued';
        }
        trailing = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // Sending Tab - shows videos queued or uploading
  Widget _buildSendingTab(StorageService storageService, ServerService serverService) {
    final unsentRecordings = storageService.recordings
        .where((r) => r.uploadStatus == UploadStatus.notUploaded ||
                      r.uploadStatus == UploadStatus.uploading ||
                      r.uploadStatus == UploadStatus.failed)
        .toList();

    if (unsentRecordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'All videos sent!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'New recordings will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unsentRecordings.length,
      itemBuilder: (context, index) {
        final recording = unsentRecordings[index];
        return _buildSendingRecordingItem(recording, storageService);
      },
    );
  }

  // Sent Tab - shows uploaded videos grouped by month
  Widget _buildSentTab(StorageService storageService) {
    final sentRecordings = storageService.recordings
        .where((r) => r.uploadStatus == UploadStatus.uploaded)
        .toList();

    if (sentRecordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No sent videos yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Uploaded videos will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Group recordings by month
    final Map<String, List<VideoRecording>> groupedByMonth = {};
    for (final recording in sentRecordings) {
      final monthKey = '${recording.createdAt.year}-${recording.createdAt.month.toString().padLeft(2, '0')}';
      groupedByMonth.putIfAbsent(monthKey, () => []).add(recording);
    }

    // Sort months descending (newest first)
    final sortedMonthKeys = groupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMonthKeys.length,
      itemBuilder: (context, index) {
        final monthKey = sortedMonthKeys[index];
        final recordings = groupedByMonth[monthKey]!;
        return _buildMonthGroup(monthKey, recordings, storageService);
      },
    );
  }

  // Month group widget with header and video list
  Widget _buildMonthGroup(String monthKey, List<VideoRecording> recordings, StorageService storageService) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final monthName = _getMonthName(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month header with count
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName $year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recordings.length} ${recordings.length == 1 ? "video" : "videos"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Videos in this month
        ...recordings.map((recording) => _buildRecordingItem(recording, storageService)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Sending tab recording item with upload status
  Widget _buildSendingRecordingItem(VideoRecording recording, StorageService storageService) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (recording.uploadStatus) {
      case UploadStatus.uploading:
        statusIcon = Icons.cloud_upload;
        statusColor = Colors.blue;
        statusText = 'Uploading...';
        break;
      case UploadStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
      default:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        statusText = 'Queued';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Video thumbnail placeholder
            Container(
              width: 100,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videocam,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 12),
            // Recording info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration and Size
                  Row(
                    children: [
                      Icon(Icons.videocam, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        recording.formattedDuration,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.sd_card, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatFileSize(recording.fileSizeBytes),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Time ago (prominent)
                  Text(
                    _formatTimeAgo(recording.createdAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Actual date (subtle)
                  Text(
                    _formatDateTime(recording.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Upload status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingItem(VideoRecording recording, StorageService storageService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showVideoPlayer(recording);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Video thumbnail placeholder
              Container(
                width: 100,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 12),
              // Recording info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration and Size
                    Row(
                      children: [
                        Icon(Icons.videocam, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          recording.formattedDuration,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.sd_card, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          _formatFileSize(recording.fileSizeBytes),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time ago (prominent)
                    Text(
                      _formatTimeAgo(recording.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Actual date (subtle)
                    Text(
                      _formatDateTime(recording.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _showDeleteConfirmation(recording, storageService);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(VideoRecording recording) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(recording: recording),
      ),
    );
  }

  void _showDeleteConfirmation(VideoRecording recording, StorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete ${recording.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              storageService.deleteRecording(recording);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? "minute" : "minutes"} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Video Player Screen
class VideoPlayerScreen extends StatefulWidget {
  final VideoRecording recording;

  const VideoPlayerScreen({super.key, required this.recording});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.recording.filePath));
    await _controller.initialize();
    setState(() {
      _isInitialized = true;
    });
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            if (_showControls)
              Positioned(
                top: 50,
                left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

            if (_showControls && _isInitialized)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
