import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/permission_service.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../widgets/camera_preview.dart';
import '../widgets/recording_controls.dart';
import '../widgets/recording_list.dart';

class DashcamScreen extends StatefulWidget {
  const DashcamScreen({super.key});

  @override
  State<DashcamScreen> createState() => _DashcamScreenState();
}

class _DashcamScreenState extends State<DashcamScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final permissionService = context.read<PermissionService>();
    final cameraService = context.read<CameraService>();
    final storageService = context.read<StorageService>();

    // Check permissions first
    await permissionService.checkPermissions();
    
    // Initialize storage service
    await storageService.initialize();

    // If permissions are granted, initialize camera
    if (permissionService.allPermissionsGranted) {
      await cameraService.initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TerrainIQ Dashcam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer<PermissionService>(
        builder: (context, permissionService, child) {
          if (!permissionService.allPermissionsGranted) {
            return _buildPermissionsView(permissionService);
          }

          return Consumer<CameraService>(
            builder: (context, cameraService, child) {
              // Initialize camera if permissions are granted but camera isn't initialized
              if (!cameraService.isInitialized) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  cameraService.initializeCamera();
                });
              }

              return IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildCameraView(),
                  _buildRecordingsView(),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
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

  Widget _buildPermissionsView(PermissionService permissionService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Permissions Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This app needs camera, microphone, location, and storage permissions to function as a dashcam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => permissionService.requestAllPermissions(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Grant Permissions',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        if (!cameraService.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          children: [
            CameraPreviewWidget(),
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: RecordingControlsWidget(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordingsView() {
    return const RecordingListWidget();
  }
}

