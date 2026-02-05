import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoTrimSegment {
  final Duration start;
  final Duration end;
  final String name;

  VideoTrimSegment({
    required this.start,
    required this.end,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start.inMilliseconds,
      'end': end.inMilliseconds,
      'name': name,
    };
  }

  factory VideoTrimSegment.fromJson(Map<String, dynamic> json) {
    return VideoTrimSegment(
      start: Duration(milliseconds: json['start']),
      end: Duration(milliseconds: json['end']),
      name: json['name'],
    );
  }
}

class VideoTrimProgress {
  final double progress;
  final String? currentOperation;
  final Duration? estimatedTimeRemaining;

  VideoTrimProgress({
    required this.progress,
    this.currentOperation,
    this.estimatedTimeRemaining,
  });
}

class VideoTrimmingService {
  static const MethodChannel _channel = MethodChannel(
    'next_player/video_trimming',
  );
  static StreamController<VideoTrimProgress>? _progressController;
  static bool _isInitialized = false;

  static Stream<VideoTrimProgress> get trimProgressStream =>
      _progressController?.stream ?? Stream.empty();

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result ?? false;

      if (_isInitialized) {
        _initializeProgressStream();
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing video trimming service: $e');
      return false;
    }
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking trimming support: $e');
      return false;
    }
  }

  static Future<Duration?> getVideoDuration(String videoPath) async {
    try {
      final result = await _channel.invokeMethod('getVideoDuration', {
        'videoPath': videoPath,
      });

      if (result != null) {
        return Duration(milliseconds: result);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      return null;
    }
  }

  static Future<String?> generateThumbnail({
    required String videoPath,
    required Duration position,
    required String outputPath,
    int width = 320,
    int height = 240,
  }) async {
    try {
      final result = await _channel.invokeMethod('generateThumbnail', {
        'videoPath': videoPath,
        'position': position.inMilliseconds,
        'outputPath': outputPath,
        'width': width,
        'height': height,
      });

      return result;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  static Future<List<String>> generateThumbnails({
    required String videoPath,
    required Duration start,
    required Duration end,
    required int count,
    required String outputDir,
    int width = 320,
    int height = 240,
  }) async {
    try {
      final result = await _channel.invokeMethod('generateThumbnails', {
        'videoPath': videoPath,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'count': count,
        'outputDir': outputDir,
        'width': width,
        'height': height,
      });

      if (result != null) {
        return List<String>.from(result);
      }
      return [];
    } catch (e) {
      debugPrint('Error generating thumbnails: $e');
      return [];
    }
  }

  static Future<String?> trimVideo({
    required String inputPath,
    required Duration start,
    required Duration end,
    required String outputPath,
    String? format,
    int? quality,
    int? bitrate,
    bool maintainAspectRatio = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'outputPath': outputPath,
        'maintainAspectRatio': maintainAspectRatio,
      };

      if (format != null) params['format'] = format;
      if (quality != null) params['quality'] = quality;
      if (bitrate != null) params['bitrate'] = bitrate;

      final result = await _channel.invokeMethod('trimVideo', params);
      return result;
    } catch (e) {
      debugPrint('Error trimming video: $e');
      return null;
    }
  }

  static Future<String?> mergeVideos({
    required List<String> inputPaths,
    required String outputPath,
    String? format,
    int? quality,
    int? bitrate,
    bool maintainAspectRatio = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'maintainAspectRatio': maintainAspectRatio,
      };

      if (format != null) params['format'] = format;
      if (quality != null) params['quality'] = quality;
      if (bitrate != null) params['bitrate'] = bitrate;

      final result = await _channel.invokeMethod('mergeVideos', params);
      return result;
    } catch (e) {
      debugPrint('Error merging videos: $e');
      return null;
    }
  }

  static Future<String?> extractAudio({
    required String videoPath,
    required String outputPath,
    String? format,
    int? bitrate,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'outputPath': outputPath,
      };

      if (format != null) params['format'] = format;
      if (bitrate != null) params['bitrate'] = bitrate;

      final result = await _channel.invokeMethod('extractAudio', params);
      return result;
    } catch (e) {
      debugPrint('Error extracting audio: $e');
      return null;
    }
  }

  static Future<String?> addWatermark({
    required String inputPath,
    required String watermarkPath,
    required String outputPath,
    String position = 'bottom-right',
    double opacity = 0.5,
    int? width,
    int? height,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'watermarkPath': watermarkPath,
        'outputPath': outputPath,
        'position': position,
        'opacity': opacity,
      };

      if (width != null) params['width'] = width;
      if (height != null) params['height'] = height;

      final result = await _channel.invokeMethod('addWatermark', params);
      return result;
    } catch (e) {
      debugPrint('Error adding watermark: $e');
      return null;
    }
  }

  static Future<String?> changeSpeed({
    required String inputPath,
    required String outputPath,
    required double speed,
    bool maintainPitch = false,
  }) async {
    try {
      final result = await _channel.invokeMethod('changeSpeed', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'speed': speed,
        'maintainPitch': maintainPitch,
      });

      return result;
    } catch (e) {
      debugPrint('Error changing video speed: $e');
      return null;
    }
  }

  static Future<String?> reverseVideo({
    required String inputPath,
    required String outputPath,
  }) async {
    try {
      final result = await _channel.invokeMethod('reverseVideo', {
        'inputPath': inputPath,
        'outputPath': outputPath,
      });

      return result;
    } catch (e) {
      debugPrint('Error reversing video: $e');
      return null;
    }
  }

  static Future<String?> rotateVideo({
    required String inputPath,
    required String outputPath,
    required int degrees, // 90, 180, 270
  }) async {
    try {
      final result = await _channel.invokeMethod('rotateVideo', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'degrees': degrees,
      });

      return result;
    } catch (e) {
      debugPrint('Error rotating video: $e');
      return null;
    }
  }

  static Future<String?> cropVideo({
    required String inputPath,
    required String outputPath,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod('cropVideo', {
        'inputPath': inputPath,
        'outputPath': outputPath,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      });

      return result;
    } catch (e) {
      debugPrint('Error cropping video: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getVideoInfo(String videoPath) async {
    try {
      final result = await _channel.invokeMethod('getVideoInfo', {
        'videoPath': videoPath,
      });

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting video info: $e');
      return null;
    }
  }

  static Future<String> getOutputPath({
    String? fileName,
    String? extension,
    String? subdirectory,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      String outputPath = directory.path;

      if (subdirectory != null) {
        outputPath = path.join(outputPath, subdirectory);
        await Directory(outputPath).create(recursive: true);
      }

      if (fileName != null) {
        outputPath = path.join(outputPath, fileName);
      }

      if (extension != null && !outputPath.endsWith(extension)) {
        outputPath = '$outputPath.$extension';
      }

      return outputPath;
    } catch (e) {
      debugPrint('Error getting output path: $e');
      rethrow;
    }
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  static void _initializeProgressStream() {
    _progressController?.close();
    _progressController = StreamController<VideoTrimProgress>.broadcast();

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTrimProgress':
          final progress = (call.arguments['progress'] ?? 0.0).toDouble();
          final operation = call.arguments['operation'] as String?;
          final estimatedTime = call.arguments['estimatedTime'] != null
              ? Duration(milliseconds: call.arguments['estimatedTime'])
              : null;

          _progressController?.add(
            VideoTrimProgress(
              progress: progress,
              currentOperation: operation,
              estimatedTimeRemaining: estimatedTime,
            ),
          );
          break;
        case 'onTrimComplete':
          _progressController?.add(
            VideoTrimProgress(
              progress: 1.0,
              currentOperation: 'Complete',
              estimatedTimeRemaining: Duration.zero,
            ),
          );
          break;
        case 'onTrimError':
          _progressController?.add(
            VideoTrimProgress(
              progress: -1.0,
              currentOperation:
                  'Error: ${call.arguments['error'] ?? 'Unknown error'}',
            ),
          );
          break;
      }
    });
  }

  static Future<void> dispose() async {
    _progressController?.close();
    _progressController = null;
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;

  // Utility methods for common operations
  static Future<String?> createGif({
    required String videoPath,
    required Duration start,
    required Duration end,
    required String outputPath,
    int width = 320,
    int height = 240,
    int fps = 10,
  }) async {
    try {
      final result = await _channel.invokeMethod('createGif', {
        'videoPath': videoPath,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'outputPath': outputPath,
        'width': width,
        'height': height,
        'fps': fps,
      });

      return result;
    } catch (e) {
      debugPrint('Error creating GIF: $e');
      return null;
    }
  }

  static Future<String?> addSubtitles({
    required String inputPath,
    required String subtitlePath,
    required String outputPath,
    String? subtitleStyle,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'subtitlePath': subtitlePath,
        'outputPath': outputPath,
      };

      if (subtitleStyle != null) params['subtitleStyle'] = subtitleStyle;

      final result = await _channel.invokeMethod('addSubtitles', params);
      return result;
    } catch (e) {
      debugPrint('Error adding subtitles: $e');
      return null;
    }
  }
}
