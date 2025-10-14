import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Service to manage device location tracking
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  String? _error;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get error => _error;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
  double? get altitude => _currentPosition?.altitude;
  double? get speed => _currentPosition?.speed; // m/s
  double? get heading => _currentPosition?.heading; // degrees
  double? get accuracy => _currentPosition?.accuracy; // meters

  /// Initialize location service and check permissions
  Future<bool> initialize() async {
    debugPrint('🌍 LocationService: Initializing...');

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        debugPrint('❌ LocationService: Location services disabled');
        notifyListeners();
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          debugPrint('❌ LocationService: Permission denied');
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        debugPrint('❌ LocationService: Permission permanently denied');
        notifyListeners();
        return false;
      }

      // Get initial position
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        debugPrint('✅ LocationService: Initial position obtained');
        debugPrint('   → Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}');
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ LocationService: Could not get initial position: $e');
      }

      debugPrint('✅ LocationService: Initialized');
      return true;
    } catch (e) {
      _error = 'Failed to initialize: $e';
      debugPrint('❌ LocationService: Initialization error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Start tracking location updates
  Future<void> startTracking() async {
    if (_isTracking) {
      debugPrint('⚠️ LocationService: Already tracking');
      return;
    }

    debugPrint('🌍 LocationService: Starting location tracking...');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
      // No timeLimit - stream should continue indefinitely, using last known position
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _error = null;
        notifyListeners();

        // Log position updates periodically (every 10 seconds)
        if (DateTime.now().second % 10 == 0) {
          debugPrint('📍 Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} '
              '(±${position.accuracy.toStringAsFixed(1)}m, ${position.speed.toStringAsFixed(1)}m/s)');
        }
      },
      onError: (error) {
        _error = 'Location stream error: $error';
        debugPrint('❌ LocationService: Stream error: $error');
        notifyListeners();
      },
    );

    _isTracking = true;
    notifyListeners();
    debugPrint('✅ LocationService: Tracking started');
  }

  /// Stop tracking location updates
  void stopTracking() {
    if (!_isTracking) return;

    debugPrint('🌍 LocationService: Stopping location tracking...');
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
    debugPrint('✅ LocationService: Tracking stopped');
  }

  /// Calculate distance to a point in meters
  double? distanceTo(double targetLat, double targetLon) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  /// Calculate bearing to a point in degrees (0-360)
  double? bearingTo(double targetLat, double targetLon) {
    if (_currentPosition == null) return null;

    return Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  @override
  void dispose() {
    debugPrint('🌍 LocationService: Disposing...');
    stopTracking();
    super.dispose();
  }
}
