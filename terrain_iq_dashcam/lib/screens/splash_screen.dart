import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'driving_mode_screen.dart';
import '../services/device_logger_service.dart';
import '../services/server_service.dart';
import '../services/location_service.dart';
import '../services/hazard_service.dart';
import '../services/mqtt_service.dart';
import '../services/camera_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _navigateToHome();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    // If we're in preview mode, skip all initialization - preview screen handles its own setup
    if (TerrainIQDashcamApp.isPreviewMode) {
      debugPrint('🎬 SplashScreen: Preview mode detected, skipping initialization');
      return;
    }

    // Try to upload pending logs from previous sessions (including crash logs)
    // This happens BEFORE the main app initializes to ensure crash logs are uploaded
    try {
      final deviceLogger = Provider.of<DeviceLoggerService>(context, listen: false);
      final serverService = Provider.of<ServerService>(context, listen: false);

      // Initialize server service
      await serverService.initialize();

      // Initialize camera service
      final cameraService = Provider.of<CameraService>(context, listen: false);
      try {
        await cameraService.initializeCamera();
        debugPrint('✅ Splash: Camera initialized successfully');
      } catch (e) {
        debugPrint('⚠️ Splash: Camera initialization failed: $e');
        // Continue anyway - app can still function without camera
      }

      // Initialize location service
      final locationService = Provider.of<LocationService>(context, listen: false);
      await locationService.initialize();
      await locationService.startTracking();

      // Initialize hazard service
      final hazardService = Provider.of<HazardService>(context, listen: false);
      await hazardService.initialize();

      // Initialize MQTT service
      final mqttService = Provider.of<MqttService>(context, listen: false);
      await mqttService.initialize();

      // Get pending logs
      final pendingLogs = await deviceLogger.getPendingLogFiles();

      if (pendingLogs.isNotEmpty) {
        debugPrint('📤 Splash: Found ${pendingLogs.length} pending log files to upload');

        // Try to upload logs (non-blocking, with timeout)
        await serverService.uploadPendingLogs(pendingLogs).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏱️ Splash: Log upload timed out, continuing...');
            return 0;
          },
        ).then((count) async {
          if (count > 0) {
            debugPrint('✅ Splash: Successfully uploaded $count log files');
            // Mark uploaded logs
            for (int i = 0; i < count; i++) {
              await deviceLogger.markLogAsUploaded(pendingLogs[i]);
            }
          }
        }).catchError((e) {
          debugPrint('⚠️ Splash: Error uploading logs: $e');
          // Log the error but continue app startup
          deviceLogger.logError('log_upload_failed', e);
        });
      } else {
        debugPrint('📝 Splash: No pending logs to upload');
      }

      // Clean up old uploaded logs
      await deviceLogger.cleanupOldLogs();
    } catch (e, stackTrace) {
      debugPrint('❌ Splash: Error in log upload process: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't block app startup even if log upload fails
    }

    // Minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DrivingModeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0E1A),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          // GPS Grid overlay
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated glow effect behind truck
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E88E5).withOpacity(0.3 * _pulseController.value),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(35),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/splash_logo.png',
                      width: 130,
                      height: 130,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // TerrainIQ Title with subtle glow
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFCCCCCC)],
                  ).createShader(bounds),
                  child: const Text(
                    'TerrainIQ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle with tech font
                const Text(
                  'Road Intelligence System',
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                // by IntelliMass.ai
                const Text(
                  'by IntelliMass.ai',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 70),
                // Loading indicator with custom style
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF1E88E5).withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Inner spinner
                      const SizedBox(
                        width: 35,
                        height: 35,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'INITIALIZING SYSTEM',
                  style: TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for GPS grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw subtle coordinate markers at intersections
    final markerPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSize * 4) {
      for (double y = 0; y < size.height; y += gridSize * 4) {
        canvas.drawCircle(Offset(x, y), 1.5, markerPaint);
      }
    }

    // Draw corner accent lines (like GPS targeting)
    final accentPaint = Paint()
      ..color = const Color(0xFF1E88E5).withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cornerLength = 40.0;
    final margin = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin + cornerLength, margin),
      accentPaint,
    );
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + cornerLength),
      accentPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin - cornerLength, margin),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + cornerLength),
      accentPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + cornerLength, size.height - margin),
      accentPaint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin, size.height - margin - cornerLength),
      accentPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin - cornerLength, size.height - margin),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin),
      Offset(size.width - margin, size.height - margin - cornerLength),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
