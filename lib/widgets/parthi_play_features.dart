import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../widgets/subtitle_selection_widget.dart';

class ParthiPlayFeatures extends ConsumerStatefulWidget {
  const ParthiPlayFeatures({super.key});

  @override
  ConsumerState<ParthiPlayFeatures> createState() =>
      _ParthiPlayFeaturesState();
}

class _ParthiPlayFeaturesState extends ConsumerState<ParthiPlayFeatures> {
  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final videoController = ref.read(videoPlayerControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Colors.red),
                const SizedBox(width: 12),
                const Text(
                  'Parthi Play Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Settings options
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Playback Speed
                _buildSettingTile(
                  icon: Icons.speed,
                  title: 'Playback Speed',
                  subtitle: '${videoState.playbackSpeed}x',
                  onTap: () => _showSpeedSelection(videoController),
                ),

                // Aspect Ratio
                _buildSettingTile(
                  icon: Icons.aspect_ratio,
                  title: 'Aspect Ratio',
                  subtitle: videoState.aspectRatioMode.label,
                  onTap: () => _showAspectRatioSelection(videoController),
                ),

                // Audio Track
                _buildSettingTile(
                  icon: Icons.audiotrack,
                  title: 'Audio Track',
                  subtitle: videoState.audioTrackIndex >= 0 && videoState.audioTracks.isNotEmpty
                      ? videoState.audioTracks[videoState.audioTrackIndex].displayName
                      : 'Default',
                  onTap: () => _showAudioTrackSelection(videoController),
                ),

                // Subtitle
                _buildSettingTile(
                  icon: Icons.subtitles,
                  title: 'Subtitle',
                  subtitle: videoState.subtitlePath != null
                      ? 'Enabled'
                      : 'Disabled',
                  onTap: () => _showSubtitleSelection(),
                ),

                // Screen Lock
                _buildSettingTile(
                  icon: videoState.isLocked ? Icons.lock : Icons.lock_open,
                  title: 'Screen Lock',
                  subtitle: videoState.isLocked ? 'Locked' : 'Unlocked',
                  onTap: () => videoController.toggleLock(),
                ),

                // Fullscreen
                _buildSettingTile(
                  icon: Icons.fullscreen,
                  title: 'Fullscreen',
                  subtitle: videoState.isFullscreen ? 'Enabled' : 'Disabled',
                  onTap: () => videoController.toggleFullscreen(),
                ),

                // Picture-in-Picture
                _buildSettingTile(
                  icon: Icons.picture_in_picture,
                  title: 'Picture-in-Picture',
                  subtitle: 'Floating window mode',
                  onTap: () => _showPiPSettings(),
                ),

                // Background Playback
                _buildSettingTile(
                  icon: Icons.headphones,
                  title: 'Background Playback',
                  subtitle: 'Play audio in background',
                  onTap: () => _showBackgroundSettings(),
                ),

                // Audio Equalizer
                _buildSettingTile(
                  icon: Icons.equalizer,
                  title: 'Audio Equalizer',
                  subtitle: 'Sound enhancement',
                  onTap: () => _showEqualizerSettings(),
                ),

                // Video Tools
                _buildSettingTile(
                  icon: Icons.video_settings,
                  title: 'Video Tools',
                  subtitle: 'Trim, compress, edit',
                  onTap: () => _showVideoTools(),
                ),

                // Casting
                _buildSettingTile(
                  icon: Icons.cast,
                  title: 'Cast to TV',
                  subtitle: 'Chromecast & DLNA',
                  onTap: () => _showCastingSettings(),
                ),

                // Subtitle Downloader
                _buildSettingTile(
                  icon: Icons.download,
                  title: 'Download Subtitles',
                  subtitle: 'Online subtitle search',
                  onTap: () => _showSubtitleDownloader(),
                ),

                // Metadata Editor
                _buildSettingTile(
                  icon: Icons.edit,
                  title: 'Edit Metadata',
                  subtitle: 'Video information editor',
                  onTap: () => _showMetadataEditor(),
                ),

                // Advanced Settings
                _buildSettingTile(
                  icon: Icons.tune,
                  title: 'Advanced',
                  subtitle: 'Equalizer, Decoder, etc.',
                  onTap: () => _showAdvancedSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Colors.red, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 15),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showSpeedSelection(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map(
                      (speed) => ListTile(
                        title: Text(
                          '${speed}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          videoController.setPlaybackSpeed(speed);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAspectRatioSelection(
    VideoPlayerControllerNotifier videoController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Aspect Ratio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: AspectRatioMode.values
                    .map(
                      (mode) => ListTile(
                        title: Text(
                          mode.label,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing:
                            ref
                                    .read(videoPlayerControllerProvider)
                                    .aspectRatioMode ==
                                mode
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () {
                          videoController.setAspectRatio(mode);
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioTrackSelection(VideoPlayerControllerNotifier videoController) {
    final videoState = ref.read(videoPlayerControllerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Audio Track',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Default track option
                  ListTile(
                    title: const Text(
                      'Default Track',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'System default audio track',
                      style: TextStyle(color: Color(0xFFBDBDBD)),
                    ),
                    leading: const Icon(Icons.audiotrack, color: Colors.white),
                    onTap: () {
                      videoController.setAudioTrack(null);
                      Navigator.of(context).pop();
                    },
                  ),
                  // Dynamic audio tracks
                  ...videoState.audioTracks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final track = entry.value;
                    return ListTile(
                      title: Text(
                        track.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${track.language}${track.codec != null ? ' • ${track.codec}' : ''}${track.channels != null ? ' • ${track.channels}ch' : ''}',
                        style: const TextStyle(color: Color(0xFFBDBDBD)),
                      ),
                      leading: const Icon(
                        Icons.audiotrack,
                        color: Colors.white,
                      ),
                      trailing: videoState.audioTrackIndex == index
                          ? const Icon(Icons.check, color: Colors.red)
                          : null,
                      onTap: () {
                        videoController.setAudioTrack(index);
                        Navigator.of(context).pop();
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubtitleSelection() {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final videoPath = videoState.videoPath;

    if (videoPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No video loaded')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubtitleSelectionWidget(
        videoPath: videoPath,
        onSubtitleSelected: () {
          // Subtitle selected, the controller will handle loading
        },
      ),
    );
  }

  void _showAdvancedSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Advanced Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildAdvancedTile('Equalizer', 'Audio enhancement'),
                  _buildAdvancedTile(
                    'Hardware Decoder',
                    'Use hardware acceleration',
                  ),
                  _buildAdvancedTile(
                    'Software Decoder',
                    'Use software decoding',
                  ),
                  _buildAdvancedTile('Skip Silence', 'Skip silent parts'),
                  _buildAdvancedTile('Loop Video', 'Repeat playback'),
                  _buildAdvancedTile(
                    'Picture-in-Picture',
                    'Floating window mode',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedTile(String title, String subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Color(0xFFBDBDBD))),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title coming soon')));
      },
    );
  }

  void _showPiPSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Picture-in-Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Enable PiP',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Floating video window',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PiP feature coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'PiP Settings',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Configure PiP behavior',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PiP settings coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackgroundSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Background Playback',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Enable Background',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Play audio in background',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Background playback coming soon'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Audio Only Mode',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Background audio settings',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio settings coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEqualizerSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Audio Equalizer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Enable Equalizer',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Sound enhancement',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equalizer coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Presets',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Equalizer presets',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Presets coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Custom EQ',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Manual equalizer',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom EQ coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoTools() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Trim Video',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Cut video segments',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video trimmer coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Compress Video',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Reduce file size',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video compression coming soon'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Convert Format',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Change video format',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Format converter coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Extract Audio',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Save audio separately',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio extraction coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCastingSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cast to TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Scan Devices',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Find casting devices',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device scanning coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Chromecast',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Cast to Chromecast',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chromecast support coming soon'),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('DLNA', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Cast to DLNA devices',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('DLNA support coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubtitleDownloader() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download Subtitles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Search Online',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Find subtitles online',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subtitle search coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Auto Match',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatic subtitle matching',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto matching coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Language Settings',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Preferred languages',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language settings coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMetadataEditor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Metadata',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Edit Info',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Title, artist, genre',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Metadata editor coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Thumbnail',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Change video thumbnail',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thumbnail editor coming soon')),
                );
              },
            ),
            ListTile(
              title: const Text(
                'Technical Info',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'View video details',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Technical info coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
