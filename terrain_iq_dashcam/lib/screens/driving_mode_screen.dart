import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/camera_service.dart';
import '../services/hazard_service.dart';
import '../services/location_service.dart';
import '../services/motion_service.dart';
import '../services/data_logger_service.dart';
import '../services/device_logger_service.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';
import '../models/hazard.dart';

class DrivingModeScreen extends StatefulWidget {
  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen> with SingleTickerProviderStateMixin {
  Timer? _proximityCheckTimer;
  Timer? _motionCheckTimer;
  Timer? _dataLogTimer;
  Timer? _countdownUpdateTimer;
  late AnimationController _flashController;
  late PageController _pageController;
  int _currentPage = 0;
  bool _autoRecordEnabled = true; // Default ON as per user requirement
  bool _isRecordingInProgress = false; // Prevent double-clicks
  bool _wasMovingLastCheck = false; // Track motion state changes

  @override
  void initState() {
    super.initState();
    _startProximityChecks();
    _startMotionCheckTimer();
    _pageController = PageController(initialPage: 0);

    // Setup flashing animation for recording indicator
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _startProximityChecks() {
    final hazardService = Provider.of<HazardService>(context, listen: false);

    // Check proximity every second
    _proximityCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      hazardService.updateProximity();
    });
  }

  @override
  void dispose() {
    _proximityCheckTimer?.cancel();
    _motionCheckTimer?.cancel();
    _dataLogTimer?.cancel();
    _countdownUpdateTimer?.cancel();
    _flashController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startMotionCheckTimer() {
    _motionCheckTimer?.cancel();
    _motionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAutoRecordConditions();

      final cameraService = Provider.of<CameraService>(context, listen: false);
      final motionService = Provider.of<MotionService>(context, listen: false);

      // Track motion state changes for debugging
      if (motionService.isMoving && !_wasMovingLastCheck) {
        _wasMovingLastCheck = true;
        debugPrint('🚗 Motion started');
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
    }
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

  @override
  Widget build(BuildContext context) {
    return Consumer4<CameraService, HazardService, LocationService, MotionService>(
      builder: (context, cameraService, hazardService, locationService, motionService, child) {
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                // PageView with 2 pages
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Page 1: Hazard HUD (default)
                    _buildHazardPage(cameraService, hazardService, locationService, motionService),

                    // Page 2: Full-screen Camera View
                    _buildCameraPage(cameraService, motionService, locationService),
                  ],
                ),

                // Back button (top left) - shows on all pages
                Positioned(
                  top: 20,
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
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Page indicator dots (bottom center)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPageIndicator(0),
                      const SizedBox(width: 8),
                      _buildPageIndicator(1),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    final isActive = _currentPage == pageIndex;
    return Container(
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
    );
  }

  /// Build Hazard HUD page (Page 1 - default)
  Widget _buildHazardPage(
    CameraService cameraService,
    HazardService hazardService,
    LocationService locationService,
    MotionService motionService,
  ) {
    // Determine background color based on proximity and severity
    Color backgroundColor = _getBackgroundColor(hazardService);

    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          // HUD Warning Display (takes most of screen)
          Positioned.fill(
            child: _buildHUDDisplay(hazardService, locationService),
          ),

          // Status indicators (bottom right corner - moved to avoid overlap)
          Positioned(
            bottom: 80, // Above the page indicator dots
            right: 20,
            child: _buildStatusIndicators(cameraService, motionService),
          ),
        ],
      ),
    );
  }

  /// Build full-screen camera page (Page 2 - swipeable)
  Widget _buildCameraPage(
    CameraService cameraService,
    MotionService motionService,
    LocationService locationService,
  ) {
    if (!cameraService.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera not available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    // Get camera view info
    final cameraInfo = motionService.getCameraViewInfo(locationService.heading);
    final view = cameraInfo['view'] ?? 'unknown';
    final compassDir = cameraInfo['compassDirection'] ?? '-';
    final speedKmh = (locationService.speed ?? 0) * 3.6; // m/s to km/h

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(cameraService.controller!),

          // Camera info overlay (top center)
          Positioned(
            top: 20,
            left: 60,
            right: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${view.replaceAll('_', ' ').toUpperCase()} → $compassDir',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${speedKmh.toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Auto-record toggle (top left - when not recording)
          if (!cameraService.isRecording)
            _buildAutoRecordToggle(motionService),

          // Recording indicator (if recording)
          if (cameraService.isRecording)
            Positioned(
              top: 100,
              right: 20,
              child: FadeTransition(
                opacity: _flashController,
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
            ),

          // Record button at bottom (manual control)
          Positioned(
            bottom: 80, // Above the page indicator dots
            left: 0,
            right: 0,
            child: Center(
              child: _buildRecordButton(cameraService),
            ),
          ),
        ],
      ),
    );
  }

  /// Build auto-record toggle with motion status indicators
  Widget _buildAutoRecordToggle(MotionService motionService) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final roughnessColor = _getRoughnessColor(motionService.getRoughnessLevel());
    final roughnessLevel = motionService.getRoughnessLevel();
    final warmingProgress = _getWarmingUpProgress(motionService);
    final showWarming = warmingProgress > 0.0 && warmingProgress < 1.0 && _autoRecordEnabled;

    return Positioned(
      top: isLandscape ? 20 : 100,
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
            ? _buildCompactAutoRecordToggle(motionService, warmingProgress, showWarming, roughnessLevel, roughnessColor)
            : _buildExpandedAutoRecordToggle(motionService, warmingProgress, showWarming, roughnessLevel, roughnessColor),
      ),
    );
  }

  /// Build compact auto-record toggle (landscape mode)
  Widget _buildCompactAutoRecordToggle(MotionService motionService, double warmingProgress, bool showWarming, String roughnessLevel, Color roughnessColor) {
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

        // Enhanced roughness indicator
        _buildEnhancedRoughnessIndicator(roughnessLevel, roughnessColor),
      ],
    );
  }

  /// Build expanded auto-record toggle (portrait mode)
  Widget _buildExpandedAutoRecordToggle(MotionService motionService, double warmingProgress, bool showWarming, String roughnessLevel, Color roughnessColor) {
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
              color: roughnessColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Road: ${roughnessLevel.replaceAll('_', ' ')}',
              style: TextStyle(
                color: roughnessColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build record button (manual start/stop)
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

  /// Get background color based on hazard proximity and severity
  Color _getBackgroundColor(HazardService hazardService) {
    if (!hazardService.hasActiveWarning) {
      return const Color(0xFF1976D2); // Safe blue
    }

    final hazard = hazardService.closestHazard;
    final distance = hazardService.distanceToClosest;
    if (hazard == null || distance == null) return const Color(0xFF1976D2);

    // Red ONLY if within 250m AND high severity (8-10)
    if (distance < 250 && hazard.severity >= 8) {
      return const Color(0xFFD32F2F); // Red
    }

    // Orange for medium-high severity (5-10) when >250m OR medium severity <250m
    if (hazard.severity >= 5) {
      return const Color(0xFFFF6F00); // Orange
    }

    // Low severity: Yellow
    return const Color(0xFFFBC02D); // Yellow
  }

  /// Build HUD warning display
  Widget _buildHUDDisplay(HazardService hazardService, LocationService locationService) {
    // Check if location is available
    final hasLocation = locationService.latitude != null && locationService.longitude != null;
    final hasHeading = locationService.heading != null;

    if (!hazardService.hasActiveWarning) {
      // Calculate time since last hazard detection
      String lastRecordedText = 'no recent measurements';
      if (hazardService.lastFetchTime != null) {
        final daysSinceLastFetch = DateTime.now().difference(hazardService.lastFetchTime!).inDays;
        if (daysSinceLastFetch == 0) {
          lastRecordedText = 'last recorded today';
        } else if (daysSinceLastFetch == 1) {
          lastRecordedText = 'last recorded 1 day ago';
        } else {
          lastRecordedText = 'last recorded $daysSinceLastFetch days ago';
        }
      }

      // Get next hazard in forward direction (only if we have location and heading)
      final nextHazardInfo = (hasLocation && hasHeading) ? hazardService.getNextHazardAhead() : null;

      return Stack(
        children: [
          // Main "All Clear" display
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No known hazards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lastRecordedText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Next hazard indicator OR location status (top right corner)
          if (nextHazardInfo != null)
            _buildNextHazardIndicator(nextHazardInfo)
          else if (!hasLocation || !hasHeading)
            _buildLocationStatusIndicator(hasLocation, hasHeading),
        ],
      );
    }

    final hazard = hazardService.closestHazard!;
    final proximity = hazardService.proximityLevel;
    final countdownDistance = hazardService.getCountdownDistance();

    // Calculate bearing to hazard for directional arrow
    double? bearing;
    if (locationService.latitude != null && locationService.longitude != null) {
      bearing = hazard.bearingFrom(locationService.latitude!, locationService.longitude!);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Directional arrow (only show when approaching, not inside zone)
            if (proximity != ProximityLevel.insideZone && bearing != null)
              _buildDirectionalArrow(bearing),

            if (proximity != ProximityLevel.insideZone && bearing != null)
              const SizedBox(height: 16),

            // Warning icon
            Icon(
              Icons.warning_rounded,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),

            // Proximity status
            if (proximity == ProximityLevel.insideZone)
              const Text(
                'IN KNOWN HAZARD ZONE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              )
            else if (countdownDistance != null)
              Column(
                children: [
                  const Text(
                    'HAZARD AHEAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Countdown distance
                  Text(
                    '${countdownDistance}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Hazard type/labels
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    hazard.primaryLabel.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Severity indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'SEVERITY:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${hazard.severity}/10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Additional labels if multiple
            if (hazard.labels.length > 1) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: hazard.labels.skip(1).map((label) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build location status indicator (when GPS unavailable)
  Widget _buildLocationStatusIndicator(bool hasLocation, bool hasHeading) {
    String statusText;
    IconData statusIcon;

    if (!hasLocation && !hasHeading) {
      statusText = 'Location unavailable';
      statusIcon = Icons.location_off;
    } else if (!hasLocation) {
      statusText = 'Searching for GPS';
      statusIcon = Icons.location_searching;
    } else {
      statusText = 'Getting heading';
      statusIcon = Icons.explore_off;
    }

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.7), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build next hazard indicator for top right corner
  Widget _buildNextHazardIndicator(Map<String, dynamic> hazardInfo) {
    final distance = hazardInfo['distance'] as double;
    final relativeBearing = hazardInfo['relativeBearing'] as double;
    final distanceRounded = (distance / 10).round() * 10; // Round to nearest 10m

    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next hazard',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${distanceRounded}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                // Directional arrow (points relative to forward direction)
                Transform.rotate(
                  angle: relativeBearing * math.pi / 180.0,
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build directional arrow pointing toward hazard
  Widget _buildDirectionalArrow(double bearing) {
    return Transform.rotate(
      angle: bearing * math.pi / 180.0, // Convert degrees to radians
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(
          Icons.navigation,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build status indicators (moving, orientation, roughness)
  Widget _buildStatusIndicators(CameraService cameraService, MotionService motionService) {
    final roughnessColor = _getRoughnessColor(motionService.getRoughnessLevel());
    final roughnessLevel = motionService.getRoughnessLevel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          if (cameraService.isRecording)
            _buildStatusDot(Icons.fiber_manual_record, Colors.red)
          else
            _buildStatusDot(Icons.videocam_off, Colors.grey),

          const SizedBox(width: 8),

          // Motion status
          _buildStatusDot(
            motionService.isMoving ? Icons.directions_car : Icons.pause_circle_outline,
            motionService.isMoving ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),

          // Orientation status
          _buildStatusDot(
            Icons.phone_android,
            motionService.isValidRecordingPosition ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),

          // Roughness indicator
          _buildEnhancedRoughnessIndicator(roughnessLevel, roughnessColor),
        ],
      ),
    );
  }

  /// Build status indicator dot
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
        size: 16,
      ),
    );
  }

  /// Build enhanced roughness indicator
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
}
