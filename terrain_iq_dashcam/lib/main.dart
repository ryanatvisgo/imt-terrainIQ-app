import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/camera_service.dart';
import 'services/storage_service.dart';
import 'services/permission_service.dart';
import 'services/motion_service.dart';
import 'services/data_logger_service.dart';
import 'services/device_logger_service.dart';
import 'services/server_service.dart';
import 'services/location_service.dart';
import 'services/hazard_service.dart';
import 'services/mqtt_service.dart';
import 'services/mqtt_preview_service_js.dart';
import 'screens/preview_mode_screen.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize device logger first
  final deviceLogger = DeviceLoggerService();
  await deviceLogger.initialize();

  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    deviceLogger.logException(
      'flutter_error',
      details.exception,
      stackTrace: details.stack,
      metadata: {
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'no context',
      },
    );
  };

  // Catch errors not caught by Flutter framework
  runZonedGuarded(() {
    runApp(TerrainIQDashcamApp(deviceLogger: deviceLogger));
  }, (error, stackTrace) {
    debugPrint('❌ Uncaught error: $error');
    deviceLogger.logException(
      'uncaught_error',
      error,
      stackTrace: stackTrace,
    );
  });
}

class TerrainIQDashcamApp extends StatelessWidget {
  final DeviceLoggerService deviceLogger;

  const TerrainIQDashcamApp({super.key, required this.deviceLogger});

  static bool _isPreviewMode = false;

  String _getInitialRoute() {
    if (kIsWeb) {
      final hash = html.window.location.hash;
      final href = html.window.location.href;
      final port = html.window.location.port;

      debugPrint('🌐 URL: $href');
      debugPrint('🌐 Port: $port');
      debugPrint('🌐 Hash: $hash');

      // If running on port 3201, it's the simulator preview mode
      if (port == '3201') {
        debugPrint('🌐 Port 3201 detected - loading preview screen for simulator');
        _isPreviewMode = true;
        return '/preview';
      }

      // Also check hash as fallback
      if (hash == '#/preview' || hash == '#preview' || hash.contains('/preview')) {
        debugPrint('🌐 Preview hash detected - loading preview screen');
        _isPreviewMode = true;
        return '/preview';
      }
    }
    _isPreviewMode = false;
    return '/';
  }

  static bool get isPreviewMode => _isPreviewMode;

  @override
  Widget build(BuildContext context) {
    final initialRoute = _getInitialRoute();
    debugPrint('🚀 App starting with initial route: $initialRoute');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: deviceLogger),
        ChangeNotifierProvider(create: (_) => CameraService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => PermissionService()),
        ChangeNotifierProvider(create: (_) => MotionService()),
        ChangeNotifierProvider(create: (_) => DataLoggerService()),
        ChangeNotifierProvider(create: (_) => ServerService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => MqttService()),
        ChangeNotifierProvider(create: (_) => MqttPreviewServiceJs()),
        ChangeNotifierProxyProvider2<LocationService, MqttService, HazardService>(
          create: (context) => HazardService(
            context.read<LocationService>(),
            context.read<MqttService>(),
          ),
          update: (context, locationService, mqttService, previous) =>
              previous ?? HazardService(locationService, mqttService),
        ),
      ],
      child: MaterialApp(
        title: 'TerrainIQ Dashcam',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
          ),
        ),
        initialRoute: initialRoute,
        routes: {
          '/': (context) => const SplashScreen(),
          '/preview': (context) => const PreviewModeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}