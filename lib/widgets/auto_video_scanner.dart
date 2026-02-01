import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/file_browser_service.dart';
import 'video_file_item.dart';

class VideoScanner {
  static List<String> videoExtensions = [
    'mp4',
    'avi',
    'mov',
    'mkv',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
    'mpg',
    'mpeg',
    'ts',
    'mts',
    'vob',
    'f4v',
    'asf',
    'rm',
    'rmvb',
  ];

  static Future<List<VideoFile>> scanAllVideos() async {
    final List<VideoFile> allVideos = [];

    try {
      // Check storage permissions first
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        debugPrint('Storage permission denied');
        return [];
      }

      // Get available storage directories dynamically
      final directories = await _getAvailableDirectories();

      debugPrint('Scanning ${directories.length} directories for videos');

      // Scan each directory
      for (final dirPath in directories) {
        try {
          debugPrint('Scanning directory: $dirPath');
          final videos = await _scanDirectory(dirPath);
          debugPrint('Found ${videos.length} videos in $dirPath');
          allVideos.addAll(videos);
        } catch (e) {
          debugPrint('Error scanning $dirPath: $e');
        }
      }

      // Remove duplicates and sort
      final uniqueVideos = <String, VideoFile>{};
      for (final video in allVideos) {
        uniqueVideos[video.path] = video;
      }

      final sortedVideos = uniqueVideos.values.toList();
      sortedVideos.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      debugPrint('Total unique videos found: ${sortedVideos.length}');
      return sortedVideos;
    } catch (e) {
      debugPrint('Error scanning videos: $e');
      return [];
    }
  }

  static Future<List<String>> _getAvailableDirectories() async {
    final List<String> directories = [];

    try {
      // Get external storage directories
      final externalStorage = await getExternalStorageDirectories();
      if (externalStorage != null) {
        directories.addAll(externalStorage);
      }

      // Add common Android paths if they exist
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
      ];

      for (final path in commonPaths) {
        if (await Directory(path).exists()) {
          directories.add(path);
        }
      }

      // Add app-specific directories
      final appDir = Directory('/storage/emulated/0/Android/data');
      if (await appDir.exists()) {
        directories.add(appDir.path);
      }

      return directories.toSet().toList(); // Remove duplicates
    } catch (e) {
      debugPrint('Error getting directories: $e');
      return ['/storage/emulated/0']; // Fallback to root
    }
  }

  static Future<List<String>?> getExternalStorageDirectories() async {
    try {
      final List<String> directories = [];

      // Check different storage paths
      final paths = [
        '/storage/emulated/0',
        '/sdcard',
        '/storage/sdcard0',
        '/storage/sdcard1',
      ];

      for (final path in paths) {
        if (await Directory(path).exists()) {
          directories.add(path);
        }
      }

      return directories.isNotEmpty ? directories : null;
    } catch (e) {
      debugPrint('Error getting external storage: $e');
      return null;
    }
  }

  static Future<List<VideoFile>> _scanDirectory(String directoryPath) async {
    final videos = <VideoFile>[];

    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: $directoryPath');
        return videos;
      }

      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        try {
          if (entity is File) {
            final fileName = entity.path.toLowerCase();
            final extension = entity.path.split('.').last.toLowerCase();

            // Check if it's a video file
            if (videoExtensions.contains(extension) ||
                fileName.contains('video') ||
                fileName.contains('movie')) {
              // Check file size (skip very small files that might be thumbnails)
              final stat = await entity.stat();
              if (stat.size > 1024 * 1024) {
                // Skip files smaller than 1MB
                videos.add(
                  VideoFile(
                    path: entity.path,
                    name: entity.path.split('/').last,
                    size: stat.size,
                    lastModified: stat.modified,
                  ),
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing file ${entity.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $directoryPath: $e');
    }

    return videos;
  }
}

class AutoVideoScannerWidget extends ConsumerStatefulWidget {
  const AutoVideoScannerWidget({super.key});

  @override
  ConsumerState<AutoVideoScannerWidget> createState() =>
      _AutoVideoScannerWidgetState();
}

class _AutoVideoScannerWidgetState
    extends ConsumerState<AutoVideoScannerWidget> {
  List<VideoFile> videos = [];
  bool isScanning = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _scanVideos();
  }

  Future<void> _scanVideos() async {
    setState(() {
      isScanning = true;
      error = null;
    });

    try {
      final scannedVideos = await VideoScanner.scanAllVideos();
      setState(() {
        videos = scannedVideos;
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isScanning = false;
      });
    }
  }

  void _selectVideo(VideoFile video) {
    Navigator.of(context).pop(video.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'All Videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                IconButton(
                  onPressed: isScanning ? null : _scanVideos,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Scanning for videos...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error scanning videos',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanVideos,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Try scanning again or check your storage',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Video count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${videos.length} videos found',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Tap to play',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        // Video list
        Expanded(
          child: ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoFileItem(
                videoFile: video,
                onTap: () => _selectVideo(video),
              );
            },
          ),
        ),
      ],
    );
  }
}
