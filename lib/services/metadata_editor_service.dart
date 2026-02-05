import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoMetadata {
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? year;
  final String? comment;
  final String? copyright;
  final String? description;
  final String? rating;
  final String? language;
  final String? director;
  final String? producer;
  final String? writer;
  final String? actors;
  final String? keywords;
  final Map<String, String>? customTags;
  final String? thumbnailPath;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int? duration;
  final int? fileSize;
  final String? format;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? bitrate;
  final String? codec;
  final String? audioCodec;
  final int? audioBitrate;
  final int? audioSampleRate;
  final int? audioChannels;

  VideoMetadata({
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.comment,
    this.copyright,
    this.description,
    this.rating,
    this.language,
    this.director,
    this.producer,
    this.writer,
    this.actors,
    this.keywords,
    this.customTags,
    this.thumbnailPath,
    this.creationDate,
    this.modificationDate,
    this.duration,
    this.fileSize,
    this.format,
    this.width,
    this.height,
    this.frameRate,
    this.bitrate,
    this.codec,
    this.audioCodec,
    this.audioBitrate,
    this.audioSampleRate,
    this.audioChannels,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'year': year,
      'comment': comment,
      'copyright': copyright,
      'description': description,
      'rating': rating,
      'language': language,
      'director': director,
      'producer': producer,
      'writer': writer,
      'actors': actors,
      'keywords': keywords,
      'customTags': customTags,
      'thumbnailPath': thumbnailPath,
      'creationDate': creationDate?.toIso8601String(),
      'modificationDate': modificationDate?.toIso8601String(),
      'duration': duration,
      'fileSize': fileSize,
      'format': format,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'bitrate': bitrate,
      'codec': codec,
      'audioCodec': audioCodec,
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
    };
  }

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      genre: json['genre'],
      year: json['year'],
      comment: json['comment'],
      copyright: json['copyright'],
      description: json['description'],
      rating: json['rating'],
      language: json['language'],
      director: json['director'],
      producer: json['producer'],
      writer: json['writer'],
      actors: json['actors'],
      keywords: json['keywords'],
      customTags: json['customTags'] != null
          ? Map<String, String>.from(json['customTags'])
          : null,
      thumbnailPath: json['thumbnailPath'],
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'])
          : null,
      modificationDate: json['modificationDate'] != null
          ? DateTime.parse(json['modificationDate'])
          : null,
      duration: json['duration'],
      fileSize: json['fileSize'],
      format: json['format'],
      width: json['width'],
      height: json['height'],
      frameRate: json['frameRate']?.toDouble(),
      bitrate: json['bitrate'],
      codec: json['codec'],
      audioCodec: json['audioCodec'],
      audioBitrate: json['audioBitrate'],
      audioSampleRate: json['audioSampleRate'],
      audioChannels: json['audioChannels'],
    );
  }

  VideoMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? year,
    String? comment,
    String? copyright,
    String? description,
    String? rating,
    String? language,
    String? director,
    String? producer,
    String? writer,
    String? actors,
    String? keywords,
    Map<String, String>? customTags,
    String? thumbnailPath,
    DateTime? creationDate,
    DateTime? modificationDate,
    int? duration,
    int? fileSize,
    String? format,
    int? width,
    int? height,
    double? frameRate,
    int? bitrate,
    String? codec,
    String? audioCodec,
    int? audioBitrate,
    int? audioSampleRate,
    int? audioChannels,
  }) {
    return VideoMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      comment: comment ?? this.comment,
      copyright: copyright ?? this.copyright,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      language: language ?? this.language,
      director: director ?? this.director,
      producer: producer ?? this.producer,
      writer: writer ?? this.writer,
      actors: actors ?? this.actors,
      keywords: keywords ?? this.keywords,
      customTags: customTags ?? this.customTags,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      bitrate: bitrate ?? this.bitrate,
      codec: codec ?? this.codec,
      audioCodec: audioCodec ?? this.audioCodec,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioChannels: audioChannels ?? this.audioChannels,
    );
  }
}

class MetadataEditorService {
  static const MethodChannel _channel = MethodChannel(
    'next_player/metadata_editor',
  );
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing metadata editor service: $e');
      return false;
    }
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking metadata support: $e');
      return false;
    }
  }

  static Future<VideoMetadata?> readMetadata(String videoPath) async {
    try {
      final result = await _channel.invokeMethod('readMetadata', {
        'videoPath': videoPath,
      });

      if (result != null) {
        return VideoMetadata.fromJson(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      debugPrint('Error reading metadata: $e');
      return null;
    }
  }

  static Future<bool> writeMetadata({
    required String videoPath,
    required VideoMetadata metadata,
    String? outputPath,
    bool preserveOriginal = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'metadata': metadata.toJson(),
        'preserveOriginal': preserveOriginal,
      };

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final result = await _channel.invokeMethod('writeMetadata', params);
      return result ?? false;
    } catch (e) {
      debugPrint('Error writing metadata: $e');
      return false;
    }
  }

  static Future<bool> updateMetadata({
    required String videoPath,
    Map<String, String>? basicTags,
    Map<String, String>? customTags,
    String? outputPath,
    bool preserveOriginal = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'preserveOriginal': preserveOriginal,
      };

      if (basicTags != null) {
        params['basicTags'] = basicTags;
      }

      if (customTags != null) {
        params['customTags'] = customTags;
      }

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final result = await _channel.invokeMethod('updateMetadata', params);
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating metadata: $e');
      return false;
    }
  }

  static Future<bool> removeMetadata({
    required String videoPath,
    List<String>? tagsToRemove,
    bool removeAll = false,
    String? outputPath,
    bool preserveOriginal = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'removeAll': removeAll,
        'preserveOriginal': preserveOriginal,
      };

      if (tagsToRemove != null) {
        params['tagsToRemove'] = tagsToRemove;
      }

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final result = await _channel.invokeMethod('removeMetadata', params);
      return result ?? false;
    } catch (e) {
      debugPrint('Error removing metadata: $e');
      return false;
    }
  }

  static Future<String?> extractThumbnail({
    required String videoPath,
    required String outputPath,
    Duration? position,
    int width = 320,
    int height = 240,
    String format = 'jpg',
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'outputPath': outputPath,
        'width': width,
        'height': height,
        'format': format,
      };

      if (position != null) {
        params['position'] = position.inMilliseconds;
      }

      final result = await _channel.invokeMethod('extractThumbnail', params);
      return result;
    } catch (e) {
      debugPrint('Error extracting thumbnail: $e');
      return null;
    }
  }

  static Future<bool> embedThumbnail({
    required String videoPath,
    required String thumbnailPath,
    String? outputPath,
    bool preserveOriginal = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'preserveOriginal': preserveOriginal,
      };

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final result = await _channel.invokeMethod('embedThumbnail', params);
      return result ?? false;
    } catch (e) {
      debugPrint('Error embedding thumbnail: $e');
      return false;
    }
  }

  static Future<bool> removeThumbnail({
    required String videoPath,
    String? outputPath,
    bool preserveOriginal = true,
  }) async {
    try {
      final params = <String, dynamic>{
        'videoPath': videoPath,
        'preserveOriginal': preserveOriginal,
      };

      if (outputPath != null) {
        params['outputPath'] = outputPath;
      }

      final result = await _channel.invokeMethod('removeThumbnail', params);
      return result ?? false;
    } catch (e) {
      debugPrint('Error removing thumbnail: $e');
      return false;
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

  static Future<List<String>> getSupportedTags() async {
    try {
      final result = await _channel.invokeMethod('getSupportedTags');
      if (result != null) {
        return List<String>.from(result);
      }
      return [
        'title',
        'artist',
        'album',
        'genre',
        'year',
        'comment',
        'copyright',
        'description',
        'rating',
        'language',
        'director',
        'producer',
        'writer',
        'actors',
        'keywords',
      ];
    } catch (e) {
      debugPrint('Error getting supported tags: $e');
      return [
        'title',
        'artist',
        'album',
        'genre',
        'year',
        'comment',
        'copyright',
        'description',
        'rating',
        'language',
        'director',
        'producer',
        'writer',
        'actors',
        'keywords',
      ];
    }
  }

  static Future<Map<String, dynamic>?> getTechnicalInfo(
    String videoPath,
  ) async {
    try {
      final result = await _channel.invokeMethod('getTechnicalInfo', {
        'videoPath': videoPath,
      });

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting technical info: $e');
      return null;
    }
  }

  static Future<String?> generateMetadataReport(String videoPath) async {
    try {
      final metadata = await readMetadata(videoPath);
      final technicalInfo = await getTechnicalInfo(videoPath);

      if (metadata == null && technicalInfo == null) return null;

      final report = StringBuffer();
      report.writeln('=== VIDEO METADATA REPORT ===');
      report.writeln('File: $videoPath');
      report.writeln('Generated: ${DateTime.now()}');
      report.writeln('');

      if (metadata != null) {
        report.writeln('--- BASIC METADATA ---');
        report.writeln('Title: ${metadata.title}');
        if (metadata.artist != null) {
          report.writeln('Artist: ${metadata.artist}');
        }
        if (metadata.album != null) {
          report.writeln('Album: ${metadata.album}');
        }
        if (metadata.genre != null) {
          report.writeln('Genre: ${metadata.genre}');
        }
        if (metadata.year != null) {
          report.writeln('Year: ${metadata.year}');
        }
        if (metadata.director != null) {
          report.writeln('Director: ${metadata.director}');
        }
        if (metadata.producer != null) {
          report.writeln('Producer: ${metadata.producer}');
        }
        if (metadata.writer != null) {
          report.writeln('Writer: ${metadata.writer}');
        }
        if (metadata.actors != null) {
          report.writeln('Actors: ${metadata.actors}');
        }
        if (metadata.keywords != null) {
          report.writeln('Keywords: ${metadata.keywords}');
        }
        if (metadata.comment != null) {
          report.writeln('Comment: ${metadata.comment}');
        }
        if (metadata.description != null) {
          report.writeln('Description: ${metadata.description}');
        }
        if (metadata.rating != null) {
          report.writeln('Rating: ${metadata.rating}');
        }
        if (metadata.language != null) {
          report.writeln('Language: ${metadata.language}');
        }
        report.writeln('');
      }

      if (technicalInfo != null) {
        report.writeln('--- TECHNICAL INFO ---');
        if (technicalInfo['format'] != null) {
          report.writeln('Format: ${technicalInfo['format']}');
        }
        if (technicalInfo['duration'] != null) {
          final duration = Duration(milliseconds: technicalInfo['duration']);
          report.writeln('Duration: ${_formatDuration(duration)}');
        }
        if (technicalInfo['fileSize'] != null) {
          report.writeln(
            'File Size: ${_formatFileSize(technicalInfo['fileSize'])}',
          );
        }
        if (technicalInfo['width'] != null && technicalInfo['height'] != null) {
          report.writeln(
            'Resolution: ${technicalInfo['width']}x${technicalInfo['height']}',
          );
        }
        if (technicalInfo['frameRate'] != null) {
          report.writeln('Frame Rate: ${technicalInfo['frameRate']} fps');
        }
        if (technicalInfo['bitrate'] != null) {
          report.writeln('Bitrate: ${technicalInfo['bitrate']} bps');
        }
        if (technicalInfo['codec'] != null) {
          report.writeln('Video Codec: ${technicalInfo['codec']}');
        }
        if (technicalInfo['audioCodec'] != null) {
          report.writeln('Audio Codec: ${technicalInfo['audioCodec']}');
        }
        if (technicalInfo['audioBitrate'] != null) {
          report.writeln('Audio Bitrate: ${technicalInfo['audioBitrate']} bps');
        }
        if (technicalInfo['audioSampleRate'] != null) {
          report.writeln(
            'Audio Sample Rate: ${technicalInfo['audioSampleRate']} Hz',
          );
        }
        if (technicalInfo['audioChannels'] != null) {
          report.writeln('Audio Channels: ${technicalInfo['audioChannels']}');
        }
      }

      return report.toString();
    } catch (e) {
      debugPrint('Error generating metadata report: $e');
      return null;
    }
  }

  static Future<String> saveMetadataReport({
    required String videoPath,
    String? outputPath,
  }) async {
    try {
      final report = await generateMetadataReport(videoPath);
      if (report == null) throw Exception('Failed to generate report');

      Directory directory;
      if (outputPath != null) {
        directory = Directory(outputPath);
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final fileName = path.basenameWithoutExtension(videoPath);
      final reportPath = path.join(
        directory.path,
        '${fileName}_metadata_report.txt',
      );

      final file = File(reportPath);
      await file.writeAsString(report);

      return reportPath;
    } catch (e) {
      debugPrint('Error saving metadata report: $e');
      rethrow;
    }
  }

  static Future<bool> backupMetadata(String videoPath) async {
    try {
      final metadata = await readMetadata(videoPath);
      if (metadata == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basenameWithoutExtension(videoPath);
      final backupPath = path.join(
        directory.path,
        '${fileName}_metadata_backup.json',
      );

      final file = File(backupPath);
      await file.writeAsString(json.encode(metadata.toJson()));

      return true;
    } catch (e) {
      debugPrint('Error backing up metadata: $e');
      return false;
    }
  }

  static Future<VideoMetadata?> restoreMetadata(String videoPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basenameWithoutExtension(videoPath);
      final backupPath = path.join(
        directory.path,
        '${fileName}_metadata_backup.json',
      );

      final file = File(backupPath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final metadataJson = json.decode(content);

      return VideoMetadata.fromJson(metadataJson);
    } catch (e) {
      debugPrint('Error restoring metadata: $e');
      return null;
    }
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static Future<void> dispose() async {
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;

  // Utility methods for batch operations
  static Future<Map<String, bool>> batchUpdateMetadata({
    required List<String> videoPaths,
    required Map<String, String> tagsToUpdate,
    bool preserveOriginal = true,
  }) async {
    final results = <String, bool>{};

    for (final videoPath in videoPaths) {
      try {
        final success = await updateMetadata(
          videoPath: videoPath,
          basicTags: tagsToUpdate,
          preserveOriginal: preserveOriginal,
        );
        results[videoPath] = success;
      } catch (e) {
        debugPrint('Error updating metadata for $videoPath: $e');
        results[videoPath] = false;
      }
    }

    return results;
  }

  static Future<Map<String, VideoMetadata?>> batchReadMetadata(
    List<String> videoPaths,
  ) async {
    final results = <String, VideoMetadata?>{};

    for (final videoPath in videoPaths) {
      try {
        final metadata = await readMetadata(videoPath);
        results[videoPath] = metadata;
      } catch (e) {
        debugPrint('Error reading metadata for $videoPath: $e');
        results[videoPath] = null;
      }
    }

    return results;
  }
}
