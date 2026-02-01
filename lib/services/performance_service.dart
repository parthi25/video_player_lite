import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class PerformanceService {
  static bool _isLowEndDevice = false;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Consider devices with Android < 8 as low-end
        _isLowEndDevice = sdkInt < 26;
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        final model = iosInfo.model;
        final systemVersion = iosInfo.systemVersion;

        // Consider iPhone 6s/SE and older as low-end
        _isLowEndDevice =
            _isOldIOSDevice(model) || _isOldIOSVersion(systemVersion);
      }
    } catch (e) {
      debugPrint('Error detecting device performance: $e');
      _isLowEndDevice = true; // Assume low-end on error
    }

    _isInitialized = true;
  }

  static bool get isLowEndDevice => _isLowEndDevice;

  static bool _isOldIOSDevice(String model) {
    final oldModels = [
      'iPhone6,1', 'iPhone6,2', // iPhone 5s
      'iPhone7,1', 'iPhone7,2', // iPhone 6/6 Plus
      'iPhone8,1', 'iPhone8,2', 'iPhone8,4', // iPhone 6s/6s Plus/SE
    ];
    return oldModels.any((oldModel) => model.contains(oldModel));
  }

  static bool _isOldIOSVersion(String version) {
    try {
      final parts = version.split('.');
      final majorVersion = int.parse(parts[0]);
      return majorVersion < 13;
    } catch (e) {
      return true;
    }
  }

  // Get optimal video resolution based on device capabilities
  static String getOptimalResolution() {
    if (_isLowEndDevice) {
      return '720p'; // Lower resolution for low-end devices
    }
    return '1080p'; // Full HD for capable devices
  }

  // Get optimal buffer duration
  static Duration getOptimalBufferDuration() {
    if (_isLowEndDevice) {
      return const Duration(seconds: 3); // Smaller buffer for low-end devices
    }
    return const Duration(seconds: 10); // Larger buffer for better devices
  }

  // Get optimal video quality settings
  static Map<String, dynamic> getOptimalVideoSettings() {
    return {
      'autoPlay': !_isLowEndDevice, // Disable autoplay on low-end devices
      'looping': false,
      'showControls': true,
      'autoDetectFullscreenDevice': !_isLowEndDevice,
      'autoDetectFullscreenAspectRatio': !_isLowEndDevice,
      'handleLifecycle': true, // Always handle lifecycle for performance
      'expandToFill': true,
      'fit': BoxFit.contain,
      'placeholder': _isLowEndDevice, // Show placeholder on low-end devices
    };
  }
}
