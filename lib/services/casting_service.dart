import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
  static const String _ssdpAddress = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const String _avTransportService =
      'urn:schemas-upnp-org:service:AVTransport:1';
  static const String _renderingControlService =
      'urn:schemas-upnp-org:service:RenderingControl:1';

  static Stream<List<CastDevice>> get devicesStream =>
      _devicesController?.stream ?? Stream.empty();

  static Stream<CastSession> get sessionStream =>
      _sessionController?.stream ?? Stream.empty();

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result ?? false;
    } catch (e) {
      debugPrint('Error initializing casting service: $e');
      _isInitialized = true; // DLNA does not require native init.
    }

    if (_isInitialized) {
      _initializeStreams();
    }
    return _isInitialized;
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking casting support: $e');
      return true; // DLNA is supported via local network scan.
    }
  }

  static Future<List<CastDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!_isInitialized) return [];

      _isScanning = true;
      _notifyDevicesChange();

      List<CastDevice> devices = [];
      const maxAttempts = 2;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        devices = await _scanDlnaDevices(timeout: timeout);
        if (devices.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 400));
      }
      _availableDevices = devices;
      _isScanning = false;

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

      if (device.type == 'DLNA') {
        _updateDeviceConnection(device.id, true);
        _currentSession = CastSession(device: device);
        _notifySessionChange();
        return true;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        _updateDeviceConnection(_currentSession!.device.id, false);
        _currentSession = null;
        _notifySessionChange();
        return true;
      }

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

      if (device.type == 'DLNA') {
        final avTransportUrl =
            device.capabilities?['avTransportUrl'] as String?;
        if (avTransportUrl == null || avTransportUrl.isEmpty) return false;

        final ok = await _dlnaSetAvTransportUri(
          avTransportUrl,
          mediaUrl,
        );
        if (!ok) return false;

        if (autoPlay) {
          await _dlnaPlay(avTransportUrl);
        }

        _currentSession = CastSession(
          device: device,
          mediaInfo: mediaInfo,
          position: startPosition ?? Duration.zero,
          isPlaying: autoPlay,
        );
        _notifySessionChange();
        return true;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final avTransportUrl =
            _currentSession!.device.capabilities?['avTransportUrl'] as String?;
        if (avTransportUrl == null || avTransportUrl.isEmpty) return false;
        final ok = await _dlnaPlay(avTransportUrl);
        if (ok) _updateSessionState(isPlaying: true);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final avTransportUrl =
            _currentSession!.device.capabilities?['avTransportUrl'] as String?;
        if (avTransportUrl == null || avTransportUrl.isEmpty) return false;
        final ok = await _dlnaPause(avTransportUrl);
        if (ok) _updateSessionState(isPlaying: false);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final avTransportUrl =
            _currentSession!.device.capabilities?['avTransportUrl'] as String?;
        if (avTransportUrl == null || avTransportUrl.isEmpty) return false;
        final ok = await _dlnaStop(avTransportUrl);
        if (ok) _updateSessionState(isPlaying: false, position: Duration.zero);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final avTransportUrl =
            _currentSession!.device.capabilities?['avTransportUrl'] as String?;
        if (avTransportUrl == null || avTransportUrl.isEmpty) return false;
        final ok = await _dlnaSeek(avTransportUrl, position);
        if (ok) _updateSessionState(position: position);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final renderingUrl =
            _currentSession!.device.capabilities?['renderingControlUrl']
                as String?;
        if (renderingUrl == null || renderingUrl.isEmpty) return false;
        final ok = await _dlnaSetVolume(renderingUrl, volume);
        if (ok) _updateSessionState(volume: volume);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        final renderingUrl =
            _currentSession!.device.capabilities?['renderingControlUrl']
                as String?;
        if (renderingUrl == null || renderingUrl.isEmpty) return false;
        final ok = await _dlnaSetMute(renderingUrl, muted);
        if (ok) _updateSessionState(isMuted: muted);
        return ok;
      }

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

      if (_currentSession!.device.type == 'DLNA') {
        return _currentSession;
      }

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
      if (_currentSession?.device.type == 'DLNA') {
        return _currentSession?.device.id == deviceId;
      }
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

  static Future<List<CastDevice>> _scanDlnaDevices({
    required Duration timeout,
  }) async {
    final devices = <String, CastDevice>{};
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;

    final searchRequest = [
      'M-SEARCH * HTTP/1.1',
      'HOST: $_ssdpAddress:$_ssdpPort',
      'MAN: "ssdp:discover"',
      'MX: 2',
      'ST: ssdp:all',
      '',
      '',
    ].join('\r\n');

    socket.send(
      utf8.encode(searchRequest),
      InternetAddress(_ssdpAddress),
      _ssdpPort,
    );

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    socket.listen((event) async {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;

      final response = utf8.decode(datagram.data, allowMalformed: true);
      final headers = _parseSsdpHeaders(response);
      final location = headers['location'];
      final usn = headers['usn'];
      if (location == null || location.isEmpty) return;

      final key = usn ?? location;
      if (devices.containsKey(key)) return;

      final device = await _fetchDlnaDevice(location, headers);
      if (device != null) {
        devices[key] = device;
        _addOrUpdateDevice(device);
      }
    });

    await completer.future;
    timer.cancel();
    socket.close();

    return devices.values.toList();
  }

  static Map<String, String> _parseSsdpHeaders(String response) {
    final lines = response.split(RegExp(r'\r\n|\n'));
    final headers = <String, String>{};
    for (final line in lines) {
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim().toLowerCase();
      final value = line.substring(idx + 1).trim();
      headers[key] = value;
    }
    return headers;
  }

  static Future<CastDevice?> _fetchDlnaDevice(
    String location,
    Map<String, String> headers,
  ) async {
    try {
      final uri = Uri.parse(location);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) return null;

      final xml = response.body;
      final friendlyName =
          _matchXmlTag(xml, 'friendlyName') ?? uri.host;
      final urlBase = _matchXmlTag(xml, 'URLBase');
      final baseUri = Uri.parse(urlBase ?? location);
      final deviceType = _matchXmlTag(xml, 'deviceType');

      final avTransport = _findServiceControlUrl(
        xml,
        _avTransportService,
        baseUri,
      );
      final rendering = _findServiceControlUrl(
        xml,
        _renderingControlService,
        baseUri,
      );

      if (avTransport == null || avTransport.isEmpty) {
        return null;
      }

      return CastDevice(
        id: headers['usn'] ?? location,
        name: friendlyName,
        type: 'DLNA',
        host: uri.host,
        port: uri.port == 0 ? 80 : uri.port,
        isConnected: false,
        capabilities: {
          'location': location,
          'avTransportUrl': avTransport,
          'renderingControlUrl': rendering,
          'server': headers['server'],
          'st': headers['st'],
          'deviceType': deviceType,
        },
      );
    } catch (_) {
      return null;
    }
  }

  static String? _matchXmlTag(String xml, String tag) {
    final regex = RegExp(
      '<$tag[^>]*>(.*?)</$tag>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim();
  }

  static String? _findServiceControlUrl(
    String xml,
    String serviceType,
    Uri baseUri,
  ) {
    final serviceRegex = RegExp(
      '<service>.*?<serviceType>\\s*${RegExp.escape(serviceType)}\\s*</serviceType>.*?<controlURL>\\s*(.*?)\\s*</controlURL>.*?</service>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = serviceRegex.firstMatch(xml);
    final control = match?.group(1);
    if (control == null || control.isEmpty) return null;
    return baseUri.resolve(control).toString();
  }

  static Future<bool> _dlnaSetAvTransportUri(
    String controlUrl,
    String mediaUrl,
  ) async {
    const action = 'SetAVTransportURI';
    const service = _avTransportService;
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
        <CurrentURI>${_xmlEscape(mediaUrl)}</CurrentURI>
        <CurrentURIMetaData></CurrentURIMetaData>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaPlay(String controlUrl) async {
    const action = 'Play';
    const service = _avTransportService;
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
        <Speed>1</Speed>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaPause(String controlUrl) async {
    const action = 'Pause';
    const service = _avTransportService;
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaStop(String controlUrl) async {
    const action = 'Stop';
    const service = _avTransportService;
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaSeek(
    String controlUrl,
    Duration position,
  ) async {
    const action = 'Seek';
    const service = _avTransportService;
    final target = _formatDlnaTime(position);
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
        <Unit>REL_TIME</Unit>
        <Target>$target</Target>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaSetVolume(
    String controlUrl,
    double volume,
  ) async {
    const action = 'SetVolume';
    const service = _renderingControlService;
    final vol = (volume.clamp(0.0, 1.0) * 100).round();
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
        <Channel>Master</Channel>
        <DesiredVolume>$vol</DesiredVolume>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _dlnaSetMute(
    String controlUrl,
    bool muted,
  ) async {
    const action = 'SetMute';
    const service = _renderingControlService;
    final body = '''
      <u:$action xmlns:u="$service">
        <InstanceID>0</InstanceID>
        <Channel>Master</Channel>
        <DesiredMute>${muted ? 1 : 0}</DesiredMute>
      </u:$action>
    ''';
    return _sendDlnaSoap(controlUrl, service, action, body);
  }

  static Future<bool> _sendDlnaSoap(
    String controlUrl,
    String serviceType,
    String action,
    String innerBody,
  ) async {
    try {
      final envelope = '''
        <?xml version="1.0" encoding="utf-8"?>
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
          s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
          <s:Body>
            $innerBody
          </s:Body>
        </s:Envelope>
      ''';
      final response = await http.post(
        Uri.parse(controlUrl),
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPAction': '"$serviceType#$action"',
        },
        body: envelope,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('DLNA SOAP error: $e');
      return false;
    }
  }

  static String _formatDlnaTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  static String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
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
