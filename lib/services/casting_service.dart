import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CastDevice {
  final String id;
  final String name;
  final String type;
  final String host;
  final int port;
  final bool isConnected;
  final String? iconUrl;
  final Map<String, dynamic>? capabilities;

  CastDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    this.isConnected = false,
    this.iconUrl,
    this.capabilities,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'host': host,
      'port': port,
      'isConnected': isConnected,
      'iconUrl': iconUrl,
      'capabilities': capabilities,
    };
  }

  factory CastDevice.fromJson(Map<String, dynamic> json) {
    return CastDevice(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      host: json['host'],
      port: json['port'],
      isConnected: json['isConnected'] ?? false,
      iconUrl: json['iconUrl'],
      capabilities: json['capabilities'],
    );
  }
}

class CastMediaInfo {
  final String title;
  final String? artist;
  final String? album;
  final String? imageUrl;
  final Duration duration;
  final String mimeType;
  final Map<String, String>? metadata;

  CastMediaInfo({
    required this.title,
    this.artist,
    this.album,
    this.imageUrl,
    required this.duration,
    required this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'imageUrl': imageUrl,
      'duration': duration.inMilliseconds,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }

  factory CastMediaInfo.fromJson(Map<String, dynamic> json) {
    return CastMediaInfo(
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      imageUrl: json['imageUrl'],
      duration: Duration(milliseconds: json['duration']),
      mimeType: json['mimeType'],
      metadata: json['metadata'],
    );
  }
}

class CastSession {
  final CastDevice device;
  final CastMediaInfo? mediaInfo;
  final Duration position;
  final bool isPlaying;
  final double volume;
  final bool isMuted;

  CastSession({
    required this.device,
    this.mediaInfo,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.volume = 1.0,
    this.isMuted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'mediaInfo': mediaInfo?.toJson(),
      'position': position.inMilliseconds,
      'isPlaying': isPlaying,
      'volume': volume,
      'isMuted': isMuted,
    };
  }

  factory CastSession.fromJson(Map<String, dynamic> json) {
    return CastSession(
      device: CastDevice.fromJson(json['device']),
      mediaInfo: json['mediaInfo'] != null
          ? CastMediaInfo.fromJson(json['mediaInfo'])
          : null,
      position: Duration(milliseconds: json['position']),
      isPlaying: json['isPlaying'],
      volume: json['volume'].toDouble(),
      isMuted: json['isMuted'],
    );
  }
}

class CastingService {
  static const MethodChannel _channel = MethodChannel('next_player/casting');
  static StreamController<List<CastDevice>>? _devicesController;
  static StreamController<CastSession>? _sessionController;
  static List<CastDevice> _availableDevices = [];
  static CastSession? _currentSession;
  static bool _isInitialized = false;
  static bool _isScanning = false;

  static Stream<List<CastDevice>> get devicesStream =>
      _devicesController?.stream ?? Stream.empty();

  static Stream<CastSession> get sessionStream =>
      _sessionController?.stream ?? Stream.empty();

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result ?? false;

      if (_isInitialized) {
        _initializeStreams();
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing casting service: $e');
      return false;
    }
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking casting support: $e');
      return false;
    }
  }

  static Future<List<CastDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!_isInitialized) return [];

      _isScanning = true;
      _notifyDevicesChange();

      final result = await _channel.invokeMethod('scanForDevices', {
        'timeout': timeout.inMilliseconds,
      });

      _isScanning = false;

      if (result != null) {
        final List<dynamic> devicesJson = result;
        _availableDevices = devicesJson
            .map((json) => CastDevice.fromJson(json))
            .toList();
      }

      _notifyDevicesChange();
      return _availableDevices;
    } catch (e) {
      debugPrint('Error scanning for devices: $e');
      _isScanning = false;
      _notifyDevicesChange();
      return [];
    }
  }

  static Future<bool> connectToDevice(CastDevice device) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('connectToDevice', {
        'deviceId': device.id,
        'host': device.host,
        'port': device.port,
      });

      if (result ?? false) {
        _updateDeviceConnection(device.id, true);
        _currentSession = CastSession(device: device);
        _notifySessionChange();
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      return false;
    }
  }

  static Future<bool> disconnectFromDevice() async {
    try {
      if (_currentSession == null) return true;

      final result = await _channel.invokeMethod('disconnectFromDevice');

      if (result ?? false) {
        _updateDeviceConnection(_currentSession!.device.id, false);
        _currentSession = null;
        _notifySessionChange();
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error disconnecting from device: $e');
      return false;
    }
  }

  static Future<bool> loadMedia({
    required CastDevice device,
    required String mediaUrl,
    required CastMediaInfo mediaInfo,
    bool autoPlay = true,
    Duration? startPosition,
  }) async {
    try {
      if (!_isInitialized) return false;

      final params = <String, dynamic>{
        'deviceId': device.id,
        'mediaUrl': mediaUrl,
        'mediaInfo': mediaInfo.toJson(),
        'autoPlay': autoPlay,
      };

      if (startPosition != null) {
        params['startPosition'] = startPosition.inMilliseconds;
      }

      final result = await _channel.invokeMethod('loadMedia', params);

      if (result ?? false) {
        _currentSession = CastSession(
          device: device,
          mediaInfo: mediaInfo,
          position: startPosition ?? Duration.zero,
          isPlaying: autoPlay,
        );
        _notifySessionChange();
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error loading media: $e');
      return false;
    }
  }

  static Future<bool> play() async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('play');

      if (result ?? false) {
        _updateSessionState(isPlaying: true);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error playing media: $e');
      return false;
    }
  }

  static Future<bool> pause() async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('pause');

      if (result ?? false) {
        _updateSessionState(isPlaying: false);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error pausing media: $e');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('stop');

      if (result ?? false) {
        _updateSessionState(isPlaying: false, position: Duration.zero);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error stopping media: $e');
      return false;
    }
  }

  static Future<bool> seek(Duration position) async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('seek', {
        'position': position.inMilliseconds,
      });

      if (result ?? false) {
        _updateSessionState(position: position);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error seeking media: $e');
      return false;
    }
  }

  static Future<bool> setVolume(double volume) async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });

      if (result ?? false) {
        _updateSessionState(volume: volume);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting volume: $e');
      return false;
    }
  }

  static Future<bool> setMuted(bool muted) async {
    try {
      if (_currentSession == null) return false;

      final result = await _channel.invokeMethod('setMuted', {'muted': muted});

      if (result ?? false) {
        _updateSessionState(isMuted: muted);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting mute state: $e');
      return false;
    }
  }

  static Future<CastSession?> getSessionStatus() async {
    try {
      if (_currentSession == null) return null;

      final result = await _channel.invokeMethod('getSessionStatus');

      if (result != null) {
        _currentSession = CastSession.fromJson(result);
        _notifySessionChange();
      }

      return _currentSession;
    } catch (e) {
      debugPrint('Error getting session status: $e');
      return _currentSession;
    }
  }

  static Future<bool> isDeviceConnected(String deviceId) async {
    try {
      return await _channel.invokeMethod('isDeviceConnected', {
            'deviceId': deviceId,
          }) ??
          false;
    } catch (e) {
      debugPrint('Error checking device connection: $e');
      return false;
    }
  }

  static List<CastDevice> getAvailableDevices() {
    return List.unmodifiable(_availableDevices);
  }

  static CastSession? getCurrentSession() {
    return _currentSession;
  }

  static bool get isScanning => _isScanning;
  static bool get isInitialized => _isInitialized;

  static void _initializeStreams() {
    _devicesController?.close();
    _sessionController?.close();

    _devicesController = StreamController<List<CastDevice>>.broadcast();
    _sessionController = StreamController<CastSession>.broadcast();

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceDiscovered':
          final deviceJson = call.arguments;
          final device = CastDevice.fromJson(deviceJson);
          _addOrUpdateDevice(device);
          break;
        case 'onDeviceLost':
          final deviceId = call.arguments;
          _removeDevice(deviceId);
          break;
        case 'onMediaStatusChanged':
          final statusJson = call.arguments;
          _updateSessionFromStatus(statusJson);
          break;
        case 'onDeviceConnected':
          final deviceId = call.arguments;
          _updateDeviceConnection(deviceId, true);
          break;
        case 'onDeviceDisconnected':
          final deviceId = call.arguments;
          _updateDeviceConnection(deviceId, false);
          if (_currentSession?.device.id == deviceId) {
            _currentSession = null;
            _notifySessionChange();
          }
          break;
      }
    });
  }

  static void _addOrUpdateDevice(CastDevice device) {
    final existingIndex = _availableDevices.indexWhere(
      (d) => d.id == device.id,
    );
    if (existingIndex >= 0) {
      _availableDevices[existingIndex] = device;
    } else {
      _availableDevices.add(device);
    }
    _notifyDevicesChange();
  }

  static void _removeDevice(String deviceId) {
    _availableDevices.removeWhere((device) => device.id == deviceId);
    _notifyDevicesChange();
  }

  static void _updateDeviceConnection(String deviceId, bool isConnected) {
    final deviceIndex = _availableDevices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex >= 0) {
      _availableDevices[deviceIndex] = CastDevice(
        id: _availableDevices[deviceIndex].id,
        name: _availableDevices[deviceIndex].name,
        type: _availableDevices[deviceIndex].type,
        host: _availableDevices[deviceIndex].host,
        port: _availableDevices[deviceIndex].port,
        isConnected: isConnected,
        iconUrl: _availableDevices[deviceIndex].iconUrl,
        capabilities: _availableDevices[deviceIndex].capabilities,
      );
      _notifyDevicesChange();
    }
  }

  static void _updateSessionFromStatus(Map<String, dynamic> status) {
    if (_currentSession != null) {
      _currentSession = CastSession(
        device: _currentSession!.device,
        mediaInfo: _currentSession!.mediaInfo,
        position: Duration(milliseconds: status['position'] ?? 0),
        isPlaying: status['isPlaying'] ?? false,
        volume: (status['volume'] ?? 1.0).toDouble(),
        isMuted: status['isMuted'] ?? false,
      );
      _notifySessionChange();
    }
  }

  static void _updateSessionState({
    bool? isPlaying,
    Duration? position,
    double? volume,
    bool? isMuted,
  }) {
    if (_currentSession != null) {
      _currentSession = CastSession(
        device: _currentSession!.device,
        mediaInfo: _currentSession!.mediaInfo,
        position: position ?? _currentSession!.position,
        isPlaying: isPlaying ?? _currentSession!.isPlaying,
        volume: volume ?? _currentSession!.volume,
        isMuted: isMuted ?? _currentSession!.isMuted,
      );
      _notifySessionChange();
    }
  }

  static void _notifyDevicesChange() {
    _devicesController?.add(List.unmodifiable(_availableDevices));
  }

  static void _notifySessionChange() {
    if (_currentSession != null) {
      _sessionController?.add(_currentSession!);
    }
  }

  static Future<void> dispose() async {
    await disconnectFromDevice();

    _devicesController?.close();
    _sessionController?.close();
    _devicesController = null;
    _sessionController = null;

    _channel.setMethodCallHandler(null);
    _isInitialized = false;
    _isScanning = false;
    _availableDevices.clear();
    _currentSession = null;
  }

  // Utility methods
  static Future<bool> castLocalFile({
    required CastDevice device,
    required String filePath,
    required CastMediaInfo mediaInfo,
    bool autoPlay = true,
  }) async {
    try {
      // This would require setting up a local HTTP server
      // For now, we'll assume the file is accessible via URL
      return await loadMedia(
        device: device,
        mediaUrl: 'file://$filePath',
        mediaInfo: mediaInfo,
        autoPlay: autoPlay,
      );
    } catch (e) {
      debugPrint('Error casting local file: $e');
      return false;
    }
  }

  static Future<bool> castNetworkStream({
    required CastDevice device,
    required String streamUrl,
    required CastMediaInfo mediaInfo,
    bool autoPlay = true,
  }) async {
    try {
      return await loadMedia(
        device: device,
        mediaUrl: streamUrl,
        mediaInfo: mediaInfo,
        autoPlay: autoPlay,
      );
    } catch (e) {
      debugPrint('Error casting network stream: $e');
      return false;
    }
  }
}
