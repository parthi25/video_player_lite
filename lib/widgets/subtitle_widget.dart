import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../services/subtitle_service.dart';
import '../services/settings_service.dart';

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
  final Function(String)? onLanguageSelected;

  const SubtitleControlPanel({
    super.key,
    required this.availableTracks,
    required this.currentTrack,
    required this.onTrackSelected,
    required this.isVisible,
    this.onLanguageSelected,
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
                  _showDownloadDialog(
                    context,
                    ref,
                    onLanguageSelected: (language) {
                      // Create a new subtitle track from the downloaded file
                      final videoState = ref.read(
                        videoPlayerControllerProvider,
                      );
                      if (videoState.videoPath != null) {
                        final subtitlePath =
                            '${videoState.videoPath!.substring(0, videoState.videoPath!.lastIndexOf('.'))}_$language.srt';
                        final newTrack = SubtitleTrack(
                          path: subtitlePath,
                          language: language,
                          label: _getLanguageName(language),
                          flag: _getLanguageFlag(language),
                        );
                        onTrackSelected(newTrack);
                      }
                    },
                  );
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

  void _showDownloadDialog(
    BuildContext context,
    WidgetRef ref, {
    Function(String)? onLanguageSelected,
  }) {
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
                onTap: () async {
                  Navigator.of(context).pop();
                  final videoState = ref.read(videoPlayerControllerProvider);
                  if (videoState.videoPath != null) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading subtitles...')),
                    );

                    final downloadedPath =
                        await SubtitleService.downloadSubtitle(
                          videoState.videoPath!,
                          entry.key,
                        );

                    if (!context.mounted) return;

                    if (downloadedPath != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Subtitle downloaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      onLanguageSelected?.call(entry.key);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to download subtitle'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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

          // Subtitle size
          const Text(
            'Subtitle Size',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder<String>(
                future: SettingsService.getSubtitleSize(),
                builder: (context, snapshot) {
                  final currentSize = snapshot.data ?? 'Medium';
                  final sizes = ['Small', 'Medium', 'Large'];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: sizes
                        .map(
                          (size) => GestureDetector(
                            onTap: () {
                              SettingsService.setSubtitleSize(size);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: currentSize == size
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: currentSize == size
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    currentSize == size
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: currentSize == size
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    size,
                                    style: TextStyle(
                                      color: currentSize == size
                                          ? Colors.blue
                                          : Colors.white,
                                      fontWeight: currentSize == size
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12),

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
    final sizes = ['Small', 'Medium', 'Large'];
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: SettingsService.getSubtitleSize(),
        builder: (context, snapshot) {
          final currentSize = snapshot.data ?? 'Medium';
          return AlertDialog(
            title: const Text('Font Size'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: sizes
                      .map(
                        (size) => GestureDetector(
                          onTap: () {
                            SettingsService.setSubtitleSize(size);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: currentSize == size
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentSize == size
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentSize == size
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentSize == size
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  size,
                                  style: TextStyle(
                                    color: currentSize == size
                                        ? Colors.blue
                                        : Colors.white,
                                    fontWeight: currentSize == size
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showFontColorDialog(BuildContext context, WidgetRef ref) {
    final colors = ['White', 'Yellow', 'Cyan', 'Green'];

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: SettingsService.getSubtitleColor(),
        builder: (context, snapshot) {
          final currentColor = snapshot.data ?? 'White';
          return AlertDialog(
            title: const Text('Font Color'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: colors
                      .map(
                        (color) => GestureDetector(
                          onTap: () {
                            SettingsService.setSubtitleColor(color);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: currentColor == color
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentColor == color
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentColor == color
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentColor == color
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  color,
                                  style: TextStyle(
                                    color: currentColor == color
                                        ? Colors.blue
                                        : Colors.white,
                                    fontWeight: currentColor == color
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showBackgroundDialog(BuildContext context, WidgetRef ref) {
    final backgrounds = ['None', 'Semi-transparent', 'Black'];

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: SettingsService.getSubtitleBackgroundColor(),
        builder: (context, snapshot) {
          final currentBg = snapshot.data ?? 'Semi-transparent';
          return AlertDialog(
            title: const Text('Background'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: backgrounds
                      .map(
                        (bg) => GestureDetector(
                          onTap: () {
                            SettingsService.setSubtitleBackgroundColor(bg);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: currentBg == bg
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentBg == bg
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentBg == bg
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentBg == bg
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  bg,
                                  style: TextStyle(
                                    color: currentBg == bg
                                        ? Colors.blue
                                        : Colors.white,
                                    fontWeight: currentBg == bg
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showPositionDialog(BuildContext context, WidgetRef ref) {
    final positions = ['Top', 'Center', 'Bottom'];

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
        future: SettingsService.getSubtitlePosition(),
        builder: (context, snapshot) {
          final currentPos = snapshot.data ?? 'Bottom';
          return AlertDialog(
            title: const Text('Position'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: positions
                      .map(
                        (pos) => GestureDetector(
                          onTap: () {
                            SettingsService.setSubtitlePosition(pos);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: currentPos == pos
                                  ? Colors.blue.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: currentPos == pos
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentPos == pos
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: currentPos == pos
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  pos,
                                  style: TextStyle(
                                    color: currentPos == pos
                                        ? Colors.blue
                                        : Colors.white,
                                    fontWeight: currentPos == pos
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
