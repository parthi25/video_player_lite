import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlayVideos = true;
  bool _generateThumbnails = true;
  bool _showVideoDetails = true;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoPlayVideos = prefs.getBool('auto_play_videos') ?? true;
      _generateThumbnails = prefs.getBool('generate_thumbnails') ?? true;
      _showVideoDetails = prefs.getBool('show_video_details') ?? true;
      final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_play_videos', _autoPlayVideos);
    await prefs.setBool('generate_thumbnails', _generateThumbnails);
    await prefs.setBool('show_video_details', _showVideoDetails);
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Playback', [
            SwitchListTile(
              title: const Text('Auto-play videos'),
              subtitle: const Text(
                'Start playing videos automatically when opened',
              ),
              value: _autoPlayVideos,
              onChanged: (value) {
                setState(() => _autoPlayVideos = value);
                _saveSettings();
              },
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Display', [
            SwitchListTile(
              title: const Text('Generate thumbnails'),
              subtitle: const Text('Create preview images for videos'),
              value: _generateThumbnails,
              onChanged: (value) {
                setState(() => _generateThumbnails = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Show video details'),
              subtitle: const Text(
                'Display file size, duration, and resolution',
              ),
              value: _showVideoDetails,
              onChanged: (value) {
                setState(() => _showVideoDetails = value);
                _saveSettings();
              },
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Appearance', [
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_getThemeModeText(_themeMode)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showThemeDialog,
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('Storage', [
            ListTile(
              title: const Text('Clear cache'),
              subtitle: const Text(
                'Remove generated thumbnails and temporary files',
              ),
              trailing: const Icon(Icons.delete_outline),
              onTap: _clearCache,
            ),
            ListTile(
              title: const Text('Clear favorites'),
              subtitle: const Text('Remove all favorite videos'),
              trailing: const Icon(Icons.favorite_border),
              onTap: _clearFavorites,
            ),
          ]),

          const SizedBox(height: 24),

          _buildSection('About', [
            const ListTile(
              title: Text('Version'),
              subtitle: Text('1.0.0'),
              trailing: Icon(Icons.info_outline),
            ),
            ListTile(
              title: const Text('Licenses'),
              subtitle: const Text('View open source licenses'),
              trailing: const Icon(Icons.description_outlined),
              onTap: () => showLicensePage(context: context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return ListTile(
              title: Text(_getThemeModeText(mode)),
              leading: Icon(
                _themeMode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _themeMode == mode
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onTap: () {
                setState(() => _themeMode = mode);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text(
          'This will remove all generated thumbnails. They will be recreated when needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

                try {
                  // Get cache directory
                  final cacheDir = await getTemporaryDirectory();
                  int deletedCount = 0;

                  // Delete thumbnail files (typically JPEG files in cache)
                  try {
                    if (await cacheDir.exists()) {
                      try {
                        await for (final entity in cacheDir.list()) {
                          if (entity is File) {
                            try {
                              final extension = entity.path
                                  .split('.')
                                  .last
                                  .toLowerCase();
                              // Delete common image formats used for thumbnails
                              if (extension == 'jpg' ||
                                  extension == 'jpeg' ||
                                  extension == 'png') {
                                try {
                                  await entity.delete();
                                  deletedCount++;
                                } catch (e) {
                                  debugPrint(
                                    'Error deleting cache file ${entity.path}: $e',
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint(
                                'Error processing cache entity ${entity.path}: $e',
                              );
                            }
                          }
                        }
                      } catch (e) {
                        debugPrint('Error listing cache directory: $e');
                      }
                    }
                  } catch (e) {
                    debugPrint('Error accessing cache directory: $e');
                  }

                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      deletedCount > 0
                          ? 'Cache cleared ($deletedCount files deleted)'
                          : 'Cache cleared (no files found)',
                    ),
                  ),
                );
              } catch (e) {
                debugPrint('Error clearing cache: $e');
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Error clearing cache')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear favorites'),
        content: const Text(
          'This will remove all videos from your favorites list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (!mounted) return;
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('favorite_videos');
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Favorites cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
