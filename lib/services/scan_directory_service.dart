import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class ScanDirectoryService {
  static const String _customDirsKey = 'custom_scan_directories';

  // Default scan directories
  static const List<String> _defaultDirectories = [
    '/storage/emulated/0',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/DCIM',
    '/storage/emulated/0/Movies',
    '/storage/emulated/0/Pictures',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
  ];

  /// Get all scan directories (default + custom)
  static Future<List<String>> getAllScanDirectories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDirsJson = prefs.getString(_customDirsKey);

      final List<String> allDirectories = List.from(_defaultDirectories);

      if (customDirsJson != null) {
        final List<dynamic> customDirs = jsonDecode(customDirsJson);
        allDirectories.addAll(customDirs.cast<String>());
      }

      // Remove duplicates while preserving order
      final seen = <String>{};
      return allDirectories.where((dir) => seen.add(dir)).toList();
    } catch (e) {
      debugPrint('Error getting scan directories: $e');
      return List.from(_defaultDirectories);
    }
  }

  /// Get only custom directories
  static Future<List<String>> getCustomDirectories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDirsJson = prefs.getString(_customDirsKey);

      if (customDirsJson != null) {
        final List<dynamic> customDirs = jsonDecode(customDirsJson);
        return customDirs.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting custom directories: $e');
      return [];
    }
  }

  /// Add a custom scan directory
  static Future<bool> addCustomDirectory(String directoryPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDirs = await getCustomDirectories();

      if (!customDirs.contains(directoryPath)) {
        customDirs.add(directoryPath);
        final customDirsJson = jsonEncode(customDirs);
        await prefs.setString(_customDirsKey, customDirsJson);
        debugPrint('Added custom scan directory: $directoryPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding custom directory: $e');
      return false;
    }
  }

  /// Remove a custom scan directory
  static Future<bool> removeCustomDirectory(String directoryPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customDirs = await getCustomDirectories();

      if (customDirs.contains(directoryPath)) {
        customDirs.remove(directoryPath);
        final customDirsJson = jsonEncode(customDirs);
        await prefs.setString(_customDirsKey, customDirsJson);
        debugPrint('Removed custom scan directory: $directoryPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing custom directory: $e');
      return false;
    }
  }

  /// Pick a directory using file picker
  static Future<String?> pickDirectory() async {
    try {
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath(
            dialogTitle: 'Select Scan Directory',
            lockParentWindow: true,
          );
      return selectedDirectory;
    } catch (e) {
      debugPrint('Error picking directory: $e');
      return null;
    }
  }

  /// Check if a directory is a default directory
  static bool isDefaultDirectory(String directoryPath) {
    return _defaultDirectories.contains(directoryPath);
  }

  /// Reset to default directories only
  static Future<bool> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customDirsKey);
      debugPrint('Reset scan directories to defaults');
      return true;
    } catch (e) {
      debugPrint('Error resetting directories: $e');
      return false;
    }
  }

  /// Get directory display name (shorten long paths)
  static String getDisplayName(String directoryPath) {
    if (directoryPath.startsWith('/storage/emulated/0/')) {
      return directoryPath.replaceFirst('/storage/emulated/0/', '');
    }
    if (directoryPath.length > 40) {
      final parts = directoryPath.split('/');
      return '.../${parts.sublist(parts.length - 2).join('/')}';
    }
    return directoryPath;
  }

  /// Validate if directory exists and is accessible
  static Future<bool> validateDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      return await directory.exists();
    } catch (e) {
      debugPrint('Error validating directory $directoryPath: $e');
      return false;
    }
  }
}
