import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/video_recording.dart';

class RecordingListWidget extends StatelessWidget {
  const RecordingListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storageService, child) {
        if (storageService.recordings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No recordings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start recording to see your videos here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Storage info header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${storageService.recordings.length} recordings',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Max: ${storageService.maxStorageGB}GB',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Recordings list
            Expanded(
              child: ListView.builder(
                itemCount: storageService.recordings.length,
                itemBuilder: (context, index) {
                  final recording = storageService.recordings[index];
                  return RecordingListItem(recording: recording);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecordingListItem extends StatelessWidget {
  final VideoRecording recording;

  const RecordingListItem({
    super.key,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.grey,
          ),
        ),
        title: Text(recording.fileName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${recording.formattedDate} at ${recording.formattedTime}'),
            Text(
              'Size: ${recording.formattedFileSize}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _playVideo(context),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final storageService = context.read<StorageService>();
    
    switch (action) {
      case 'play':
        _playVideo(context);
        break;
      case 'share':
        _shareVideo(context);
        break;
      case 'delete':
        _deleteVideo(context, storageService);
        break;
    }
  }

  void _playVideo(BuildContext context) {
    // TODO: Implement video playback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video playback not implemented yet')),
    );
  }

  void _shareVideo(BuildContext context) {
    // TODO: Implement video sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video sharing not implemented yet')),
    );
  }

  void _deleteVideo(BuildContext context, StorageService storageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete "${recording.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              storageService.deleteRecording(recording);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

