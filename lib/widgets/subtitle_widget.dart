import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../services/subtitle_service.dart';

class SubtitleWidget extends ConsumerWidget {
  const SubtitleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final currentSubtitle = SubtitleService.getCurrentSubtitle(
      videoState.position,
    );

    if (currentSubtitle == null || currentSubtitle.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 100, // Position above controls
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          currentSubtitle.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class SubtitleControlPanel extends ConsumerWidget {
  final List<SubtitleTrack> availableTracks;
  final SubtitleTrack? currentTrack;
  final Function(SubtitleTrack?) onTrackSelected;
  final bool isVisible;

  const SubtitleControlPanel({
    super.key,
    required this.availableTracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.subtitles, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Subtitles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => onTrackSelected(null),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Subtitle list
            if (availableTracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No subtitles found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              // None option
              ListTile(
                leading: const Icon(Icons.subtitles_off, color: Colors.grey),
                title: const Text('None'),
                trailing: currentTrack == null
                    ? const Icon(Icons.check, color: Colors.red)
                    : null,
                onTap: () => onTrackSelected(null),
              ),

              const Divider(height: 1, color: Color(0xFF3A3A3A)),

              // Available tracks
              ...availableTracks.map(
                (track) => Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        child: Text(
                          _getLanguageFlag(track.language),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      title: Text(track.label),
                      subtitle: Text(_getLanguageName(track.language)),
                      trailing: currentTrack?.path == track.path
                          ? const Icon(Icons.check, color: Colors.red)
                          : null,
                      onTap: () => onTrackSelected(track),
                    ),
                    if (track != availableTracks.last)
                      const Divider(height: 1, color: Color(0xFF3A3A3A)),
                  ],
                ),
              ),

              // Download option
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Download Subtitles'),
                subtitle: const Text('Search online for subtitles'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDownloadDialog(context, ref);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLanguageFlag(String language) {
    final flags = {
      'en': '🇺🇸',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'ja': '🇯🇵',
      'ko': '🇰🇷',
      'zh': '🇨🇳',
      'ar': '🇸🇦',
      'hi': '🇮🇳',
      'th': '🇹🇭',
      'vi': '🇻🇳',
    };
    return flags[language] ?? '🌐';
  }

  String _getLanguageName(String language) {
    final names = SubtitleService.getLanguageCodes();
    return names[language] ?? language;
  }

  void _showDownloadDialog(BuildContext context, WidgetRef ref) {
    final languages = SubtitleService.getLanguageCodes();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Subtitles'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final entry = languages.entries.elementAt(index);
              return ListTile(
                leading: Text(_getLanguageFlag(entry.key)),
                title: Text(entry.value),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement subtitle download
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading ${entry.value} subtitles...'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SubtitleSettingsWidget extends ConsumerWidget {
  const SubtitleSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subtitle Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Font size
          _buildSettingItem(
            'Font Size',
            'Medium',
            Icons.format_size,
            () => _showFontSizeDialog(context, ref),
          ),

          const SizedBox(height: 12),

          // Font color
          _buildSettingItem(
            'Font Color',
            'White',
            Icons.palette,
            () => _showFontColorDialog(context, ref),
          ),

          const SizedBox(height: 12),

          // Background
          _buildSettingItem(
            'Background',
            'Semi-transparent',
            Icons.format_color_fill,
            () => _showBackgroundDialog(context, ref),
          ),

          const SizedBox(height: 12),

          // Position
          _buildSettingItem(
            'Position',
            'Bottom',
            Icons.vertical_align_bottom,
            () => _showPositionDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    final sizes = ['Small', 'Medium', 'Large', 'Extra Large'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizes
              .map(
                (size) => RadioListTile<String>(
                  title: Text(size),
                  value: size,
                  selected: 'Medium' == size, // TODO: Get from settings
                  toggleable: true,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showFontColorDialog(BuildContext context, WidgetRef ref) {
    final colors = ['White', 'Yellow', 'Cyan', 'Green'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: colors
              .map(
                (color) => RadioListTile<String>(
                  title: Text(color),
                  value: color,
                  selected: 'White' == color, // TODO: Get from settings
                  toggleable: true,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showBackgroundDialog(BuildContext context, WidgetRef ref) {
    final backgrounds = ['None', 'Semi-transparent', 'Black'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: backgrounds
              .map(
                (bg) => RadioListTile<String>(
                  title: Text(bg),
                  value: bg,
                  selected: 'Semi-transparent' == bg, // TODO: Get from settings
                  toggleable: true,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showPositionDialog(BuildContext context, WidgetRef ref) {
    final positions = ['Top', 'Center', 'Bottom'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: positions
              .map(
                (pos) => RadioListTile<String>(
                  title: Text(pos),
                  value: pos,
                  selected: 'Bottom' == pos, // TODO: Get from settings
                  toggleable: true,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
