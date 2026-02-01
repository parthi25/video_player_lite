import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';

class NextGestureDetector extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(Duration)? onSeek;
  final Function(double)? onVolumeChanged;
  final Function(double)? onBrightnessChanged;

  const NextGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onSeek,
    this.onVolumeChanged,
    this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final gestureState = ref.watch(gestureStateProvider);
    final gestureNotifier = ref.read(gestureStateProvider.notifier);

    // Cache screen dimensions to avoid repeated calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap?.call();
        ref.read(videoPlayerControllerProvider.notifier).toggleControls();
      },
      onDoubleTap: () {
        onDoubleTap?.call();
        ref.read(videoPlayerControllerProvider.notifier).togglePlayPause();
      },
      onHorizontalDragStart: (details) {
        if (videoState.controller != null &&
            videoState.duration.inMilliseconds > 0) {
          gestureNotifier.state = gestureState.copyWith(
            isSeeking: true,
            seekPosition: videoState.position.inMilliseconds.toDouble(),
          );
        }
      },
      onHorizontalDragUpdate: (details) {
        if (!gestureState.isSeeking || videoState.controller == null) return;

        final dragPercentage = details.primaryDelta! / screenWidth;
        final seekAmount = dragPercentage * videoState.duration.inMilliseconds;
        final newPosition = (gestureState.seekPosition + seekAmount).clamp(
          0.0,
          videoState.duration.inMilliseconds.toDouble(),
        );

        gestureNotifier.state = gestureState.copyWith(
          seekPosition: newPosition,
        );
        onSeek?.call(Duration(milliseconds: newPosition.round()));
      },
      onHorizontalDragEnd: (details) {
        if (gestureState.isSeeking) {
          onSeek?.call(
            Duration(milliseconds: gestureState.seekPosition.round()),
          );
          gestureNotifier.state = gestureState.copyWith(isSeeking: false);
        }
      },
      onVerticalDragUpdate: (details) {
        final isLeftSide = details.globalPosition.dx < screenWidth / 2;
        final dragPercentage = -details.primaryDelta! / screenHeight;

        if (isLeftSide) {
          // Brightness control (left side)
          final newBrightness = (gestureState.brightness + dragPercentage)
              .clamp(0.0, 1.0);
          gestureNotifier.state = gestureState.copyWith(
            brightness: newBrightness,
            showBrightnessIndicator: true,
          );
          onBrightnessChanged?.call(newBrightness);
        } else {
          // Volume control (right side)
          final newVolume = (gestureState.volume + dragPercentage).clamp(
            0.0,
            1.0,
          );
          gestureNotifier.state = gestureState.copyWith(
            volume: newVolume,
            showVolumeIndicator: true,
          );
          onVolumeChanged?.call(newVolume);
        }
      },
      onVerticalDragEnd: (details) {
        gestureNotifier.state = gestureState.copyWith(
          showVolumeIndicator: false,
          showBrightnessIndicator: false,
        );
      },
      child: Stack(
        children: [
          child,

          // Optimized seek indicator - only rebuild when necessary
          if (gestureState.isSeeking)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gestureState.seekPosition >
                                  videoState.position.inMilliseconds
                              ? Icons.fast_forward
                              : Icons.fast_rewind,
                          color: Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(
                            Duration(
                              milliseconds: gestureState.seekPosition.round(),
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((gestureState.seekPosition / videoState.duration.inMilliseconds) * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Optimized volume indicator
          if (gestureState.showVolumeIndicator)
            Positioned(
              right: 20,
              top: screenHeight * 0.3,
              child: _buildVerticalIndicator(
                Icons.volume_up,
                gestureState.volume,
                Colors.blue,
              ),
            ),

          // Optimized brightness indicator
          if (gestureState.showBrightnessIndicator)
            Positioned(
              left: 20,
              top: screenHeight * 0.3,
              child: _buildVerticalIndicator(
                Icons.brightness_6,
                gestureState.brightness,
                Colors.yellow,
              ),
            ),
        ],
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

  Widget _buildVerticalIndicator(IconData icon, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 40,
                height: 120 * value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
