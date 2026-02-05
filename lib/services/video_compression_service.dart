import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum VideoQuality { ultraLow, low, medium, high, ultraHigh, original }

enum VideoFormat { mp4, avi, mkv, mov, webm, flv }

class CompressionSettings {
  final VideoQuality quality;
  final VideoFormat format;
  final int? bitrate;
  final int? width;
  final int? height;
  final int? frameRate;
  final bool maintainAspectRatio;
  final bool removeAudio;
  final int? audioBitrate;
  final int? audioSampleRate;

  CompressionSettings({
    required this.quality,
    required this.format,
    this.bitrate,
    this.width,
    this.height,
    this.frameRate,
    this.maintainAspectRatio = true,
    this.removeAudio = false,
    this.audioBitrate,
    this.audioSampleRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'quality': quality.index,
      'format': format.name,
      'bitrate': bitrate,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'maintainAspectRatio': maintainAspectRatio,
      'removeAudio': removeAudio,
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
    };
  }

  factory CompressionSettings.fromJson(Map<String, dynamic> json) {
    return CompressionSettings(
      quality: VideoQuality.values[json['quality']],
      format: VideoFormat.values.firstWhere((f) => f.name == json['format']),
      bitrate: json['bitrate'],
      width: json['width'],
      height: json['height'],
      frameRate: json['frameRate'],
      maintainAspectRatio: json['maintainAspectRatio'] ?? true,
      removeAudio: json['removeAudio'] ?? false,
      audioBitrate: json['audioBitrate'],
      audioSampleRate: json['audioSampleRate'],
    );
  }

  static CompressionSettings get presetUltraLow => CompressionSettings(
    quality: VideoQuality.ultraLow,
    format: VideoFormat.mp4,
    bitrate: 500000, // 500 kbps
    frameRate: 15,
    audioBitrate: 64000, // 64 kbps
  );

  static CompressionSettings get presetLow => CompressionSettings(
    quality: VideoQuality.low,
    format: VideoFormat.mp4,
    bitrate: 1000000, // 1 Mbps
    frameRate: 24,
    audioBitrate: 96000, // 96 kbps
  );

  static CompressionSettings get presetMedium => CompressionSettings(
    quality: VideoQuality.medium,
    format: VideoFormat.mp4,
    bitrate: 2000000, // 2 Mbps
    frameRate: 30,
    audioBitrate: 128000, // 128 kbps
  );

  static CompressionSettings get presetHigh => CompressionSettings(
    quality: VideoQuality.high,
    format: VideoFormat.mp4,
    bitrate: 5000000, // 5 Mbps
    frameRate: 30,
    audioBitrate: 192000, // 192 kbps
  );

  static CompressionSettings get presetUltraHigh => CompressionSettings(
    quality: VideoQuality.ultraHigh,
    format: VideoFormat.mp4,
    bitrate: 10000000, // 10 Mbps
    frameRate: 60,
    audioBitrate: 320000, // 320 kbps
  );
}

class CompressionProgress {
  final double progress;
  final String? currentOperation;
  final Duration? estimatedTimeRemaining;
  final int? processedFrames;
  final int? totalFrames;
  final double? currentFps;
  final double? currentBitrate;

  CompressionProgress({
    required this.progress,
    this.currentOperation,
    this.estimatedTimeRemaining,
    this.processedFrames,
    this.totalFrames,
    this.currentFps,
    this.currentBitrate,
  });
}

class VideoCompressionService {
  static const MethodChannel _channel = MethodChannel(
    'next_player/video_compression',
  );
  static StreamController<CompressionProgress>? _progressController;
  static bool _isInitialized = false;
  static bool _isCompressing = false;

  static Stream<CompressionProgress> get compressionProgressStream =>
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
      debugPrint('Error initializing video compression service: $e');
      return false;
    }
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking compression support: $e');
      return false;
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

  static Future<String?> compressVideo({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
    Function(CompressionProgress)? onProgress,
  }) async {
    try {
      if (_isCompressing) {
        debugPrint('Compression already in progress');
        return null;
      }

      _isCompressing = true;
      _notifyProgress(
        CompressionProgress(
          progress: 0.0,
          currentOperation: 'Starting compression...',
        ),
      );

      final params = <String, dynamic>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'settings': settings.toJson(),
      };

      final result = await _channel.invokeMethod('compressVideo', params);

      _isCompressing = false;

      if (result != null) {
        _notifyProgress(
          CompressionProgress(
            progress: 1.0,
            currentOperation: 'Compression complete',
          ),
        );
        return result;
      } else {
        _notifyProgress(
          CompressionProgress(
            progress: -1.0,
            currentOperation: 'Compression failed',
          ),
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error compressing video: $e');
      _isCompressing = false;
      _notifyProgress(
        CompressionProgress(progress: -1.0, currentOperation: 'Error: $e'),
      );
      return null;
    }
  }

  static Future<String?> compressVideoWithPreset({
    required String inputPath,
    required String outputPath,
    required VideoQuality quality,
    VideoFormat format = VideoFormat.mp4,
    Function(CompressionProgress)? onProgress,
  }) async {
    CompressionSettings settings;

    switch (quality) {
      case VideoQuality.ultraLow:
        settings = CompressionSettings.presetUltraLow;
        break;
      case VideoQuality.low:
        settings = CompressionSettings.presetLow;
        break;
      case VideoQuality.medium:
        settings = CompressionSettings.presetMedium;
        break;
      case VideoQuality.high:
        settings = CompressionSettings.presetHigh;
        break;
      case VideoQuality.ultraHigh:
        settings = CompressionSettings.presetUltraHigh;
        break;
      case VideoQuality.original:
        // Get original video info and use similar settings
        final videoInfo = await getVideoInfo(inputPath);
        if (videoInfo != null) {
          settings = CompressionSettings(
            quality: quality,
            format: format,
            bitrate: videoInfo['bitrate'],
            width: videoInfo['width'],
            height: videoInfo['height'],
            frameRate: videoInfo['frameRate'],
            audioBitrate: videoInfo['audioBitrate'],
            audioSampleRate: videoInfo['audioSampleRate'],
          );
        } else {
          settings = CompressionSettings.presetMedium;
        }
        break;
    }

    settings = CompressionSettings(
      quality: settings.quality,
      format: format,
      bitrate: settings.bitrate,
      width: settings.width,
      height: settings.height,
      frameRate: settings.frameRate,
      maintainAspectRatio: settings.maintainAspectRatio,
      removeAudio: settings.removeAudio,
      audioBitrate: settings.audioBitrate,
      audioSampleRate: settings.audioSampleRate,
    );

    return await compressVideo(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
      onProgress: onProgress,
    );
  }

  static Future<bool> cancelCompression() async {
    try {
      if (!_isCompressing) return true;

      final result = await _channel.invokeMethod('cancelCompression');
      _isCompressing = false;

      if (result ?? false) {
        _notifyProgress(
          CompressionProgress(
            progress: -1.0,
            currentOperation: 'Compression cancelled',
          ),
        );
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error cancelling compression: $e');
      return false;
    }
  }

  static Future<String?> resizeVideo({
    required String inputPath,
    required String outputPath,
    required int width,
    required int height,
    bool maintainAspectRatio = true,
    VideoFormat format = VideoFormat.mp4,
    int? quality,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'width': width,
        'height': height,
        'maintainAspectRatio': maintainAspectRatio,
        'format': format.name,
      };

      if (quality != null) params['quality'] = quality;

      final result = await _channel.invokeMethod('resizeVideo', params);
      return result;
    } catch (e) {
      debugPrint('Error resizing video: $e');
      return null;
    }
  }

  static Future<String?> convertFormat({
    required String inputPath,
    required String outputPath,
    required VideoFormat format,
    int? quality,
    int? bitrate,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'format': format.name,
      };

      if (quality != null) params['quality'] = quality;
      if (bitrate != null) params['bitrate'] = bitrate;

      final result = await _channel.invokeMethod('convertFormat', params);
      return result;
    } catch (e) {
      debugPrint('Error converting format: $e');
      return null;
    }
  }

  static Future<String?> extractAudio({
    required String inputPath,
    required String outputPath,
    String format = 'mp3',
    int? bitrate,
    int? sampleRate,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'format': format,
      };

      if (bitrate != null) params['bitrate'] = bitrate;
      if (sampleRate != null) params['sampleRate'] = sampleRate;

      final result = await _channel.invokeMethod('extractAudio', params);
      return result;
    } catch (e) {
      debugPrint('Error extracting audio: $e');
      return null;
    }
  }

  static Future<String?> createGif({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
    int width = 320,
    int height = 240,
    int fps = 10,
    int? quality,
  }) async {
    try {
      final params = <String, dynamic>{
        'inputPath': inputPath,
        'outputPath': outputPath,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'width': width,
        'height': height,
        'fps': fps,
      };

      if (quality != null) params['quality'] = quality;

      final result = await _channel.invokeMethod('createGif', params);
      return result;
    } catch (e) {
      debugPrint('Error creating GIF: $e');
      return null;
    }
  }

  static Future<List<String>> getSupportedFormats() async {
    try {
      final result = await _channel.invokeMethod('getSupportedFormats');
      if (result != null) {
        return List<String>.from(result);
      }
      return ['mp4', 'avi', 'mkv', 'mov', 'webm', 'flv'];
    } catch (e) {
      debugPrint('Error getting supported formats: $e');
      return ['mp4', 'avi', 'mkv', 'mov', 'webm', 'flv'];
    }
  }

  static Future<String> getOutputPath({
    String? fileName,
    VideoFormat? format,
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

      if (format != null && !outputPath.endsWith('.${format.name}')) {
        outputPath = '$outputPath.${format.name}';
      }

      return outputPath;
    } catch (e) {
      debugPrint('Error getting output path: $e');
      rethrow;
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

  static Future<double> getCompressionRatio(
    String originalPath,
    String compressedPath,
  ) async {
    try {
      final originalSize = await getFileSize(originalPath);
      final compressedSize = await getFileSize(compressedPath);

      if (originalSize == 0) return 0.0;
      return compressedSize / originalSize;
    } catch (e) {
      debugPrint('Error calculating compression ratio: $e');
      return 0.0;
    }
  }

  static Future<int> getEstimatedOutputSize({
    required String inputPath,
    required CompressionSettings settings,
  }) async {
    try {
      final videoInfo = await getVideoInfo(inputPath);
      if (videoInfo == null) return 0;

      final originalSize = await getFileSize(inputPath);
      final originalBitrate = videoInfo['bitrate'] as int? ?? 0;
      final targetBitrate = settings.bitrate ?? originalBitrate;

      if (originalBitrate == 0) return originalSize;

      final ratio = targetBitrate / originalBitrate;
      return (originalSize * ratio).round();
    } catch (e) {
      debugPrint('Error estimating output size: $e');
      return 0;
    }
  }

  static void _initializeProgressStream() {
    _progressController?.close();
    _progressController = StreamController<CompressionProgress>.broadcast();

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onCompressionProgress':
          final progress = (call.arguments['progress'] ?? 0.0).toDouble();
          final operation = call.arguments['operation'] as String?;
          final estimatedTime = call.arguments['estimatedTime'] != null
              ? Duration(milliseconds: call.arguments['estimatedTime'])
              : null;
          final processedFrames = call.arguments['processedFrames'] as int?;
          final totalFrames = call.arguments['totalFrames'] as int?;
          final currentFps = call.arguments['currentFps']?.toDouble();
          final currentBitrate = call.arguments['currentBitrate']?.toDouble();

          _notifyProgress(
            CompressionProgress(
              progress: progress,
              currentOperation: operation,
              estimatedTimeRemaining: estimatedTime,
              processedFrames: processedFrames,
              totalFrames: totalFrames,
              currentFps: currentFps,
              currentBitrate: currentBitrate,
            ),
          );
          break;
        case 'onCompressionComplete':
          _isCompressing = false;
          _notifyProgress(
            CompressionProgress(progress: 1.0, currentOperation: 'Complete'),
          );
          break;
        case 'onCompressionError':
          _isCompressing = false;
          _notifyProgress(
            CompressionProgress(
              progress: -1.0,
              currentOperation:
                  'Error: ${call.arguments['error'] ?? 'Unknown error'}',
            ),
          );
          break;
      }
    });
  }

  static void _notifyProgress(CompressionProgress progress) {
    _progressController?.add(progress);
  }

  static Future<void> dispose() async {
    if (_isCompressing) {
      await cancelCompression();
    }

    _progressController?.close();
    _progressController = null;
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isCompressing => _isCompressing;

  // Utility methods
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  static String getQualityDisplayName(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.ultraLow:
        return 'Ultra Low (500 kbps)';
      case VideoQuality.low:
        return 'Low (1 Mbps)';
      case VideoQuality.medium:
        return 'Medium (2 Mbps)';
      case VideoQuality.high:
        return 'High (5 Mbps)';
      case VideoQuality.ultraHigh:
        return 'Ultra High (10 Mbps)';
      case VideoQuality.original:
        return 'Original';
    }
  }

  static String getFormatDisplayName(VideoFormat format) {
    return format.name.toUpperCase();
  }
}
