import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'about_screen.dart';
import '../services/theme_service.dart';
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
            // Theme Settings
            SettingsSection(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              children: [_buildThemeToggle()],
            ),

            const SizedBox(height: 24),

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
              ],
            ),

            const SizedBox(height: 24),

            // More Settings Navigation
            SettingsSection(
              title: 'Advanced',
              icon: Icons.tune,
              children: [
                _buildNavigationSetting(
                  'File Browser',
                  'Browse media files with advanced options',
                  Icons.folder_open,
                  () {
                    Navigator.of(context).pushNamed('/next-browser');
                  },
                ),
                _buildNavigationSetting(
                  'Playback Tuning',
                  'Finetune skip duration and gestures',
                  Icons.slow_motion_video,
                  () {},
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

            // Information & About
            SettingsSection(
              title: 'Information',
              icon: Icons.info_outline,
              children: [
                _buildNavigationSetting(
                  'About NEXT PLAYER',
                  'Version, updates, and more',
                  Icons.help_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildNavigationSetting(
                  'Privacy Policy',
                  'How we handle your data',
                  Icons.privacy_tip_outlined,
                  () => _showPrivacyPolicy(context),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark
                      ? 'Currently using Dark theme'
                      : 'Switch to Dark theme',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (v) {
              ref
                  .read(themeModeProvider.notifier)
                  .setTheme(v ? ThemeMode.dark : ThemeMode.light);
            },
            activeThumbColor: Colors.red,
          ),
        ],
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

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'All your private videos and passwords are stored locally on your device. We do not collect or share any personal data.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
