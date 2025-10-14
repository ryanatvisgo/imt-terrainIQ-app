import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

/// Service to detect device orientation and motion for auto-recording
class MotionService extends ChangeNotifier {
  // Sensor stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Device orientation state
  String _orientation = 'unknown'; // 'top_down', 'bottom_down', 'left_down', 'right_down', 'flat', 'unknown'
  bool _isMoving = false;
  DateTime? _lastMovementTime;
  DateTime? _firstMovementTime; // Track when sustained movement started
  bool _ignoreFlatOrientation = false; // Toggle for flat placement check

  // Motion detection parameters
  static const double _deltaThreshold = 0.8; // Change threshold for motion detection (works in any orientation)
  static const double _velocityThreshold = 0.4; // m/s minimum speed for recording (~0.9 mph)
  static const double _orientationThreshold = 7.0; // m/s² for gravity detection
  static const Duration _sustainedMotionDuration = Duration(seconds: 3); // Must move for 3 seconds
  static const Duration _idleTimeout = Duration(seconds: 30); // Stop after 30s idle

  // Delta-based motion detection (works in any orientation)
  double? _previousMagnitude;
  List<double> _recentDeltas = []; // Last 10 magnitude changes
  static const int _deltaSampleSize = 10; // Last 10 readings for averaging

  // Accelerometer data for roughness detection
  List<double> _accelerometerMagnitudes = [];
  static const int _roughnessSampleSize = 100; // Last 100 readings

  // Current sensor readings
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // Getters
  String get orientation => _orientation;
  bool get isMoving => _isMoving;
  DateTime? get lastMovementTime => _lastMovementTime;
  DateTime? get firstMovementTime => _firstMovementTime; // For warming up indicator
  double get accelX => _accelX;
  double get accelY => _accelY;
  double get accelZ => _accelZ;
  double get gyroX => _gyroX;
  double get gyroY => _gyroY;
  double get gyroZ => _gyroZ;
  bool get ignoreFlatOrientation => _ignoreFlatOrientation;

  /// Set whether to ignore flat orientation for recording
  /// Useful for mounting camera facing straight down (e.g., off back of vehicle)
  void setIgnoreFlatOrientation(bool ignore) {
    if (_ignoreFlatOrientation != ignore) {
      _ignoreFlatOrientation = ignore;
      debugPrint('📱 MotionService: Ignore flat orientation = $ignore');
      notifyListeners();
    }
  }

  /// Initialize sensor listeners
  Future<void> initialize() async {
    debugPrint('🔵 MotionService: Initializing...');

    // Listen to accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint('❌ MotionService: Accelerometer error: $error');
      },
    );

    // Listen to gyroscope
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      _handleGyroscopeEvent,
      onError: (error) {
        debugPrint('❌ MotionService: Gyroscope error: $error');
      },
    );

    debugPrint('✅ MotionService: Initialized');
  }

  /// Handle accelerometer events
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    _accelX = event.x;
    _accelY = event.y;
    _accelZ = event.z;

    final now = DateTime.now();

    // Calculate magnitude for roughness detection
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    _accelerometerMagnitudes.add(magnitude);
    if (_accelerometerMagnitudes.length > _roughnessSampleSize) {
      _accelerometerMagnitudes.removeAt(0);
    }

    // Determine device orientation based on gravity
    _updateOrientation(event.x, event.y, event.z);

    // Calculate delta from previous magnitude (works in any phone orientation)
    if (_previousMagnitude != null) {
      final delta = (magnitude - _previousMagnitude!).abs();
      _recentDeltas.add(delta);
      if (_recentDeltas.length > _deltaSampleSize) {
        _recentDeltas.removeAt(0);
      }
    }
    _previousMagnitude = magnitude;

    // Calculate average delta to determine if moving
    double averageDelta = 0.0;
    if (_recentDeltas.length >= 5) {
      averageDelta = _recentDeltas.reduce((a, b) => a + b) / _recentDeltas.length;
    }

    // Detect movement based on delta threshold (change in acceleration = motion)
    final hasSignificantMotion = averageDelta > _deltaThreshold;

    if (hasSignificantMotion) {
      _lastMovementTime = now;

      // Track when sustained movement started
      if (_firstMovementTime == null) {
        _firstMovementTime = now;
        debugPrint('🚗 MotionService: Movement started (delta: ${averageDelta.toStringAsFixed(3)} m/s²)');
      } else {
        // Log periodic motion updates (every 5 seconds)
        final timeSinceFirstMovement = now.difference(_firstMovementTime!);
        if (timeSinceFirstMovement.inSeconds % 5 == 0) {
          debugPrint('🚗 MotionService: Still moving (delta: ${averageDelta.toStringAsFixed(3)} m/s²)');
        }
      }

      if (!_isMoving) {
        _isMoving = true;
        notifyListeners();
      }
    } else {
      // Check if motion stopped recently (within last 1 second)
      if (_lastMovementTime != null) {
        final timeSinceLastMotion = now.difference(_lastMovementTime!);

        // If no motion for more than 1 second, mark as stopped for UI
        if (timeSinceLastMotion > const Duration(seconds: 1)) {
          if (_isMoving) {
            _isMoving = false;
            debugPrint('⏸️ MotionService: Stopped (no motion for ${timeSinceLastMotion.inMilliseconds}ms)');
            notifyListeners();
          }
        }

        // Reset sustained movement timer if idle for more than 2 seconds
        if (timeSinceLastMotion > const Duration(seconds: 2)) {
          _firstMovementTime = null;
        }
      }
    }
  }

  /// Handle gyroscope events
  void _handleGyroscopeEvent(GyroscopeEvent event) {
    _gyroX = event.x;
    _gyroY = event.y;
    _gyroZ = event.z;
  }

  /// Determine device orientation from accelerometer data
  /// Detects which edge of the phone is pointing down
  void _updateOrientation(double x, double y, double z) {
    String newOrientation;

    // Phone is relatively flat if Z acceleration is close to -9.8
    if (z.abs() > _orientationThreshold) {
      newOrientation = 'flat';
    }
    // Check which edge is pointing down based on gravity direction
    // Y-axis: top/bottom edges
    else if (y.abs() > x.abs() && y.abs() > _orientationThreshold) {
      // Positive Y = top edge pointing down (camera pointing forward when in landscape)
      // Negative Y = bottom edge pointing down (camera pointing backward when in landscape)
      newOrientation = y > 0 ? 'top_down' : 'bottom_down';
    }
    // X-axis: left/right edges
    else if (x.abs() > y.abs() && x.abs() > _orientationThreshold) {
      // Positive X = right edge pointing down (side mount - right side)
      // Negative X = left edge pointing down (side mount - left side)
      newOrientation = x > 0 ? 'right_down' : 'left_down';
    }
    else {
      newOrientation = 'unknown';
    }

    if (newOrientation != _orientation) {
      _orientation = newOrientation;
      debugPrint('📱 MotionService: Orientation changed to $_orientation (x:${x.toStringAsFixed(1)}, y:${y.toStringAsFixed(1)}, z:${z.toStringAsFixed(1)})');
      notifyListeners();
    }
  }

  /// Check if the device is in a valid position for recording
  /// Returns true for any known orientation (top_down, bottom_down, left_down, right_down, flat)
  bool get isValidRecordingPosition {
    // Accept all orientations except 'unknown'
    // This allows mounting on windshield, side windows, or rear window
    return _orientation != 'unknown';
  }

  /// Check if recording should start based on sustained motion and orientation
  /// Requires:
  /// - Valid recording position (orientation)
  /// - Currently moving (based on delta threshold)
  /// - Sustained motion for at least 3 seconds
  bool get shouldStartRecording {
    if (!isValidRecordingPosition) {
      return false;
    }

    if (!_isMoving) {
      return false;
    }

    // Check if movement has been sustained for required duration
    if (_firstMovementTime == null) {
      return false;
    }

    final movementDuration = DateTime.now().difference(_firstMovementTime!);
    final hasSustainedMotion = movementDuration >= _sustainedMotionDuration;

    if (hasSustainedMotion) {
      debugPrint('✅ MotionService: Sustained motion detected - duration: ${movementDuration.inSeconds}s');
    }

    return hasSustainedMotion;
  }

  /// Check if recording should stop based on idle time only
  /// Orientation changes do NOT stop recording - only prolonged lack of motion
  bool get shouldStopRecording {
    if (_lastMovementTime == null) {
      return true; // No movement detected yet
    }

    final idleDuration = DateTime.now().difference(_lastMovementTime!);
    return idleDuration >= _idleTimeout; // Stop after 30s of no motion
  }

  /// Calculate road roughness based on accelerometer variance
  /// Returns a value between 0.0 (smooth) and 1.0 (very rough)
  double calculateRoughness() {
    if (_accelerometerMagnitudes.length < 10) {
      return 0.0; // Not enough data
    }

    // Calculate variance of accelerometer magnitude
    final mean = _accelerometerMagnitudes.reduce((a, b) => a + b) / _accelerometerMagnitudes.length;
    final variance = _accelerometerMagnitudes
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) / _accelerometerMagnitudes.length;

    // Normalize variance to 0-1 scale (empirically determined range)
    // Variance of 0-5 maps to 0.0-1.0
    final roughness = (variance / 5.0).clamp(0.0, 1.0);

    return roughness;
  }

  /// Get roughness level as a string
  String getRoughnessLevel() {
    final roughness = calculateRoughness();
    if (roughness < 0.2) return 'smooth';
    if (roughness < 0.5) return 'moderate';
    if (roughness < 0.8) return 'rough';
    return 'very_rough';
  }

  /// Get camera view direction based on phone orientation and GPS heading
  /// Returns a map with 'view' (forward/rear/left_side/right_side) and 'cameraHeading' (degrees)
  Map<String, dynamic> getCameraViewInfo(double? gpsHeading) {
    if (gpsHeading == null) {
      return {'view': 'unknown', 'cameraHeading': null};
    }

    String view;
    double cameraHeading;

    switch (_orientation) {
      case 'top_down':
        // Camera pointing in direction of travel
        view = 'forward';
        cameraHeading = gpsHeading;
        break;
      case 'bottom_down':
        // Camera pointing opposite direction of travel
        view = 'rear';
        cameraHeading = (gpsHeading + 180) % 360;
        break;
      case 'left_down':
        // Camera pointing 90° left of direction of travel
        view = 'left_side';
        cameraHeading = (gpsHeading - 90 + 360) % 360;
        break;
      case 'right_down':
        // Camera pointing 90° right of direction of travel
        view = 'right_side';
        cameraHeading = (gpsHeading + 90) % 360;
        break;
      default:
        view = 'unknown';
        cameraHeading = gpsHeading;
    }

    return {
      'view': view,
      'cameraHeading': cameraHeading,
      'compassDirection': _getCompassDirection(cameraHeading),
    };
  }

  /// Convert heading degrees to compass direction (N, NE, E, etc.)
  String _getCompassDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  @override
  void dispose() {
    debugPrint('🔵 MotionService: Disposing...');
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
}
