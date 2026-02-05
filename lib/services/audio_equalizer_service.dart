import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EqualizerPreset {
  final String name;
  final List<double> frequencies;
  final List<double> gains;

  EqualizerPreset({
    required this.name,
    required this.frequencies,
    required this.gains,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'frequencies': frequencies, 'gains': gains};
  }

  factory EqualizerPreset.fromJson(Map<String, dynamic> json) {
    return EqualizerPreset(
      name: json['name'],
      frequencies: List<double>.from(json['frequencies']),
      gains: List<double>.from(json['gains']),
    );
  }
}

class AudioEqualizerService {
  static const MethodChannel _channel = MethodChannel('next_player/equalizer');
  static bool _isInitialized = false;
  static bool _isEnabled = false;
  static List<double> _frequencies = [];
  static List<double> _gains = [];
  static List<EqualizerPreset> _presets = [];
  static EqualizerPreset? _currentPreset;
  static StreamController<Map<String, dynamic>>? _equalizerController;

  static Stream<Map<String, dynamic>> get equalizerStream =>
      _equalizerController?.stream ?? Stream.empty();

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result ?? false;

      if (_isInitialized) {
        await _loadDefaultPresets();
        await _getFrequencyBands();
        _initializeEqualizerStream();
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing equalizer: $e');
      return false;
    }
  }

  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod('isSupported') ?? false;
    } catch (e) {
      debugPrint('Error checking equalizer support: $e');
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod('isEnabled') ?? false;
    } catch (e) {
      debugPrint('Error checking equalizer enabled status: $e');
      return false;
    }
  }

  static Future<bool> setEnabled(bool enabled) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setEnabled', {
        'enabled': enabled,
      });
      _isEnabled = result ?? false;

      _notifyEqualizerChange('enabled', _isEnabled);
      return _isEnabled;
    } catch (e) {
      debugPrint('Error setting equalizer enabled: $e');
      return false;
    }
  }

  static Future<List<double>> getFrequencyBands() async {
    try {
      if (!_isInitialized) return [];

      final result = await _channel.invokeMethod('getFrequencyBands');
      _frequencies = List<double>.from(result ?? []);
      return _frequencies;
    } catch (e) {
      debugPrint('Error getting frequency bands: $e');
      return [];
    }
  }

  static Future<List<double>> getCurrentGains() async {
    try {
      if (!_isInitialized) return [];

      final result = await _channel.invokeMethod('getCurrentGains');
      _gains = List<double>.from(result ?? []);
      return _gains;
    } catch (e) {
      debugPrint('Error getting current gains: $e');
      return [];
    }
  }

  static Future<bool> setBandGain(int band, double gain) async {
    try {
      if (!_isInitialized || band < 0 || band >= _frequencies.length) {
        return false;
      }

      final result = await _channel.invokeMethod('setBandGain', {
        'band': band,
        'gain': gain,
      });

      if (result ?? false) {
        if (_gains.length > band) {
          _gains[band] = gain;
        }
        _notifyEqualizerChange('bandGain', {'band': band, 'gain': gain});
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting band gain: $e');
      return false;
    }
  }

  static Future<bool> setAllGains(List<double> gains) async {
    try {
      if (!_isInitialized || gains.length != _frequencies.length) {
        return false;
      }

      final result = await _channel.invokeMethod('setAllGains', {
        'gains': gains,
      });

      if (result ?? false) {
        _gains = List.from(gains);
        _notifyEqualizerChange('allGains', gains);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting all gains: $e');
      return false;
    }
  }

  static Future<bool> setPreset(EqualizerPreset preset) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setPreset', {
        'name': preset.name,
        'gains': preset.gains,
      });

      if (result ?? false) {
        _currentPreset = preset;
        _gains = List.from(preset.gains);
        _notifyEqualizerChange('preset', preset.toJson());
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting preset: $e');
      return false;
    }
  }

  static Future<bool> setBassBoost(double boost) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setBassBoost', {
        'boost': boost,
      });

      if (result ?? false) {
        _notifyEqualizerChange('bassBoost', boost);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting bass boost: $e');
      return false;
    }
  }

  static Future<bool> setTrebleBoost(double boost) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setTrebleBoost', {
        'boost': boost,
      });

      if (result ?? false) {
        _notifyEqualizerChange('trebleBoost', boost);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting treble boost: $e');
      return false;
    }
  }

  static Future<bool> setVirtualizer(bool enabled) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setVirtualizer', {
        'enabled': enabled,
      });

      if (result ?? false) {
        _notifyEqualizerChange('virtualizer', enabled);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting virtualizer: $e');
      return false;
    }
  }

  static Future<bool> setLoudnessEnhancer(bool enabled) async {
    try {
      if (!_isInitialized) return false;

      final result = await _channel.invokeMethod('setLoudnessEnhancer', {
        'enabled': enabled,
      });

      if (result ?? false) {
        _notifyEqualizerChange('loudnessEnhancer', enabled);
      }

      return result ?? false;
    } catch (e) {
      debugPrint('Error setting loudness enhancer: $e');
      return false;
    }
  }

  static List<EqualizerPreset> getPresets() {
    return List.unmodifiable(_presets);
  }

  static EqualizerPreset? getCurrentPreset() {
    return _currentPreset;
  }

  static List<double> getFrequencies() {
    return List.unmodifiable(_frequencies);
  }

  static List<double> getGains() {
    return List.unmodifiable(_gains);
  }

  static Future<void> _loadDefaultPresets() async {
    _presets = [
      EqualizerPreset(
        name: 'Normal',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [0, 0, 0, 0, 0],
      ),
      EqualizerPreset(
        name: 'Classical',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [0, 0, 0, 0, 0],
      ),
      EqualizerPreset(
        name: 'Dance',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [5.0, 3.0, 0, 1.0, 5.0],
      ),
      EqualizerPreset(
        name: 'Flat',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [0, 0, 0, 0, 0],
      ),
      EqualizerPreset(
        name: 'Folk',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [3.0, 3.0, 0, -1.0, 1.0],
      ),
      EqualizerPreset(
        name: 'Heavy Metal',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [5.0, 3.0, 0, -4.0, -1.0],
      ),
      EqualizerPreset(
        name: 'Hip Hop',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [5.0, 2.5, 0, -1.0, 1.0],
      ),
      EqualizerPreset(
        name: 'Jazz',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [3.0, 2.0, 0, 2.0, 4.0],
      ),
      EqualizerPreset(
        name: 'Pop',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [-1.0, 2.5, 4.0, 4.5, 1.0],
      ),
      EqualizerPreset(
        name: 'Rock',
        frequencies: [60, 230, 910, 3600, 14000],
        gains: [5.0, 3.0, -1.0, 2.0, 4.0],
      ),
    ];
  }

  static Future<void> _getFrequencyBands() async {
    try {
      final bands = await _channel.invokeMethod('getFrequencyBands');
      if (bands != null) {
        _frequencies = List<double>.from(bands);
      } else {
        // Default frequency bands if not supported
        _frequencies = [60, 230, 910, 3600, 14000];
      }
      _gains = List.filled(_frequencies.length, 0.0);
    } catch (e) {
      debugPrint('Error getting frequency bands: $e');
      _frequencies = [60, 230, 910, 3600, 14000];
      _gains = List.filled(_frequencies.length, 0.0);
    }
  }

  static void _initializeEqualizerStream() {
    _equalizerController?.close();
    _equalizerController = StreamController<Map<String, dynamic>>.broadcast();

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onEqualizerEnabledChanged':
          final enabled = call.arguments['enabled'] ?? false;
          _isEnabled = enabled;
          _notifyEqualizerChange('enabled', enabled);
          break;
        case 'onBandGainChanged':
          final band = call.arguments['band'] ?? 0;
          final gain = call.arguments['gain'] ?? 0.0;
          if (_gains.length > band) {
            _gains[band] = gain;
          }
          _notifyEqualizerChange('bandGain', {'band': band, 'gain': gain});
          break;
      }
    });
  }

  static void _notifyEqualizerChange(String type, dynamic value) {
    _equalizerController?.add({
      'type': type,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> dispose() async {
    _equalizerController?.close();
    _equalizerController = null;
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
    _isEnabled = false;
    _currentPreset = null;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isCurrentlyEnabled => _isEnabled;
}
