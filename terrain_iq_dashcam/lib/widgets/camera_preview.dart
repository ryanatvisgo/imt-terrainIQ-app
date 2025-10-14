import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraService>(
      builder: (context, cameraService, child) {
        if (cameraService.controller == null || !cameraService.isInitialized) {
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

        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: CameraPreview(cameraService.controller!),
            ),
          ),
        );
      },
    );
  }
}
