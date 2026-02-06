import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:media_kit/media_kit.dart';

class ThumbnailService {
  static final Map<String, String> _thumbnailCache = {};
  static Directory? _thumbnailDir;

  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailDir = Directory(path.join(appDir.path, 'thumbnails'));
      if (!await _thumbnailDir!.exists()) {
        await _thumbnailDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error initializing thumbnail service: $e');
    }
  }

  static String _getThumbnailFileName(String videoPath) {
    final bytes = utf8.encode(videoPath);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}.jpg';
  }

  static Future<String?> getThumbnailPath(String videoPath) async {
    if (_thumbnailDir == null) {
      await initialize();
    }

    final fileName = _getThumbnailFileName(videoPath);
    final thumbnailPath = path.join(_thumbnailDir!.path, fileName);

    if (await File(thumbnailPath).exists()) {
      return thumbnailPath;
    }

    return null;
  }

  static Future<String?> generateThumbnail(String videoPath) async {
    try {
      if (_thumbnailDir == null) {
        await initialize();
      }

      final cachedPath = await getThumbnailPath(videoPath);
      if (cachedPath != null) {
        return cachedPath;
      }

      if (!await File(videoPath).exists()) {
        return null;
      }

      final fileName = _getThumbnailFileName(videoPath);
      final thumbnailPath = path.join(_thumbnailDir!.path, fileName);

      final player = Player();
      try {
        await player.open(Media(videoPath), play: false);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        final screenshot = await player.screenshot();
        if (screenshot != null) {
          await File(thumbnailPath).writeAsBytes(screenshot);
          _thumbnailCache[videoPath] = thumbnailPath;
          return thumbnailPath;
        }
      } finally {
        await player.dispose();
      }

      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoPath: $e');
      return null;
    }
  }

  static Future<void> generateThumbnailsBatch(List<String> videoPaths) async {
    for (final videoPath in videoPaths) {
      try {
        await generateThumbnail(videoPath);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Error generating thumbnail for $videoPath: $e');
      }
    }
  }

  static Future<void> clearCache() async {
    try {
      if (_thumbnailDir != null && await _thumbnailDir!.exists()) {
        await _thumbnailDir!.delete(recursive: true);
        await _thumbnailDir!.create(recursive: true);
      }
      _thumbnailCache.clear();
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  static Future<void> deleteThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await getThumbnailPath(videoPath);
      if (thumbnailPath != null) {
        final file = File(thumbnailPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _thumbnailCache.remove(videoPath);
    } catch (e) {
      debugPrint('Error deleting thumbnail: $e');
    }
  }
}
