import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _subtitleSizeKey = 'subtitle_size';
  static const String _subtitleColorKey = 'subtitle_color';
  static const String _subtitleBackgroundColorKey = 'subtitle_background_color';
  static const String _subtitlePositionKey = 'subtitle_position';
  static const String _doubleTapSeekKey = 'double_tap_seek_seconds';
  static const String _rewindSpeedKey = 'rewind_speed';
  static const String _holdForwardSpeedKey = 'hold_forward_speed';
  static const String _holdRewindSpeedKey = 'hold_rewind_speed';
  static const String _backgroundPlayKeyAndroid =
      'background_play_enabled_android';
  static const String _backgroundPlayKeyIOS = 'background_play_enabled_ios';

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static Future<String> getSubtitleSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleSizeKey) ?? 'Medium';
  }

  static Future<void> setSubtitleSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleSizeKey, size);
    _changes.add(null);
  }

  static Future<String> getSubtitleColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleColorKey) ?? 'White';
  }

  static Future<void> setSubtitleColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleColorKey, color);
    _changes.add(null);
  }

  static Future<String> getSubtitleBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleBackgroundColorKey) ?? 'None';
  }

  static Future<void> setSubtitleBackgroundColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleBackgroundColorKey, color);
    _changes.add(null);
  }

  static Future<String> getSubtitlePosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitlePositionKey) ?? 'Bottom';
  }

  static Future<void> setSubtitlePosition(String position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitlePositionKey, position);
    _changes.add(null);
  }

  static Future<int> getDoubleTapSeekSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_doubleTapSeekKey) ?? 10;
  }

  static Future<void> setDoubleTapSeekSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_doubleTapSeekKey, seconds);
    _changes.add(null);
  }

  static Future<double> getRewindSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rewindSpeedKey) ?? 2.0;
  }

  static Future<void> setRewindSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rewindSpeedKey, speed);
    _changes.add(null);
  }

  static Future<double> getHoldForwardSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final forward = prefs.getDouble(_holdForwardSpeedKey);
    if (forward != null) return forward;
    return prefs.getDouble(_rewindSpeedKey) ?? 2.0;
  }

  static Future<void> setHoldForwardSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_holdForwardSpeedKey, speed);
    _changes.add(null);
  }

  static Future<double> getHoldRewindSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final rewind = prefs.getDouble(_holdRewindSpeedKey);
    if (rewind != null) return rewind;
    return prefs.getDouble(_rewindSpeedKey) ?? 2.0;
  }

  static Future<void> setHoldRewindSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_holdRewindSpeedKey, speed);
    _changes.add(null);
  }

  static Future<bool> getBackgroundPlaybackEnabled({
    required bool isIOS,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isIOS ? _backgroundPlayKeyIOS : _backgroundPlayKeyAndroid;
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setBackgroundPlaybackEnabled(
    bool enabled, {
    required bool isIOS,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isIOS ? _backgroundPlayKeyIOS : _backgroundPlayKeyAndroid;
    await prefs.setBool(key, enabled);
    _changes.add(null);
  }
}
