import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';

class NextPlayerControls extends ConsumerWidget {
  const NextPlayerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final videoController = ref.read(videoPlayerControllerProvider.notifier);

    if (!videoState.showControls || videoState.isLocked) {
      return const SizedBox.shrink();
    }

    // Use RepaintBoundary to isolate repaints
    return RepaintBoundary(
      child: AnimatedOpacity(
        opacity: videoState.showControls ? 1.0 : 0.0,
        duration: const Duration(
          milliseconds: 200,
        ), // Reduced duration for better performance
        child: Stack(
          children: [
            // Top controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopControls(
                context,
                ref,
                videoState,
                videoController,
              ),
            ),

            // Center play button - only show when controls are visible
            if (videoState.showControls)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildCenterPlayButton(
                  context,
                  ref,
                  videoState,
                  videoController,
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(
                context,
                ref,
                videoState,
                videoController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState videoState,
    dynamic videoController,
  ) {
    return SafeArea(
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            const SizedBox(width: 4),

            // Video title (placeholder) - Use Flexible to prevent overflow
            Flexible(
              child: Text(
                'MX Player',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // Lock button
            IconButton(
              onPressed: videoController.toggleLock,
              icon: Icon(
                videoState.isLocked ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),

            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
              onSelected: (value) =>
                  _handleMenuAction(value, ref, videoController),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'speed',
                  child: Row(
                    children: [
                      Icon(Icons.speed, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Playback Speed'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'aspect_ratio',
                  child: Row(
                    children: [
                      Icon(Icons.aspect_ratio, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Aspect Ratio'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'subtitle',
                  child: Row(
                    children: [
                      Icon(Icons.subtitles, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Subtitles'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'audio_track',
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text('Audio Track'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState videoState,
    dynamic videoController,
  ) {
    return Center(
      child: GestureDetector(
        onTap: videoController.togglePlayPause,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Icon(
            videoState.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState videoState,
    dynamic videoController,
  ) {
    return SafeArea(
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Progress bar
            _buildProgressBar(context, ref, videoState, videoController),

            const SizedBox(height: 6),

            // Control buttons and time
            Row(
              children: [
                // Current time
                Flexible(
                  child: Text(
                    _formatDuration(videoState.position),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Play/Pause button
                IconButton(
                  onPressed: videoController.togglePlayPause,
                  icon: Icon(
                    videoState.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const SizedBox(width: 4),

                // Previous button (placeholder)
                IconButton(
                  onPressed: () {
                    // TODO: Implement previous video
                  },
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                // Next button (placeholder)
                IconButton(
                  onPressed: () {
                    // TODO: Implement next video
                  },
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const Spacer(),

                // Volume button
                IconButton(
                  onPressed: () {
                    _showVolumeDialog(context, ref, videoController);
                  },
                  icon: const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const SizedBox(width: 4),

                // Subtitle button
                IconButton(
                  onPressed: () {
                    _showSubtitleDialog(context, ref, videoController);
                  },
                  icon: Icon(
                    videoState.subtitlePath != null
                        ? Icons.subtitles
                        : Icons.subtitles_outlined,
                    color: videoState.subtitlePath != null
                        ? Colors.red
                        : Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const SizedBox(width: 4),

                // Settings button
                IconButton(
                  onPressed: () {
                    _showSettingsDialog(context, ref, videoController);
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const SizedBox(width: 4),

                // Fullscreen button
                IconButton(
                  onPressed: videoController.toggleFullscreen,
                  icon: Icon(
                    videoState.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),

                const SizedBox(width: 8),

                // Total time
                Flexible(
                  child: Text(
                    _formatDuration(videoState.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState videoState,
    dynamic videoController,
  ) {
    final position = videoState.position.inMilliseconds.toDouble();
    final duration = videoState.duration.inMilliseconds.toDouble();
    final progress = duration > 0 ? position / duration : 0.0;

    return SizedBox(
      height: 4,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.red,
          overlayColor: Colors.transparent,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          trackHeight: 4,
        ),
        child: Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: (value) {
            final newPosition = value * duration;
            videoController.seekTo(Duration(milliseconds: newPosition.round()));
          },
        ),
      ),
    );
  }

  void _handleMenuAction(String value, WidgetRef ref, dynamic videoController) {
    switch (value) {
      case 'speed':
        _showPlaybackSpeedDialog(ref.context, ref, videoController);
        break;
      case 'aspect_ratio':
        _showAspectRatioDialog(ref.context, ref, videoController);
        break;
      case 'subtitle':
        _showSubtitleDialog(ref.context, ref, videoController);
        break;
      case 'audio_track':
        _showAudioTrackDialog(ref.context, ref, videoController);
        break;
    }
  }

  void _showPlaybackSpeedDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: speeds.length,
            itemBuilder: (context, index) {
              final speed = speeds[index];
              final videoState = ref.watch(videoPlayerControllerProvider);
              final isSelected = videoState.playbackSpeed == speed;

              return ListTile(
                title: Text('${speed}x'),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.red)
                    : null,
                onTap: () {
                  videoController.setPlaybackSpeed(speed);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAspectRatioDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    final ratios = ['fit', 'fill', 'stretch', '16:9', '4:3'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aspect Ratio'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ratios.length,
            itemBuilder: (context, index) {
              final ratio = ratios[index];
              final videoState = ref.watch(videoPlayerControllerProvider);
              final isSelected = videoState.aspectRatio == ratio;

              return ListTile(
                title: Text(ratio.toUpperCase()),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.red)
                    : null,
                onTap: () {
                  videoController.setAspectRatio(ratio);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showVolumeDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    final videoState = ref.watch(videoPlayerControllerProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Slider(
              value: videoState.volume,
              onChanged: (value) {
                videoController.setVolume(value);
              },
              min: 0.0,
              max: 1.0,
              divisions: 20,
            ),
            Text('${(videoState.volume * 100).round()}%'),
          ],
        ),
      ),
    );
  }

  void _showSubtitleDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    // TODO: Implement subtitle selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subtitle selection coming soon')),
    );
  }

  void _showAudioTrackDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Audio Track'),
        content: Text('Audio track selection coming soon'),
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic videoController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hardware Acceleration'),
              subtitle: const Text('Enable hardware decoding'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Save to settings
                },
              ),
            ),
            ListTile(
              title: const Text('Auto-rotate'),
              subtitle: const Text('Rotate screen with video'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Save to settings
                },
              ),
            ),
            ListTile(
              title: const Text('Keep Screen On'),
              subtitle: const Text('Prevent screen from sleeping'),
              trailing: Switch(
                value: true, // TODO: Get from settings
                onChanged: (value) {
                  // TODO: Save to settings
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}
