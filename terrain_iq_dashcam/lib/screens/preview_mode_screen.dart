import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_preview_service_js.dart';

/// Preview mode screen for HTML simulator integration
/// Displays real Flutter UI controlled by the HTML simulator via MQTT
class PreviewModeScreen extends StatefulWidget {
  const PreviewModeScreen({super.key});

  @override
  State<PreviewModeScreen> createState() => _PreviewModeScreenState();
}

class _PreviewModeScreenState extends State<PreviewModeScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🎬 PreviewModeScreen: initState() called');
    // Connect to MQTT broker when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🎬 PreviewModeScreen: Post-frame callback - attempting MQTT connection');
      final mqttService = Provider.of<MqttPreviewServiceJs>(context, listen: false);
      debugPrint('🎬 PreviewModeScreen: MqttPreviewServiceJs obtained, calling connect()');
      mqttService.connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttPreviewServiceJs>(
      builder: (context, mqttService, child) {
        if (!mqttService.isConnected) {
          return _buildConnectionStatus(mqttService);
        }

        if (!mqttService.previewEnabled) {
          return _buildWaitingForPreview();
        }

        final state = mqttService.previewState;
        final isLandscape = state.orientation == 'landscape';

        return OrientationBuilder(
          builder: (context, orientation) {
            return Scaffold(
              backgroundColor: _getBackgroundColor(state.severity),
              body: SafeArea(
                child: isLandscape
                    ? _buildLandscapeView(state)
                    : _buildPortraitView(state),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConnectionStatus(MqttPreviewServiceJs mqttService) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Connecting to MQTT broker...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Text(
              'ws://localhost:3301',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForPreview() {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_iphone, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              'Flutter App Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Switch to "Flutter App" mode in the HTML simulator',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'MQTT Connected',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitView(PreviewState state) {
    // Switch between views based on page number
    switch (state.page) {
      case 1:
        // Page 1: HUD Only
        return Column(
          children: [
            _buildHeader(state),
            Expanded(
              child: _buildHazardDisplay(state),
            ),
          ],
        );

      case 2:
        // Page 2: HUD with Camera PIP
        return Column(
          children: [
            _buildHeader(state),
            Expanded(
              child: Stack(
                children: [
                  _buildHazardDisplay(state),
                  // Camera PIP in bottom right
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildCameraPIP(),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3:
        // Page 3: Camera Full Screen with Overlay
        return Stack(
          children: [
            _buildCameraFullScreen(),
            // Overlay header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(state),
            ),
            // Overlay hazard info
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: _buildHazardOverlay(state),
            ),
          ],
        );

      default:
        return Column(
          children: [
            _buildHeader(state),
            Expanded(
              child: _buildHazardDisplay(state),
            ),
          ],
        );
    }
  }

  Widget _buildLandscapeView(PreviewState state) {
    // Switch between views based on page number
    switch (state.page) {
      case 1:
        // Page 1: HUD Only
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildHazardDisplay(state),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: EdgeInsets.all(20),
                child: _buildSideInfo(state),
              ),
            ),
          ],
        );

      case 2:
        // Page 2: HUD with Camera PIP
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildHazardDisplay(state),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildCameraPIP(),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: EdgeInsets.all(20),
                child: _buildSideInfo(state),
              ),
            ),
          ],
        );

      case 3:
        // Page 3: Camera Full Screen with Overlay
        return Stack(
          children: [
            _buildCameraFullScreen(),
            Positioned(
              top: 20,
              left: 20,
              child: _buildHazardOverlay(state),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 250,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildSideInfo(state),
              ),
            ),
          ],
        );

      default:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildHazardDisplay(state),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: EdgeInsets.all(20),
                child: _buildSideInfo(state),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHeader(PreviewState state) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Recording indicator
          Row(
            children: [
              if (state.recording) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          // Speed indicator
          Text(
            state.moving ? '${state.speed.toInt()} km/h' : 'STOPPED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          // Orientation indicator
          Text(
            state.orientation.toUpperCase(),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardDisplay(PreviewState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hazard icon - use Flutter icons instead of emoji
          Icon(
            _getIconForEmoji(state.icon),
            size: 120,
            color: Colors.white,
          ),

          SizedBox(height: 20),

          // Hazard type
          Text(
            state.hazardType.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          SizedBox(height: 40),

          // Distance
          Text(
            '${state.distance.toInt()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),

          Text(
            'METERS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              letterSpacing: 4,
            ),
          ),

          SizedBox(height: 40),

          // Severity indicator
          _buildSeverityBar(state.severity),
        ],
      ),
    );
  }

  Widget _buildSeverityBar(int severity) {
    return Column(
      children: [
        Text(
          'SEVERITY LEVEL',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            final isActive = index < severity;
            return Container(
              width: 30,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? _getSeverityColor(severity)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        SizedBox(height: 8),
        Text(
          '$severity / 10',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSideInfo(PreviewState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREVIEW MODE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 20),
        _buildInfoRow('Distance', '${state.distance.toInt()}m'),
        _buildInfoRow('Severity', '${state.severity}/10'),
        _buildInfoRow('Speed', '${state.speed.toInt()} km/h'),
        _buildInfoRow('Hazard', state.hazardType),
        _buildInfoRow('Recording', state.recording ? 'Active' : 'Inactive'),
        _buildInfoRow('Auto Record', state.autoRecord ? 'On' : 'Off'),
        if (state.latitude != null && state.longitude != null) ...[
          SizedBox(height: 20),
          _buildInfoRow('Latitude', state.latitude!.toStringAsFixed(6)),
          _buildInfoRow('Longitude', state.longitude!.toStringAsFixed(6)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPIP() {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder for camera feed - in production this would be actual camera
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Icon(
                  Icons.videocam,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
            // Recording indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'REC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFullScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder for camera feed - in production this would be actual camera
          Container(
            color: Colors.grey[900],
            child: Center(
              child: Icon(
                Icons.videocam,
                color: Colors.white24,
                size: 120,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardOverlay(PreviewState state) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSeverityColor(state.severity).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getIconForEmoji(state.icon),
                size: 32,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.hazardType.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${state.distance.toInt()}m ahead',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Severity: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              ...List.generate(10, (index) {
                final isActive = index < state.severity;
                return Container(
                  width: 20,
                  height: 6,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _getSeverityColor(state.severity)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
              SizedBox(width: 8),
              Text(
                '${state.severity}/10',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(int severity) {
    if (severity >= 8) {
      return Colors.red[700]!; // High severity
    } else if (severity >= 5) {
      return Colors.orange[700]!; // Medium severity
    } else if (severity >= 3) {
      return Colors.yellow[700]!; // Low severity
    } else {
      return Colors.green[700]!; // Very low or all clear
    }
  }

  Color _getSeverityColor(int severity) {
    if (severity >= 8) {
      return Colors.red;
    } else if (severity >= 5) {
      return Colors.orange;
    } else if (severity >= 3) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  IconData _getIconForEmoji(String emoji) {
    // Map emoji strings to Flutter icons
    switch (emoji) {
      case '⚠️':
      case '⚠':
        return Icons.warning;
      case '🌊':
        return Icons.waves;
      case '🚨':
        return Icons.emergency;
      case '✅':
      case '✓':
        return Icons.check_circle;
      case '🚧':
        return Icons.construction;
      case '⛔':
        return Icons.block;
      case '🛑':
        return Icons.stop;
      case '❌':
        return Icons.cancel;
      case '⭕':
        return Icons.circle_outlined;
      default:
        return Icons.warning; // Default fallback
    }
  }
}
