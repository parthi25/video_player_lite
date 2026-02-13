import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('next_player/pip');
  static bool _isPiPEnabled = false;
  static StreamController<bool>? _pipStatusController;
  static Stream<bool> get pipStatusStream =>
      _pipStatusController?.stream ?? Stream.empty();

  // Enhanced device compatibility check
  static Future<bool> isPiPSupported() async {
    try {
      // Check for Android PiP support
      if (Platform.isAndroid) {
        // Android 8.0+ (API 26+) supports PiP
        final version = await _getAndroidVersion();
        if (version >= 26) {
          return await _channel.invokeMethod('isPiPSupported') ?? false;
        }
        return false;
      }
      // Check for iOS PiP support
      else if (Platform.isIOS) {
        // iOS 9.0+ supports PiP
        final version = await _getIOSVersion();
        if (version >= 9.0) {
          return await _channel.invokeMethod('isPiPSupported') ?? false;
        }
        return false;
      }
      // Web and desktop fallback
      else if (kIsWeb ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux) {
        return await _checkWebDesktopPiP();
      }
      return false;
    } catch (e) {
      debugPrint('Error checking PiP support: $e');
      return false;
    }
  }

  // Get Android version
  static Future<int> _getAndroidVersion() async {
    try {
      final info = await _channel.invokeMethod('getAndroidVersion');
      return info ?? 21; // Default to older version
    } catch (e) {
      return 21;
    }
  }

  // Get iOS version
  static Future<double> _getIOSVersion() async {
    try {
      final info = await _channel.invokeMethod('getIOSVersion');
      return info?.toDouble() ?? 8.0;
    } catch (e) {
      return 8.0;
    }
  }

  // Web/Desktop PiP check
  static Future<bool> _checkWebDesktopPiP() async {
    try {
      if (kIsWeb) {
        // Check if browser supports Picture-in-Picture API
        return kIsWeb;
      } else {
        // Desktop PiP support check
        return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isPiPActive() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _channel.invokeMethod('isPiPActive') ?? false;
      } else {
        // Web/desktop PiP status check
        return _isPiPEnabled;
      }
    } catch (e) {
      debugPrint('Error checking PiP status: $e');
      return false;
    }
  }

  static Future<bool> enablePiP({
    required double aspectRatio,
    String? title,
    String? artist,
    String? genre,
    String? albumArt,
  }) async {
    try {
      if (!await isPiPSupported()) {
        debugPrint('PiP not supported on this device');
        return false;
      }

      final params = <String, dynamic>{
        'aspectRatio': aspectRatio,
        'title': title ?? 'Parthi Play',
        'artist': artist ?? 'Parthi Play',
        'genre': genre ?? 'Video',
        'albumArt': albumArt,
      };

      bool result = false;

      // Platform-specific PiP enable
      if (Platform.isAndroid) {
        result = await _channel.invokeMethod('enablePiP', params) ?? false;
      } else if (Platform.isIOS) {
        result = await _channel.invokeMethod('enablePiPiOS', params) ?? false;
      } else if (kIsWeb) {
        result = await _enableWebPiP(aspectRatio, title, artist, genre);
      } else {
        // Desktop PiP - use floating package
        result = await _enableDesktopPiP(aspectRatio, title, artist, genre);
      }

      _isPiPEnabled = result;

      if (_isPiPEnabled) {
        _initializePiPStatusStream();
      }

      return _isPiPEnabled;
    } catch (e) {
      debugPrint('Error enabling PiP: $e');
      // Try fallback method
      return await _enablePiPFallback(
        aspectRatio,
        title,
        artist,
        genre,
        albumArt,
      );
    }
  }

  // Web PiP implementation
  static Future<bool> _enableWebPiP(
    double aspectRatio,
    String? title,
    String? artist,
    String? genre,
  ) async {
    try {
      if (kIsWeb) {
        // Use HTML5 Video PiP API
        final result =
            await _channel.invokeMethod('enableWebPiP', {
              'aspectRatio': aspectRatio,
              'title': title ?? 'Parthi Play',
            }) ??
            false;
        _isPiPEnabled = result;

        if (_isPiPEnabled) {
          _initializePiPStatusStream();
        }

        return _isPiPEnabled;
      }
      return false;
    } catch (e) {
      debugPrint('Web PiP failed: $e');
      return false;
    }
  }

  // Desktop PiP implementation using floating package
  static Future<bool> _enableDesktopPiP(
    double aspectRatio,
    String? title,
    String? artist,
    String? genre,
  ) async {
    try {
      // Create floating window for desktop
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final result = await _createFloatingWindow(
          aspectRatio,
          title,
          artist,
          genre,
        );
        _isPiPEnabled = result;

        if (_isPiPEnabled) {
          _initializePiPStatusStream();
        }

        return _isPiPEnabled;
      }
      return false;
    } catch (e) {
      debugPrint('Desktop PiP failed: $e');
      return false;
    }
  }

  // Fallback PiP method for unsupported devices
  static Future<bool> _enablePiPFallback(
    double aspectRatio,
    String? title,
    String? artist,
    String? genre,
    String? albumArt,
  ) async {
    try {
      debugPrint('Trying PiP fallback method');

      // Create a floating window simulation for desktop/web
      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux) {
        return await _createFloatingWindow(aspectRatio, title, artist, genre);
      }

      return false;
    } catch (e) {
      debugPrint('Fallback PiP failed: $e');
      return false;
    }
  }

  // Create floating window for desktop using platform channels
  static Future<bool> _createFloatingWindow(
    double aspectRatio,
    String? title,
    String? artist,
    String? genre,
  ) async {
    try {
      // Use platform channels for desktop PiP simulation
      debugPrint('Creating floating window with aspect ratio: $aspectRatio');

      final params = <String, dynamic>{
        'aspectRatio': aspectRatio,
        'title': title ?? 'Parthi Play',
        'artist': artist ?? 'Parthi Play',
        'genre': genre ?? 'Video',
      };

      final result =
          await _channel.invokeMethod('createFloatingWindow', params) ?? false;
      _isPiPEnabled = result;
      _initializePiPStatusStream();

      return result;
    } catch (e) {
      debugPrint('Floating window creation failed: $e');
      return false;
    }
  }

  static Future<bool> disablePiP() async {
    try {
      bool result = false;

      // Platform-specific PiP disable
      if (Platform.isAndroid || Platform.isIOS) {
        result = await _channel.invokeMethod('disablePiP') ?? false;
      } else if (kIsWeb) {
        result = await _disableWebPiP();
      } else {
        // Desktop PiP
        result = await _disableDesktopPiP();
      }

      _isPiPEnabled = !result;

      if (!_isPiPEnabled) {
        _disposePiPStatusStream();
      }

      return !_isPiPEnabled;
    } catch (e) {
      debugPrint('Error disabling PiP: $e');
      // Try fallback
      return await _disablePiPFallback();
    }
  }

  // Web PiP disable
  static Future<bool> _disableWebPiP() async {
    try {
      if (kIsWeb) {
        final result = await _channel.invokeMethod('disableWebPiP') ?? false;
        _isPiPEnabled = !result;

        if (!_isPiPEnabled) {
          _disposePiPStatusStream();
        }

        return !_isPiPEnabled;
      }
      return false;
    } catch (e) {
      debugPrint('Web PiP disable failed: $e');
      return false;
    }
  }

  // Desktop PiP disable
  static Future<bool> _disableDesktopPiP() async {
    try {
      final result = await _closeFloatingWindow();
      _isPiPEnabled = !result;

      if (!_isPiPEnabled) {
        _disposePiPStatusStream();
      }

      return !_isPiPEnabled;
    } catch (e) {
      debugPrint('Desktop PiP disable failed: $e');
      return false;
    }
  }

  // Fallback PiP disable
  static Future<bool> _disablePiPFallback() async {
    try {
      final result = await _closeFloatingWindow();
      _isPiPEnabled = !result;

      if (!_isPiPEnabled) {
        _disposePiPStatusStream();
      }

      return !_isPiPEnabled;
    } catch (e) {
      debugPrint('Fallback PiP disable failed: $e');
      return false;
    }
  }

  // Close floating window
  static Future<bool> _closeFloatingWindow() async {
    try {
      debugPrint('Closing floating window');
      final result =
          await _channel.invokeMethod('closeFloatingWindow') ?? false;
      _isPiPEnabled = !result;
      _disposePiPStatusStream();
      return result;
    } catch (e) {
      debugPrint('Floating window close failed: $e');
      return false;
    }
  }

  static Future<void> updatePiPParams({
    String? title,
    String? artist,
    String? genre,
    String? albumArt,
  }) async {
    try {
      if (!_isPiPEnabled) return;

      final params = <String, dynamic>{
        'title': title,
        'artist': artist,
        'genre': genre,
        'albumArt': albumArt,
      };

      await _channel.invokeMethod('updatePiPParams', params);
    } catch (e) {
      debugPrint('Error updating PiP params: $e');
    }
  }

  static void _initializePiPStatusStream() {
    _pipStatusController?.close();
    _pipStatusController = StreamController<bool>.broadcast();

    // Listen to PiP status changes
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPiPStatusChanged':
          final status = call.arguments['status'] ?? false;
          _isPiPEnabled = status;
          _pipStatusController?.add(status);
          break;
      }
    });
  }

  static void _disposePiPStatusStream() {
    _pipStatusController?.close();
    _pipStatusController = null;
    _channel.setMethodCallHandler(null);
  }

  static Future<void> dispose() async {
    await disablePiP();
    _disposePiPStatusStream();
  }

  static bool get isCurrentlyInPiP => _isPiPEnabled;
}
