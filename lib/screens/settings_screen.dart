import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/performance_service.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hardwareAcceleration = true;
  bool _autoPlayNext = false;
  bool _skipSilence = false;
  bool _loopVideo = false;
  bool _rememberPosition = true;
  bool _showSubtitles = true;
  String _playbackSpeed = '1.0';
  String _aspectRatio = 'fit';
  String _videoQuality = 'auto';
  String _subtitleLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Settings
            SettingsSection(
              title: 'Performance',
              icon: Icons.speed,
              children: [
                _buildSwitchSetting(
                  'Hardware Acceleration',
                  'Use GPU for video decoding',
                  _hardwareAcceleration,
                  (value) => setState(() => _hardwareAcceleration = value),
                ),
                _buildSwitchSetting(
                  'Auto Play Next',
                  'Automatically play next video',
                  _autoPlayNext,
                  (value) => setState(() => _autoPlayNext = value),
                ),
                _buildSwitchSetting(
                  'Skip Silence',
                  'Skip silent parts in videos',
                  _skipSilence,
                  (value) => setState(() => _skipSilence = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Playback Settings
            SettingsSection(
              title: 'Playback',
              icon: Icons.play_arrow,
              children: [
                _buildSwitchSetting(
                  'Loop Video',
                  'Repeat current video',
                  _loopVideo,
                  (value) => setState(() => _loopVideo = value),
                ),
                _buildSwitchSetting(
                  'Remember Position',
                  'Resume from last position',
                  _rememberPosition,
                  (value) => setState(() => _rememberPosition = value),
                ),
                _buildSwitchSetting(
                  'Show Subtitles',
                  'Display subtitles by default',
                  _showSubtitles,
                  (value) => setState(() => _showSubtitles = value),
                ),
                _buildDropdownSetting(
                  'Default Playback Speed',
                  _playbackSpeed,
                  ['0.25', '0.5', '0.75', '1.0', '1.25', '1.5', '2.0'],
                  (value) => setState(() => _playbackSpeed = value),
                ),
                _buildDropdownSetting(
                  'Default Aspect Ratio',
                  _aspectRatio,
                  ['fit', 'fill', 'stretch', '16:9', '4:3'],
                  (value) => setState(() => _aspectRatio = value),
                ),
                _buildDropdownSetting(
                  'Video Quality',
                  _videoQuality,
                  ['auto', '1080p', '720p', '480p', '360p'],
                  (value) => setState(() => _videoQuality = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Subtitle Settings
            SettingsSection(
              title: 'Subtitles',
              icon: Icons.subtitles,
              children: [
                _buildDropdownSetting(
                  'Subtitle Language',
                  _subtitleLanguage,
                  ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'ja', 'ko', 'zh'],
                  (value) => setState(() => _subtitleLanguage = value),
                ),
                _buildNavigationSetting(
                  'Subtitle Appearance',
                  'Customize subtitle style',
                  Icons.text_fields,
                  () => _showSubtitleAppearanceDialog(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Storage Settings
            SettingsSection(
              title: 'Storage',
              icon: Icons.storage,
              children: [
                _buildNavigationSetting(
                  'Clear Cache',
                  'Free up storage space',
                  Icons.delete_outline,
                  () => _showClearCacheDialog(),
                ),
                _buildNavigationSetting(
                  'Download Location',
                  'Change download folder',
                  Icons.folder,
                  () => _showDownloadLocationDialog(),
                ),
                _buildNavigationSetting(
                  'Storage Usage',
                  'View storage statistics',
                  Icons.storage_outlined,
                  () => _showStorageUsageDialog(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Device Info
            SettingsSection(
              title: 'Device Information',
              icon: Icons.info,
              children: [
                _buildInfoSetting(
                  'Device Performance',
                  PerformanceService.isLowEndDevice ? 'Low-end' : 'High-end',
                ),
                _buildInfoSetting('App Version', '1.0.0'),
                _buildInfoSetting('Build Number', '20240101'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[400], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSetting(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  void _showSubtitleAppearanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Subtitle Appearance',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Subtitle customization options will be available in the next update.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear all cached data? This will free up storage space but may slow down initial loading.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDownloadLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Download Location',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Download location settings will be available in the next update.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStorageUsageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Storage Usage',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cache: 125 MB', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text('Downloads: 2.3 GB', style: TextStyle(color: Colors.white)),
            SizedBox(height: 8),
            Text(
              'Total: 2.4 GB',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
