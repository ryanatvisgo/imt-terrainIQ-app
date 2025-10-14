import 'dart:io';
import 'package:intl/intl.dart';

enum UploadStatus {
  notUploaded,
  uploading,
  uploaded,
  failed,
}

class VideoRecording {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int fileSizeBytes;
  final Duration? duration;
  final UploadStatus uploadStatus;
  final String? serverUrl;
  final bool existsLocally;

  VideoRecording({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.fileSizeBytes,
    this.duration,
    this.uploadStatus = UploadStatus.notUploaded,
    this.serverUrl,
    this.existsLocally = true,
  });

  factory VideoRecording.fromFile(File file) {
    final stat = file.statSync();
    return VideoRecording(
      filePath: file.path,
      fileName: file.path.split('/').last,
      createdAt: stat.modified,
      fileSizeBytes: stat.size,
      existsLocally: true,
    );
  }

  factory VideoRecording.fromJson(Map<String, dynamic> json) {
    return VideoRecording(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      uploadStatus: UploadStatus.values.firstWhere(
        (e) => e.toString() == json['uploadStatus'],
        orElse: () => UploadStatus.notUploaded,
      ),
      serverUrl: json['serverUrl'] as String?,
      existsLocally: json['existsLocally'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'createdAt': createdAt.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
      'duration': duration?.inMilliseconds,
      'uploadStatus': uploadStatus.toString(),
      'serverUrl': serverUrl,
      'existsLocally': existsLocally,
    };
  }

  VideoRecording copyWith({
    String? filePath,
    String? fileName,
    DateTime? createdAt,
    int? fileSizeBytes,
    Duration? duration,
    UploadStatus? uploadStatus,
    String? serverUrl,
    bool? existsLocally,
  }) {
    return VideoRecording(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      duration: duration ?? this.duration,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      serverUrl: serverUrl ?? this.serverUrl,
      existsLocally: existsLocally ?? this.existsLocally,
    );
  }

  bool get isUploaded => uploadStatus == UploadStatus.uploaded;
  bool get isOnlyOnServer => isUploaded && !existsLocally;
  bool get canDelete => existsLocally || isUploaded;

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(createdAt);
  }

  String get formattedTime {
    return DateFormat('HH:mm:ss').format(createdAt);
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get formattedDuration {
    if (duration == null) return 'Unknown';
    
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    final seconds = duration!.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoRecording && other.filePath == filePath;
  }

  @override
  int get hashCode => filePath.hashCode;
}
