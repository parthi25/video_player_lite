import 'dart:io';
import 'package:flutter/foundation.dart';

class MemoryManager {
  static bool _isInitialized = false;
  static int _memoryThreshold = 100 * 1024 * 1024; // 100MB threshold

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        // Adjust memory threshold based on available memory
        final memoryInfo = await _getAndroidMemoryInfo();
        if (memoryInfo != null) {
          _memoryThreshold = (memoryInfo['totalMemory']! * 0.3)
              .round(); // 30% of total memory
        }
      } else if (Platform.isIOS) {
        _memoryThreshold = 80 * 1024 * 1024; // 80MB for iOS
      }
    } catch (e) {
      debugPrint('Error initializing memory manager: $e');
    }

    _isInitialized = true;
  }

  static Future<Map<String, int>?> _getAndroidMemoryInfo() async {
    try {
      // This is a simplified version - in production you'd use platform channels
      return {
        'totalMemory': 2 * 1024 * 1024 * 1024, // Default 2GB
        'availableMemory': 1 * 1024 * 1024 * 1024, // Default 1GB
      };
    } catch (e) {
      return null;
    }
  }

  static bool shouldReduceQuality() {
    return _memoryThreshold < 150 * 1024 * 1024; // Less than 150MB
  }

  static int getMaxCacheSize() {
    if (_memoryThreshold < 100 * 1024 * 1024) {
      return 50 * 1024 * 1024; // 50MB for low memory
    } else if (_memoryThreshold < 200 * 1024 * 1024) {
      return 100 * 1024 * 1024; // 100MB for medium memory
    } else {
      return 200 * 1024 * 1024; // 200MB for high memory
    }
  }

  static Duration getBufferDuration() {
    if (_memoryThreshold < 100 * 1024 * 1024) {
      return const Duration(seconds: 2); // Smaller buffer for low memory
    } else {
      return const Duration(seconds: 5); // Standard buffer
    }
  }

  static void clearCache() {
    // Implement cache clearing logic
    debugPrint('Clearing video cache to free memory');
  }

  static bool isLowMemory() {
    return _memoryThreshold < 100 * 1024 * 1024;
  }
}
