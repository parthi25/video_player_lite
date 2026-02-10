import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'about_screen.dart';
import 'scan_directories_settings_screen.dart';
import '../services/theme_service.dart';
import '../services/performance_service.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Performance State
  late bool _hwDecoding;
  late bool _frameDrop;
  late bool _skipLoopFilter;

  // App State
  bool _skipSilence = false;

  @override
  void initState() {
    super.initState();
    // Load initial values from service
    _hwDecoding = PerformanceService.isHardwareDecodingEnabled;
    _frameDrop = PerformanceService.isFrameDropEnabled;
    _skipLoopFilter = PerformanceService.isSkipLoopFilterEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section (Card Style)
            _buildThemeSection(theme),
            const SizedBox(height: 24),

            // Performance Settings (Functional)
            SettingsSection(
              title: 'Playback & Performance',
              icon: Icons.speed_rounded,
              children: [
                _buildSwitchSetting(
                  'Hardware Acceleration',
                  'Use GPU for smooth video decoding',
                  _hwDecoding,
                  (value) {
                    setState(() => _hwDecoding = value);
                    PerformanceService.setHardwareDecoding(value);
                  },
                ),
                _buildSwitchSetting(
                  'Frame Drop',
                  'Skip frames to prevent audio lag',
                  _frameDrop,
                  (value) {
                    setState(() => _frameDrop = value);
                    PerformanceService.setFrameDrop(value);
                  },
                ),
                _buildSwitchSetting(
                  'Speedup Mode (Skip Filter)',
                  'Disable deblocking for max speed (Low quality)',
                  _skipLoopFilter,
                  (value) {
                    setState(() => _skipLoopFilter = value);
                    PerformanceService.setSkipLoopFilter(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Advanced Navigation
            SettingsSection(
              title: 'Advanced Features',
              icon: Icons.tune_rounded,
              children: [
                _buildNavigationSetting(
                  'Scan Directories',
                  'Manage folders for video scanning',
                  Icons.folder_special,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ScanDirectoriesSettingsScreen(),
                    ),
                  ),
                ),
                _buildNavigationSetting(
                  'File Browser',
                  'Manage folders and view hidden files',
                  Icons.folder_open_rounded,
                  () => Navigator.of(context).pushNamed('/next-browser'),
                ),
                _buildSwitchSetting(
                  'Skip Silence',
                  'Automatically skip silent parts',
                  _skipSilence,
                  (value) => setState(() => _skipSilence = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Section
            SettingsSection(
              title: 'About',
              icon: Icons.info_outline_rounded,
              children: [
                _buildNavigationSetting(
                  'About Parthi Play',
                  'Version 1.0.0 • Build 2024',
                  Icons.android,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  ),
                ),
                _buildNavigationSetting(
                  'Privacy Policy',
                  'Local storage only. No tracking.',
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

  Widget _buildThemeSection(ThemeData theme) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_rounded, color: Colors.purple),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    'Customize app look',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildThemeCard(
                  'Light',
                  Icons.wb_sunny_rounded,
                  !isDark,
                  () => ref
                      .read(themeModeProvider.notifier)
                      .setTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeCard(
                  'Dark',
                  Icons.nightlight_round,
                  isDark,
                  () => ref
                      .read(themeModeProvider.notifier)
                      .setTheme(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.red : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
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
    final theme = Theme.of(context);
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
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.red,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We respect your privacy. All your private videos, passwords, and playback history are stored strictly locally on your device.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '• No data upload to servers.\n• No tracking or analytics.\n• Offline-first design.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
