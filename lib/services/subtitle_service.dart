import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'subtitle_downloader_service.dart';

class SubtitleTrack {
  final String path;
  final String language;
  final String label;
  final String? flag;

  SubtitleTrack({
    required this.path,
    required this.language,
    required this.label,
    this.flag,
  });

  Map<String, dynamic> toJson() {
    return {'path': path, 'language': language, 'label': label, 'flag': flag};
  }

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      path: json['path'],
      language: json['language'],
      label: json['label'],
      flag: json['flag'],
    );
  }
}

class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleEntry({required this.start, required this.end, required this.text});
}

class SubtitleService {
  static List<SubtitleEntry>? _currentSubtitles;
  static SubtitleTrack? _currentTrack;

  static Future<List<SubtitleTrack>> findSubtitleTracks(
    String videoPath,
  ) async {
    final List<SubtitleTrack> tracks = [];

    try {
      final videoFile = File(videoPath);
      final videoDir = videoFile.parent;
      final videoNameWithoutExt = path.basenameWithoutExtension(videoPath);

      // Common subtitle extensions
      final subtitleExtensions = ['.srt', '.vtt', '.ass', '.ssa'];

      // Look for subtitle files with same name as video
      for (final ext in subtitleExtensions) {
        final subtitlePath = path.join(
          videoDir.path,
          '$videoNameWithoutExt$ext',
        );
        final subtitleFile = File(subtitlePath);

        if (await subtitleFile.exists()) {
          tracks.add(
            SubtitleTrack(
              path: subtitlePath,
              language: 'Unknown',
              label: path.basename(subtitlePath),
            ),
          );
        }
      }

      // Look for subtitle files in subdirectories (like "Subtitles" folder)
      final subtitleDirs = ['Subtitles', 'subs', 'sub'];
      for (final dirName in subtitleDirs) {
        final subtitleDir = Directory(path.join(videoDir.path, dirName));
        if (await subtitleDir.exists()) {
          await for (final entity in subtitleDir.list()) {
            if (entity is File) {
              final ext = path.extension(entity.path).toLowerCase();
              if (subtitleExtensions.contains(ext)) {
                final fileName = path.basenameWithoutExtension(entity.path);
                if (fileName.toLowerCase().contains(
                  videoNameWithoutExt.toLowerCase(),
                )) {
                  tracks.add(
                    SubtitleTrack(
                      path: entity.path,
                      language: 'Unknown',
                      label: path.basename(entity.path),
                    ),
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding subtitle tracks: $e');
    }

    return tracks;
  }

  static Future<List<SubtitleEntry>?> parseSubtitleFile(
    String subtitlePath,
  ) async {
    try {
      final file = File(subtitlePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final ext = path.extension(subtitlePath).toLowerCase();

      List<SubtitleEntry> entries = [];

      if (ext == '.srt') {
        entries = _parseSRT(content);
      } else if (ext == '.vtt') {
        entries = _parseVTT(content);
      } else if (ext == '.ass' || ext == '.ssa') {
        entries = _parseASS(content);
      }

      _currentSubtitles = entries;
      return entries;
    } catch (e) {
      debugPrint('Error parsing subtitle file: $e');
      return null;
    }
  }

  static List<SubtitleEntry> _parseSRT(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content
        .split('\n\n')
        .where((block) => block.trim().isNotEmpty);

    for (final block in blocks) {
      final lines = block.split('\n');
      if (lines.length < 3) continue;

      // Parse time line (format: 00:00:00,000 --> 00:00:00,000)
      final timeLine = lines[1];
      final timeMatch = RegExp(
        r'(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})',
      ).firstMatch(timeLine);

      if (timeMatch != null) {
        final start = Duration(
          hours: int.parse(timeMatch.group(1)!),
          minutes: int.parse(timeMatch.group(2)!),
          seconds: int.parse(timeMatch.group(3)!),
          milliseconds: int.parse(timeMatch.group(4)!),
        );

        final end = Duration(
          hours: int.parse(timeMatch.group(5)!),
          minutes: int.parse(timeMatch.group(6)!),
          seconds: int.parse(timeMatch.group(7)!),
          milliseconds: int.parse(timeMatch.group(8)!),
        );

        final text = lines.sublist(2).join('\n').trim();

        entries.add(SubtitleEntry(start: start, end: end, text: text));
      }
    }

    return entries;
  }

  static List<SubtitleEntry> _parseVTT(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content
        .split('\n\n')
        .where((block) => block.trim().isNotEmpty);

    for (final block in blocks) {
      final lines = block.split('\n');
      if (lines.length < 2) continue;

      // Skip WEBVTT header
      if (lines[0].startsWith('WEBVTT')) continue;

      // Parse time line (format: 00:00:00.000 --> 00:00:00.000)
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2}):(\d{2})\.(\d{3}) --> (\d{2}):(\d{2}):(\d{2})\.(\d{3})',
        ).firstMatch(line);

        if (timeMatch != null && i + 1 < lines.length) {
          final start = Duration(
            hours: int.parse(timeMatch.group(1)!),
            minutes: int.parse(timeMatch.group(2)!),
            seconds: int.parse(timeMatch.group(3)!),
            milliseconds: int.parse(timeMatch.group(4)!),
          );

          final end = Duration(
            hours: int.parse(timeMatch.group(5)!),
            minutes: int.parse(timeMatch.group(6)!),
            seconds: int.parse(timeMatch.group(7)!),
            milliseconds: int.parse(timeMatch.group(8)!),
          );

          final text = lines.sublist(i + 1).join('\n').trim();

          entries.add(SubtitleEntry(start: start, end: end, text: text));
          break;
        }
      }
    }

    return entries;
  }

  static List<SubtitleEntry> _parseASS(String content) {
    // Simplified ASS parser - basic implementation
    final entries = <SubtitleEntry>[];
    final lines = content.split('\n');

    bool inEvents = false;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('[Events]')) {
        inEvents = true;
        continue;
      }

      if (trimmedLine.startsWith('[') && !trimmedLine.startsWith('[Events]')) {
        inEvents = false;
        continue;
      }

      if (!inEvents || !trimmedLine.startsWith('Dialogue:')) continue;

      // Parse Dialogue line (simplified)
      final parts = trimmedLine.substring(9).split(',');
      if (parts.length >= 10) {
        final startTime = _parseASSTime(parts[1].trim());
        final endTime = _parseASSTime(parts[2].trim());
        final text = parts.sublist(9).join(',').trim();

        // Remove ASS formatting
        final cleanText = text.replaceAll(RegExp(r'\{[^}]*\}'), '');

        entries.add(
          SubtitleEntry(start: startTime, end: endTime, text: cleanText),
        );
      }
    }

    return entries;
  }

  static Duration _parseASSTime(String timeStr) {
    // Format: H:MM:SS.cc
    final parts = timeStr.split(':');
    if (parts.length != 3) return Duration.zero;

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final secondsParts = parts[2].split('.');
    final seconds = int.parse(secondsParts[0]);
    final centiseconds = secondsParts.length > 1
        ? int.parse(secondsParts[1])
        : 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
  }

  static SubtitleEntry? getCurrentSubtitle(Duration position) {
    if (_currentSubtitles == null) return null;

    for (final entry in _currentSubtitles!) {
      if (position >= entry.start && position <= entry.end) {
        return entry;
      }
    }

    return null;
  }

  static void setCurrentTrack(SubtitleTrack? track) {
    _currentTrack = track;
    if (track != null) {
      parseSubtitleFile(track.path);
    } else {
      _currentSubtitles = null;
    }
  }

  static SubtitleTrack? get currentTrack => _currentTrack;
  static List<SubtitleEntry>? get currentSubtitles => _currentSubtitles;

  static Future<String?> downloadSubtitle(
    String videoPath,
    String language,
  ) async {
    try {
      // Get video file name without extension for better search
      final fileName = path.basenameWithoutExtension(videoPath);

      // Search for subtitles online
      final results = await SubtitleDownloaderService.searchSubtitles(
        query: fileName,
        language: language,
      );

      if (results.isNotEmpty) {
        // Get the best match (highest rated and most downloaded)
        results.sort((a, b) {
          final scoreA = a.rating * a.downloads;
          final scoreB = b.rating * b.downloads;
          return scoreB.compareTo(scoreA);
        });

        final bestMatch = results.first;

        // Download the subtitle
        final downloadedPath =
            await SubtitleDownloaderService.downloadAndSaveSubtitle(
              subtitle: bestMatch,
              outputDirectory: path.dirname(videoPath),
            );

        if (downloadedPath != null) {
          debugPrint('Subtitle downloaded successfully: $downloadedPath');
          return downloadedPath;
        }
      }

      debugPrint('No subtitles found for $videoPath in $language');
      return null;
    } catch (e) {
      debugPrint('Error downloading subtitle: $e');
      return null;
    }
  }

  static Map<String, String> getLanguageCodes() {
    return {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'vi': 'Vietnamese',
    };
  }

  static String? detectLanguage(String filename) {
    final name = path.basenameWithoutExtension(filename).toLowerCase();
    final codes = getLanguageCodes();

    for (final entry in codes.entries) {
      if (name.contains(entry.key) ||
          name.contains(entry.value.toLowerCase())) {
        return entry.key;
      }
    }

    return null;
  }
}
