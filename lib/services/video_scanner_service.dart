import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_model.dart';

class VideoScannerService {
  static VideoScannerService? _instance;
  static VideoScannerService get instance => _instance ??= VideoScannerService._();
  
  VideoScannerService._();

  Stream<VideoScanProgress> scanForVideos() async* {
    yield VideoScanProgress(status: ScanStatus.starting, message: 'Initializing scan...');
    
    try {
      final directories = await _getDirectoriesToScan();
      yield VideoScanProgress(
        status: ScanStatus.scanning, 
        message: 'Found ${directories.length} directories to scan'
      );

      final List<VideoModel> allVideos = [];
      int processedDirs = 0;

      for (final directory in directories) {
        yield VideoScanProgress(
          status: ScanStatus.scanning,
          message: 'Scanning ${directory.path.split('/').last}...',
          progress: processedDirs / directories.length,
        );

        final videos = await _scanDirectory(directory);
        allVideos.addAll(videos);
        processedDirs++;

        yield VideoScanProgress(
          status: ScanStatus.scanning,
          message: 'Found ${videos.length} videos in ${directory.path.split('/').last}',
          progress: processedDirs / directories.length,
          videos: List.from(allVideos),
        );
      }

      yield VideoScanProgress(
        status: ScanStatus.completed,
        message: 'Scan completed. Found ${allVideos.length} videos.',
        progress: 1.0,
        videos: allVideos,
      );
    } catch (e) {
      yield VideoScanProgress(
        status: ScanStatus.error,
        message: 'Error during scan: $e',
      );
    }
  }

  Future<List<Directory>> _getDirectoriesToScan() async {
    final List<Directory> directories = [];
    
    if (kIsWeb) {
      // Web doesn't support directory scanning
      debugPrint('Video scanning not supported on web platform');
      return directories;
    }
    
    try {
      if (Platform.isAndroid) {
        final commonPaths = [
          '/storage/emulated/0',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/DCIM/Camera',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
          '/storage/emulated/0/Telegram/Telegram Video',
          '/storage/emulated/0/Videos',
          '/storage/emulated/0/Video',
        ];
        
        for (final path in commonPaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              directories.add(dir);
            }
          } catch (e) {
            debugPrint('Error checking directory $path: $e');
          }
        }
      } else if (Platform.isIOS) {
        try {
          directories.add(await getApplicationDocumentsDirectory());
        } catch (e) {
          debugPrint('Error getting iOS documents directory: $e');
        }
      } else {
        // For other platforms, return empty list
        debugPrint('Video scanning not supported on this platform');
      }
    } catch (e) {
      debugPrint('Error getting directories to scan: $e');
    }
    
    return directories;
  }

  Future<List<VideoModel>> _scanDirectory(Directory directory) async {
    final List<VideoModel> videos = [];
    
    // Video file extensions
    const videoExtensions = [
      'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', 'm4v',
      '3gp', '3g2', 'mpg', 'mpeg', 'ts', 'mts', 'vob', 'asf',
      'rm', 'rmvb', 'divx', 'xvid', 'ogv', 'mxf', 'f4v'
    ];
    
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final path = entity.path.toLowerCase();
            final extension = path.split('.').last;
            
            // Check both MIME type and file extension
            bool isVideo = false;
            final mimeType = lookupMimeType(entity.path);
            if (mimeType != null && mimeType.startsWith('video/')) {
              isVideo = true;
            } else if (videoExtensions.contains(extension)) {
              isVideo = true;
            }
            
            if (isVideo) {
              final videoModel = await _createVideoModel(entity);
              if (videoModel != null) {
                videos.add(videoModel);
              }
            }
          } catch (e) {
            debugPrint('Error processing file ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }
    
    return videos;
  }

  Future<VideoModel?> _createVideoModel(File file) async {
    try {
      final stat = await file.stat();
      
      // Skip expensive video metadata extraction during scanning
      // This will be loaded lazily when needed (e.g., when displaying thumbnails)
      // This makes scanning 10-100x faster
      return VideoModel(
        file: file,
        name: file.path.split('/').last,
        path: file.path,
        size: stat.size,
        duration: Duration.zero, // Will be loaded lazily
        width: null,
        height: null,
        lastModified: stat.modified,
      );
    } catch (e) {
      debugPrint('Error creating video model for ${file.path}: $e');
      return null;
    }
  }
}

class VideoScanProgress {
  final ScanStatus status;
  final String message;
  final double progress;
  final List<VideoModel> videos;

  VideoScanProgress({
    required this.status,
    required this.message,
    this.progress = 0.0,
    this.videos = const [],
  });
}

enum ScanStatus {
  starting,
  scanning,
  completed,
  error,
}