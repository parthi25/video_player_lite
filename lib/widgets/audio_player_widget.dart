import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String audioPath;
  final String audioTitle;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.audioTitle,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _albumArtController;
  late VideoPlayerControllerNotifier _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = ref.read(videoPlayerControllerProvider.notifier);
    _albumArtController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Auto-play audio file
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoController.initializeVideo(null, widget.audioPath);
    });
  }

  @override
  void dispose() {
    _albumArtController.dispose();
    // Stop audio playback when disposing
    _videoController.pause();
    _videoController.reset();
    super.dispose();
  }

  void _togglePlayPause() {
    final videoState = ref.read(videoPlayerControllerProvider);

    if (videoState.isPlaying) {
      _videoController.pause();
      _albumArtController.stop();
    } else {
      _videoController.play();
      _albumArtController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.iconTheme.color),
          onPressed: () {
            // Stop audio and reset when going back
            _videoController.pause();
            _videoController.reset();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Now Playing',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.stop_circle_outlined, color: Colors.red),
            onPressed: () {
              _videoController.pause();
              _videoController.reset();
              _albumArtController.stop();
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Album Art with Animation
            Expanded(
              flex: 3,
              child: Center(
                child: AnimatedBuilder(
                  animation: _albumArtController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _albumArtController.value * 2 * 3.14159,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade600,
                              Colors.pink.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Song Info
            Column(
              children: [
                Text(
                  widget.audioTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: videoState.isPlaying
                            ? Colors.green
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            videoState.isPlaying
                                ? Icons.play_arrow
                                : Icons.pause,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            videoState.isPlaying ? 'PLAYING' : 'PAUSED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Audio File',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Seek Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: Colors.blue.shade400,
                      inactiveTrackColor: isDark
                          ? Colors.white24
                          : Colors.black12,
                      thumbColor: Colors.blue.shade400,
                    ),
                    child: Slider(
                      value: videoState.duration.inMilliseconds > 0
                          ? videoState.position.inMilliseconds.toDouble() /
                                videoState.duration.inMilliseconds.toDouble()
                          : 0.0,
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds:
                              (value * videoState.duration.inMilliseconds)
                                  .round(),
                        );
                        ref
                            .read(videoPlayerControllerProvider.notifier)
                            .seekTo(newPosition);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(videoState.position),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(videoState.duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle, color: theme.iconTheme.color),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: theme.iconTheme.color,
                    size: 32,
                  ),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade400,
                  ),
                  child: IconButton(
                    icon: Icon(
                      videoState.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: theme.iconTheme.color,
                    size: 32,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.stop, color: theme.iconTheme.color),
                  onPressed: () {
                    _videoController.pause();
                    _videoController.seekTo(Duration.zero);
                    _albumArtController.stop();
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Additional Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(Icons.favorite_border, 'Like'),
                _buildControlButton(Icons.playlist_add, 'Playlist'),
                _buildControlButton(Icons.equalizer, 'EQ'),
                _buildControlButton(Icons.share, 'Share'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.iconTheme.color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }
}
