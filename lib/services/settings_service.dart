import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _subtitleSizeKey = 'subtitle_size';
  static const String _subtitleColorKey = 'subtitle_color';
  static const String _subtitleBackgroundColorKey = 'subtitle_background_color';
  static const String _subtitlePositionKey = 'subtitle_position';

  static Future<String> getSubtitleSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleSizeKey) ?? 'Medium';
  }

  static Future<void> setSubtitleSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleSizeKey, size);
  }

  static Future<String> getSubtitleColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleColorKey) ?? 'White';
  }

  static Future<void> setSubtitleColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleColorKey, color);
  }

  static Future<String> getSubtitleBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitleBackgroundColorKey) ?? 'None';
  }

  static Future<void> setSubtitleBackgroundColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitleBackgroundColorKey, color);
  }

  static Future<String> getSubtitlePosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subtitlePositionKey) ?? 'Bottom';
  }

  static Future<void> setSubtitlePosition(String position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subtitlePositionKey, position);
  }
}
