import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class SubtitleEntry {
  final Duration start;
  final Duration end;
  final String text;

  SubtitleEntry({required this.start, required this.end, required this.text});

  factory SubtitleEntry.fromJson(Map<String, dynamic> json) {
    return SubtitleEntry(
      start: Duration(milliseconds: json['start']),
      end: Duration(milliseconds: json['end']),
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.inMilliseconds,
      'end': end.inMilliseconds,
      'text': text,
    };
  }
}

class SubtitleParser {
  static Future<List<SubtitleEntry>> parseSRT(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      final content = await file.readAsString(encoding: utf8);
      final entries = <SubtitleEntry>[];

      final lines = content.split('\n');
      int i = 0;

      while (i < lines.length) {
        // Skip empty lines
        if (lines[i].trim().isEmpty) {
          i++;
          continue;
        }

        // Parse subtitle number
        final number = int.tryParse(lines[i].trim());
        if (number == null) {
          i++;
          continue;
        }
        i++;

        // Parse time range
        if (i >= lines.length) break;
        final timeLine = lines[i].trim();
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})',
        ).firstMatch(timeLine);

        if (timeMatch == null) {
          i++;
          continue;
        }

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

        i++;

        // Parse subtitle text
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }

        if (textLines.isNotEmpty) {
          entries.add(
            SubtitleEntry(start: start, end: end, text: textLines.join('\n')),
          );
        }
      }

      return entries;
    } catch (e) {
      debugPrint('Error parsing SRT file: $e');
      return [];
    }
  }

  static Future<List<SubtitleEntry>> parseVTT(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return [];

      final content = await file.readAsString(encoding: utf8);
      final entries = <SubtitleEntry>[];

      final lines = content.split('\n');
      int i = 0;

      // Skip WEBVTT header
      while (i < lines.length && !lines[i].contains('-->')) {
        i++;
      }

      while (i < lines.length) {
        // Skip empty lines
        if (lines[i].trim().isEmpty) {
          i++;
          continue;
        }

        // Parse time range
        final timeLine = lines[i].trim();
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2}):(\d{2})\.(\d{3}) --> (\d{2}):(\d{2}):(\d{2})\.(\d{3})',
        ).firstMatch(timeLine);

        if (timeMatch == null) {
          i++;
          continue;
        }

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

        i++;

        // Parse subtitle text
        final textLines = <String>[];
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }

        if (textLines.isNotEmpty) {
          entries.add(
            SubtitleEntry(start: start, end: end, text: textLines.join('\n')),
          );
        }
      }

      return entries;
    } catch (e) {
      debugPrint('Error parsing VTT file: $e');
      return [];
    }
  }

  static Future<List<SubtitleEntry>> parseSubtitleFile(String filePath) async {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.srt':
        return parseSRT(filePath);
      case '.vtt':
        return parseVTT(filePath);
      default:
        debugPrint('Unsupported subtitle format: $extension');
        return [];
    }
  }
}

class SubtitleDisplayWidget extends StatefulWidget {
  final Duration currentPosition;
  final List<SubtitleEntry> subtitles;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final Alignment alignment;

  const SubtitleDisplayWidget({
    super.key,
    required this.currentPosition,
    required this.subtitles,
    this.textStyle,
    this.padding,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<SubtitleDisplayWidget> createState() => _SubtitleDisplayWidgetState();
}

class _SubtitleDisplayWidgetState extends State<SubtitleDisplayWidget> {
  String _currentSubtitle = '';
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _updateSubtitle();
  }

  @override
  void didUpdateWidget(SubtitleDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition ||
        oldWidget.subtitles != widget.subtitles) {
      _updateSubtitle();
    }
  }

  void _updateSubtitle() {
    String newSubtitle = '';

    for (final entry in widget.subtitles) {
      if (widget.currentPosition >= entry.start &&
          widget.currentPosition <= entry.end) {
        newSubtitle = entry.text;
        break;
      }
    }

    if (newSubtitle != _currentSubtitle) {
      setState(() {
        _currentSubtitle = newSubtitle;
        _isVisible = newSubtitle.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || _currentSubtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80, // Above controls
      left: 0,
      right: 0,
      child: Container(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentSubtitle,
            style:
                widget.textStyle ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black,
                    ),
                  ],
                ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
