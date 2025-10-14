import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/motion_service.dart';
import '../services/server_service.dart';
import '../services/hazard_service.dart';
import 'driving_mode_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildDrivingModeSection(context),
          const Divider(),
          _buildGeneralSettings(context),
          const Divider(),
          _buildRecordingSettings(context),
          const Divider(),
          _buildAdvancedSettings(context),
        ],
      ),
    );
  }

  Widget _buildDrivingModeSection(BuildContext context) {
    return Consumer<HazardService>(
      builder: (context, hazardService, child) {
        return ExpansionTile(
          title: const Text(
            'Driving Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: const Icon(Icons.navigation, color: Color(0xFF1E88E5)),
          initiallyExpanded: false,
          children: [
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: const Text('Hazard Warning HUD'),
              subtitle: const Text(
                'Full-screen hazard alerts with real-time distance countdown',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DrivingModeScreen(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Color-coded severity alerts (Red/Orange/Blue)'),
                  Text('• Distance countdown to hazards'),
                  Text('• Camera preview for dashcam recording'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hazard Proximity Alert Distance',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${hazardService.proximityThresholdMeters.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Close\n(100m)', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: hazardService.proximityThresholdMeters,
                          min: 100,
                          max: 500,
                          divisions: 8,
                          label: '${hazardService.proximityThresholdMeters.toStringAsFixed(0)}m',
                          onChanged: (value) {
                            hazardService.setProximityThreshold(value);
                          },
                        ),
                      ),
                      const Text('Far\n(500m)', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adjusts when hazard warnings appear (currently within ${hazardService.proximityThresholdMeters.toStringAsFixed(0)}m)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Consumer<ServerService>(
      builder: (context, serverService, child) {
        return ExpansionTile(
          title: const Text(
            'General',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: const Icon(Icons.settings, color: Color(0xFF1E88E5)),
          initiallyExpanded: true,
          children: [
            SwitchListTile(
              title: const Text('WiFi-Only Uploads'),
              subtitle: const Text('Only upload when connected to WiFi'),
              value: serverService.wifiOnlyMode,
              onChanged: (value) {
                serverService.setWifiOnlyMode(value);
              },
              secondary: const Icon(Icons.wifi),
            ),
            SwitchListTile(
              title: const Text('Delete After Upload'),
              subtitle: const Text('Delete local files after successful upload'),
              value: serverService.deleteAfterUpload,
              onChanged: (value) {
                serverService.setDeleteAfterUpload(value);
              },
              secondary: const Icon(Icons.delete),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordingSettings(BuildContext context) {
    return const ExpansionTile(
      title: Text(
        'Recording',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      leading: Icon(Icons.videocam, color: Color(0xFF1E88E5)),
      children: [
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Auto-Record Settings'),
          subtitle: Text('Starts recording after 3 seconds of sustained motion (≥0.4 m/s / ~0.9 mph)'),
        ),
        ListTile(
          leading: Icon(Icons.pause),
          title: Text('Auto-Stop'),
          subtitle: Text('Stops recording after 30 seconds of being stationary'),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings(BuildContext context) {
    return Consumer<MotionService>(
      builder: (context, motionService, child) {
        return ExpansionTile(
          title: const Text(
            'Advanced',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: const Icon(Icons.settings_suggest, color: Color(0xFF1E88E5)),
          children: [
            SwitchListTile(
              title: const Text('Allow Flat Orientation Recording'),
              subtitle: const Text(
                'Enable to record when phone is flat (e.g., camera pointing straight down off vehicle)',
              ),
              value: motionService.ignoreFlatOrientation,
              onChanged: (value) {
                motionService.setIgnoreFlatOrientation(value);
              },
              secondary: const Icon(Icons.phone_android),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motion Detection Thresholds:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Velocity: ≥0.4 m/s (~0.9 mph)'),
                  Text('• Sustained Duration: 3 seconds'),
                  Text('• Idle Timeout: 30 seconds'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
