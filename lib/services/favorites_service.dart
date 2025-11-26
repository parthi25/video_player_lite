import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_videos';
  static FavoritesService? _instance;
  static FavoritesService get instance => _instance ??= FavoritesService._();
  
  FavoritesService._();

  Future<Set<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      return favoritesJson.toSet();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return <String>{};
    }
  }

  Future<void> addFavorite(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      favorites.add(videoPath);
      await prefs.setStringList(_favoritesKey, favorites.toList());
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      favorites.remove(videoPath);
      await prefs.setStringList(_favoritesKey, favorites.toList());
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(String videoPath) async {
    try {
      final favorites = await getFavorites();
      return favorites.contains(videoPath);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String videoPath) async {
    try {
      if (await isFavorite(videoPath)) {
        await removeFavorite(videoPath);
      } else {
        await addFavorite(videoPath);
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }
}