import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';

class RecordingControlsWidget extends StatelessWidget {
  const RecordingControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CameraService, StorageService>(
      builder: (context, cameraService, storageService, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recording indicator
            if (cameraService.isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(width: 20),
            
            // Record/Stop button
            GestureDetector(
              onTap: () => _toggleRecording(cameraService, storageService),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: cameraService.isRecording ? Colors.red : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  cameraService.isRecording ? Icons.stop : Icons.videocam,
                  color: cameraService.isRecording ? Colors.white : Colors.red,
                  size: 32,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Settings button
            GestureDetector(
              onTap: () {
                // TODO: Open settings
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleRecording(CameraService cameraService, StorageService storageService) async {
    try {
      if (cameraService.isRecording) {
        final recordingPath = await cameraService.stopRecording();
        if (recordingPath != null) {
          await storageService.addRecording(recordingPath);
        }
      } else {
        await cameraService.startRecording();
      }
    } catch (e) {
      // Handle error
      debugPrint('Error toggling recording: $e');
    }
  }
}
