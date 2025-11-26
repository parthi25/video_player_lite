import 'dart:io';

class VideoModel {
  final File file;
  final String name;
  final String path;
  final int size;
  final Duration duration;
  final int? width;
  final int? height;
  final DateTime lastModified;
  bool isFavorite;

  VideoModel({
    required this.file,
    required this.name,
    required this.path,
    required this.size,
    required this.duration,
    this.width,
    this.height,
    required this.lastModified,
    this.isFavorite = false,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String get resolution =>
      width != null && height != null ? '${width}x$height' : 'Unknown';

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'size': size,
    'duration': duration.inMilliseconds,
    'width': width,
    'height': height,
    'lastModified': lastModified.millisecondsSinceEpoch,
    'isFavorite': isFavorite,
  };

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
    file: File(json['path']),
    name: json['name'] ?? json['path'].split('/').last,
    path: json['path'],
    size: json['size'] ?? 0,
    duration: Duration(milliseconds: json['duration'] ?? 0),
    width: json['width'],
    height: json['height'],
    lastModified: json['lastModified'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'])
        : DateTime.now(),
    isFavorite: json['isFavorite'] ?? false,
  );
}
