import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'file_browser_service.dart';

class VideoScannerService {
  static const List<String> videoExtensions = [
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

  static const List<String> audioExtensions = [
    'mp3',
    'wav',
    'm4a',
    'ogg',
    'flac',
    'aac',
    'wma',
    'aiff',
    'au',
    'ra',
    'amr',
    'ac3',
    'dts',
    'm4p',
    'm4b',
    'm4r',
    'opus',
    'webm',
    'mp4a',
  ];

  static const String _cacheKey = 'scanned_videos_cache';

  /// Scans for videos in a separate isolate to prevent UI jank
  static Future<List<VideoFile>> scanAllVideos({bool useCache = true}) async {
    if (useCache) {
      final cached = await getCachedVideos();
      if (cached.isNotEmpty) return cached;
    }

    // Check permissions on the main thread
    if (!await _checkPermissions()) {
      debugPrint('Storage permission denied');
      return [];
    }

    // Get directories on the main thread
    final directories = await _getAvailableDirectories();

    // Run scanning in isolate
    final videos = await compute(_scanInIsolate, directories);

    // Save to cache
    await saveVideosToCache(videos);

    return videos;
  }

  static Future<List<VideoFile>> getCachedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => VideoFile.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading cached videos: $e');
      return [];
    }
  }

  static Future<void> saveVideosToCache(List<VideoFile> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(videos.map((v) => v.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving videos to cache: $e');
    }
  }

  static Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      // For Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      // Check for photos/videos specific permissions on Android 13+
      if (await Permission.videos.request().isGranted &&
          await Permission.photos.request().isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      return await Permission.photos.request().isGranted;
    }
    return false;
  }

  static Future<List<String>> _getAvailableDirectories() async {
    final Set<String> directories = {};

    try {
      if (Platform.isAndroid) {
        // Primary external storage
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          // Attempt to go up to root: /storage/emulated/0/Android/data/... -> /storage/emulated/0
          final path = extDir.path;
          final androidIndex = path.indexOf('/Android');
          if (androidIndex != -1) {
            directories.add(path.substring(0, androidIndex));
          } else {
            directories.add(path);
          }
        }

        // Add specific common folders if we can access them
        // Note: On Android 11+, we might not be able to list /storage/emulated/0 directly
        // without MANAGE_EXTERNAL_STORAGE.
        // We add common paths explicitly for better scan targets.

        final root = '/storage/emulated/0';
        directories.add(root);
        directories.add('$root/Download');
        directories.add('$root/DCIM');
        directories.add('$root/Movies');
        directories.add('$root/Pictures');
        directories.add('$root/WhatsApp/Media/WhatsApp Video');
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        directories.add(docsDir.path);
      }
    } catch (e) {
      debugPrint('Error getting directories: $e');
    }

    return directories.toList();
  }

  /// Top-level function for isolate
  static Future<List<VideoFile>> _scanInIsolate(
    List<String> directories,
  ) async {
    final List<VideoFile> allVideos = [];
    final Set<String> processedPaths = {};

    for (final dirPath in directories) {
      try {
        final directory = Directory(dirPath);
        if (!directory.existsSync()) continue;

        // Recursive scan
        // Note: listSync with recursive: true can be slow on huge trees,
        // but since we stand in an isolate, we won't freeze UI.
        // However, we should be careful about memory if there are million files.
        // Using sync iterator is fine in isolate.

        final entities = directory.listSync(
          recursive: true,
          followLinks: false,
        );

        for (final entity in entities) {
          if (entity is File) {
            final path = entity.path;
            final name = path.split(Platform.pathSeparator).last;
            final extension = name.contains('.')
                ? name.split('.').last.toLowerCase()
                : '';

            final allExtensions = videoExtensions; // Only scan for video files
            if (allExtensions.contains(extension)) {
              // Filter small files (thumbnails/ads)
              try {
                final stat = entity.statSync();
                final minSize = 1024 * 1024; // 1MB minimum for video files

                if (stat.size > minSize) {
                  if (!processedPaths.contains(path)) {
                    processedPaths.add(path);
                    allVideos.add(
                      VideoFile(
                        path: path,
                        name: name,
                        size: stat.size,
                        lastModified: stat.modified,
                      ),
                    );
                  }
                }
              } catch (e) {
                // ignore access errors
              }
            }
          }
        }
      } catch (e) {
        // Start next dir
      }
    }

    // Sort by name
    allVideos.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return allVideos;
  }
}
