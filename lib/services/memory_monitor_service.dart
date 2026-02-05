import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ExoPlayerTracker {
  static final Set<int> _activeControllers = <int>{};
  static int _totalCreated = 0;
  static int _totalDisposed = 0;

  static void registerController(int hashCode) {
    _activeControllers.add(hashCode);
    _totalCreated++;
    if (kDebugMode) {
      debugPrint(
        ' ExoPlayer #$hashCode created (Active: ${_activeControllers.length}, Total: $_totalCreated)',
      );
    }
  }

  static void disposeController(int hashCode) {
    _activeControllers.remove(hashCode);
    _totalDisposed++;
    if (kDebugMode) {
      debugPrint(
        ' ExoPlayer #$hashCode disposed (Active: ${_activeControllers.length}, Disposed: $_totalDisposed)',
      );
    }
  }

  static int get activeCount => _activeControllers.length;
  static int get totalCreated => _totalCreated;
  static int get totalDisposed => _totalDisposed;

  static void reset() {
    _activeControllers.clear();
    _totalCreated = 0;
    _totalDisposed = 0;
  }
}

class MemoryMonitorService {
  static Timer? _memoryTimer;
  static const Duration _checkInterval = Duration(seconds: 5);
  static int _previousInstanceCount = 0;

  static void startMonitoring() {
    if (kDebugMode) {
      _memoryTimer?.cancel();
      _memoryTimer = Timer.periodic(_checkInterval, (timer) {
        _checkMemoryUsage();
      });
    }
  }

  static void stopMonitoring() {
    _memoryTimer?.cancel();
    _memoryTimer = null;
  }

  static Future<void> _checkMemoryUsage() async {
    try {
      // Get device info for context
      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'Unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = '${iosInfo.name} ${iosInfo.model}';
      }

      final currentInstanceCount = ExoPlayerTracker.activeCount;

      if (currentInstanceCount > _previousInstanceCount + 2) {
        debugPrint(' MEMORY LEAK DETECTED: $deviceName');
        debugPrint(
          '   ExoPlayer instances increased from $_previousInstanceCount to $currentInstanceCount',
        );
        debugPrint('   This indicates improper video controller disposal');
      }

      if (currentInstanceCount > 3) {
        debugPrint(
          ' CRITICAL: Too many ExoPlayer instances ($currentInstanceCount)',
        );
        debugPrint('   App may crash soon due to memory exhaustion');
        debugPrint(
          '   Total created: ${ExoPlayerTracker.totalCreated}, Total disposed: ${ExoPlayerTracker.totalDisposed}',
        );
      }

      _previousInstanceCount = currentInstanceCount;
    } catch (e) {
      debugPrint('Memory monitoring error: $e');
    }
  }

  static Future<void> forceGarbageCollection() async {
    if (Platform.isAndroid) {
      try {
        // Force GC on Android
        await SystemChannels.platform.invokeMethod('System.gc');
        debugPrint(' Forced garbage collection');
      } catch (e) {
        debugPrint('Failed to force GC: $e');
      }
    }
  }
}

// Provider for memory monitoring
final memoryMonitorProvider = Provider<MemoryMonitorService>((ref) {
  ref.onDispose(() {
    MemoryMonitorService.stopMonitoring();
  });
  return MemoryMonitorService();
});
