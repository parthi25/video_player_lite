import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RecentFilesService {
  static const String _recentVideosKey = 'recent_videos';
  static const String _recentAudioKey = 'recent_audio';
  static const int _maxRecentFiles = 50;
  static RecentFilesService? _instance;
  
  static RecentFilesService get instance => _instance ??= RecentFilesService._();
  
  RecentFilesService._();

  Future<void> addRecentVideo(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = await getRecentVideos();
      recent.remove(path); // Remove if exists
      recent.insert(0, path); // Add to beginning
      
      // Keep only max items
      if (recent.length > _maxRecentFiles) {
        recent.removeRange(_maxRecentFiles, recent.length);
      }
      
      await prefs.setStringList(_recentVideosKey, recent);
    } catch (e) {
      debugPrint('Error adding recent video: $e');
    }
  }

  Future<void> addRecentAudio(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = await getRecentAudio();
      recent.remove(path);
      recent.insert(0, path);
      
      if (recent.length > _maxRecentFiles) {
        recent.removeRange(_maxRecentFiles, recent.length);
      }
      
      await prefs.setStringList(_recentAudioKey, recent);
    } catch (e) {
      debugPrint('Error adding recent audio: $e');
    }
  }

  Future<List<String>> getRecentVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList(_recentVideosKey) ?? [];
      // Filter out files that no longer exist
      final existing = <String>[];
      for (final path in recent) {
        if (File(path).existsSync()) {
          existing.add(path);
        }
      }
      // Update if some files were removed
      if (existing.length != recent.length) {
        await prefs.setStringList(_recentVideosKey, existing);
      }
      return existing;
    } catch (e) {
      debugPrint('Error getting recent videos: $e');
      return [];
    }
  }

  Future<List<String>> getRecentAudio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList(_recentAudioKey) ?? [];
      final existing = <String>[];
      for (final path in recent) {
        if (File(path).existsSync()) {
          existing.add(path);
        }
      }
      if (existing.length != recent.length) {
        await prefs.setStringList(_recentAudioKey, existing);
      }
      return existing;
    } catch (e) {
      debugPrint('Error getting recent audio: $e');
      return [];
    }
  }

  Future<void> clearRecentVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentVideosKey);
    } catch (e) {
      debugPrint('Error clearing recent videos: $e');
    }
  }

  Future<void> clearRecentAudio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentAudioKey);
    } catch (e) {
      debugPrint('Error clearing recent audio: $e');
    }
  }
}

