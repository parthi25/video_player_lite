import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class Preferences {
  static const String _favoritesKey = 'favorite_videos';

  static Future<List<VideoModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson
        .map((json) => VideoModel.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> addToFavorites(VideoModel video) async {
    final favorites = await getFavorites();
    if (!favorites.any((v) => v.path == video.path)) {
      favorites.add(video);
      await _saveFavorites(favorites);
    }
  }

  static Future<void> removeFromFavorites(String path) async {
    final favorites = await getFavorites();
    favorites.removeWhere((v) => v.path == path);
    await _saveFavorites(favorites);
  }

  static Future<void> toggleFavorite(VideoModel video) async {
    if (video.isFavorite) {
      await removeFromFavorites(video.path);
    } else {
      await addToFavorites(video);
    }
    video.isFavorite = !video.isFavorite;
  }

  static Future<void> _saveFavorites(List<VideoModel> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = favorites.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }
}
