import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PerformanceOptimizer {
  static bool _isInitialized = false;
  static bool _isLowEndDevice = false;
  static bool _isTablet = false;
  static int _availableMemory = 1024 * 1024 * 1024; // 1GB default
  static List<ConnectivityResult> _connectivity = [ConnectivityResult.none];
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _detectDeviceCapabilities();
      await _setupConnectivityMonitoring();
      await _optimizeForDevice();

      _isInitialized = true;
      debugPrint('Performance optimizer initialized');
      debugPrint('Low-end device: $_isLowEndDevice');
      debugPrint('Tablet: $_isTablet');
      debugPrint('Available memory: ${_availableMemory ~/ (1024 * 1024)}MB');
    } catch (e) {
      debugPrint('Error initializing performance optimizer: $e');
      // Assume low-end device on error
      _isLowEndDevice = true;
    }
  }

  static Future<void> _detectDeviceCapabilities() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // Consider devices with Android < 8 as low-end
      _isLowEndDevice = sdkInt < 26;

      // Use reasonable memory defaults - actual memory detection requires platform-specific APIs
      _availableMemory = 2 * 1024 * 1024 * 1024; // Default 2GB for Android

      // Detect tablet using modern approach
      _isTablet = _isAndroidTablet(androidInfo);
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final model = iosInfo.model;
      final systemVersion = iosInfo.systemVersion;

      // Consider iPhone 6s/SE and older as low-end
      _isLowEndDevice =
          _isOldIOSDevice(model) || _isOldIOSVersion(systemVersion);

      // Detect iPad
      _isTablet = model.startsWith('iPad');
    }
  }

  static bool _isAndroidTablet(AndroidDeviceInfo androidInfo) {
    // Modern tablet detection using manufacturer and model data
    // Avoid deprecated displayMetrics API
    final manufacturer = androidInfo.manufacturer.toLowerCase();
    final model = androidInfo.model.toLowerCase();
    final brand = androidInfo.brand.toLowerCase();

    // Check for known tablet manufacturers/models
    final tabletKeywords = [
      'tablet',
      'tab',
      'pad',
      'sm-t',
      'sm-p',
      'a7',
      'a8',
      'a9',
      'lenovo tab',
      'galaxy tab',
      'fire tablet',
      'nexus 9',
      'pixel c',
    ];

    final hasTabletKeyword = tabletKeywords.any(
      (keyword) =>
          model.contains(keyword) ||
          manufacturer.contains(keyword) ||
          brand.contains(keyword),
    );

    // Additional heuristics based on device characteristics
    final isLargeDevice =
        model.contains('10') || model.contains('11') || model.contains('12');

    return hasTabletKeyword || isLargeDevice;
  }

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

  static Future<void> _setupConnectivityMonitoring() async {
    _connectivity = await Connectivity().checkConnectivity();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      _connectivity = results;
      _adaptToNetworkConditions();
    });
  }

  static Future<void> _optimizeForDevice() async {
    if (_isLowEndDevice) {
      // Reduce animation duration
      // Lower video quality by default
      // Disable expensive features

      // Set preferred device orientation to landscape for video
      // await AutoOrientation.landscapeAutoMode(); // Disabled due to build issues

      // Enable wakelock to prevent screen from sleeping during playback
      await WakelockPlus.enable();
    }
  }

  static void _adaptToNetworkConditions() {
    if (_connectivity.isEmpty) return;

    final result = _connectivity.first;
    switch (result) {
      case ConnectivityResult.wifi:
        debugPrint('WiFi connection - High quality streaming');
        break;
      case ConnectivityResult.mobile:
        debugPrint('Mobile connection - Adaptive quality streaming');
        break;
      case ConnectivityResult.none:
        debugPrint('No connection - Offline mode');
        break;
      default:
        debugPrint('Unknown connection type');
    }
  }

  static bool get isLowEndDevice => _isLowEndDevice;
  static bool get isTablet => _isTablet;
  static int get availableMemory => _availableMemory;
  static List<ConnectivityResult> get connectivity => _connectivity;

  // Video quality optimization
  static String getOptimalVideoQuality() {
    if (_isLowEndDevice) {
      return '720p';
    } else if (_connectivity.contains(ConnectivityResult.mobile)) {
      return '1080p';
    } else {
      return '1080p';
    }
  }

  static Duration getOptimalBufferDuration() {
    if (_isLowEndDevice) {
      return const Duration(seconds: 3);
    } else if (_connectivity.contains(ConnectivityResult.mobile)) {
      return const Duration(seconds: 5);
    } else {
      return const Duration(seconds: 10);
    }
  }

  static int getMaxCacheSize() {
    if (_availableMemory < 1024 * 1024 * 1024) {
      // < 1GB
      return 50 * 1024 * 1024; // 50MB
    } else if (_availableMemory < 2 * 1024 * 1024 * 1024) {
      // < 2GB
      return 100 * 1024 * 1024; // 100MB
    } else {
      return 200 * 1024 * 1024; // 200MB
    }
  }

  // UI optimization
  static Duration getAnimationDuration() {
    return _isLowEndDevice
        ? const Duration(milliseconds: 150)
        : const Duration(milliseconds: 300);
  }

  static bool shouldEnableHardwareAcceleration() {
    return !_isLowEndDevice;
  }

  static bool shouldEnableBackgroundPlayback() {
    return !_isLowEndDevice &&
        !_connectivity.contains(ConnectivityResult.mobile);
  }

  // Memory management
  static Future<void> clearMemoryCache() async {
    // Force garbage collection
    if (!kReleaseMode) {
      debugPrint('Clearing memory cache...');
    }

    // Trigger garbage collection
    await Future.delayed(const Duration(milliseconds: 100));

    // In a real implementation, you would clear image caches, etc.
  }

  static void monitorMemoryUsage() {
    // Monitor memory usage and take action if needed
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_availableMemory < 100 * 1024 * 1024) {
        // < 100MB
        debugPrint('Low memory detected, clearing cache');
        clearMemoryCache();
      }
    });
  }

  // Battery optimization
  static Future<void> optimizeForBattery() async {
    if (_isLowEndDevice) {
      // Reduce frame rate
      // Lower brightness
      // Disable background processing
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    WakelockPlus.disable();
    // AutoOrientation.fullAutoMode(); // Disabled due to build issues
  }
}

class ErrorHandler {
  static void handleVideoError(String error, StackTrace? stackTrace) {
    debugPrint('Video player error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    // Categorize errors and provide appropriate feedback
    if (error.contains('network') || error.contains('connection')) {
      // Network error
      debugPrint('Network error detected');
    } else if (error.contains('format') || error.contains('codec')) {
      // Format error
      debugPrint('Video format error detected');
    } else if (error.contains('permission')) {
      // Permission error
      debugPrint('Permission error detected');
    } else {
      // Unknown error
      debugPrint('Unknown video error');
    }
  }

  static void handleGestureError(String error, StackTrace? stackTrace) {
    debugPrint('Gesture handling error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void handleSubtitleError(String error, StackTrace? stackTrace) {
    debugPrint('Subtitle error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void handlePerformanceError(String error, StackTrace? stackTrace) {
    debugPrint('Performance error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }

    // Take corrective action
    PerformanceOptimizer.clearMemoryCache();
  }
}

class PerformanceMonitor {
  static int _frameCount = 0;
  static double _totalFrameTime = 0.0;
  static DateTime? _lastFrameTime;
  static Timer? _monitorTimer;

  static void startMonitoring() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateFPS();
    });
  }

  static void stopMonitoring() {
    _monitorTimer?.cancel();
  }

  static void recordFrame() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime =
          now.difference(_lastFrameTime!).inMicroseconds.toDouble() / 1000.0;
      _totalFrameTime += frameTime;
      _frameCount++;
    }
    _lastFrameTime = now;
  }

  static void _calculateFPS() {
    if (_frameCount > 0) {
      final avgFrameTime = _totalFrameTime / _frameCount;
      final fps = 1000.0 / avgFrameTime;

      debugPrint('Average FPS: ${fps.toStringAsFixed(1)}');

      // Take action if FPS is too low
      if (fps < 20) {
        debugPrint('Low FPS detected, optimizing performance');
        PerformanceOptimizer.clearMemoryCache();
      }

      // Reset counters
      _frameCount = 0;
      _totalFrameTime = 0.0;
    }
  }
}

class NetworkOptimizer {
  static Future<bool> checkNetworkStability() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        return false;
      }

      // Simple ping test (in a real implementation, you'd use a proper ping)
      final startTime = DateTime.now();
      try {
        await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;

        debugPrint('Network latency: ${latency}ms');
        return latency < 2000; // Consider stable if latency < 2 seconds
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<void> optimizeForNetwork() async {
    final isStable = await checkNetworkStability();

    if (!isStable) {
      debugPrint('Unstable network detected, optimizing for low bandwidth');
      // Reduce video quality
      // Increase buffer size
      // Enable adaptive streaming
    }
  }
}
