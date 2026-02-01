import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../core/video_player_controller.dart';
import 'next_gesture_detector.dart';
import 'next_player_controls.dart';

class NextVideoPlayer extends ConsumerWidget {
  final String? videoUrl;
  final String? videoPath;
  final bool autoPlay;
  final bool looping;
  final VoidCallback? onVideoEnded;

  const NextVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoPath,
    this.autoPlay = false,
    this.looping = false,
    this.onVideoEnded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final videoController = ref.read(videoPlayerControllerProvider.notifier);

    // Initialize video when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!videoState.isInitialized &&
          (videoUrl != null || videoPath != null)) {
        videoController.initializeVideo(videoUrl, videoPath);
      }
    });

    // Listen for video end with optimized listener
    ref.listen<VideoPlayerState>(videoPlayerControllerProvider, (
      previous,
      next,
    ) {
      if (previous != null &&
          next.isInitialized &&
          next.controller != null &&
          next.controller!.value.isInitialized) {
        next.controller!.addListener(() {
          if (next.controller!.value.position >=
                  next.controller!.value.duration &&
              next.controller!.value.duration != Duration.zero) {
            onVideoEnded?.call();
          }
        });
      }
    });

    if (videoState.errorMessage != null) {
      return _buildErrorWidget(context, videoState.errorMessage!);
    }

    if (!videoState.isInitialized) {
      return _buildLoadingWidget();
    }

    // Use RepaintBoundary for better performance
    return RepaintBoundary(
      child: NextGestureDetector(
        onSeek: videoController.seekTo,
        onVolumeChanged: videoController.setVolume,
        onBrightnessChanged: (brightness) {
          // TODO: Implement brightness control
          debugPrint('Brightness: $brightness');
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              Center(child: _buildVideoPlayer(videoState)),

              // Custom controls overlay
              const NextPlayerControls(),

              // Lock indicator
              if (videoState.isLocked)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Screen Locked',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerState videoState) {
    if (videoState.controller == null ||
        !videoState.controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    Widget videoWidget = VideoPlayer(videoState.controller!);

    // Apply aspect ratio based on setting
    switch (videoState.aspectRatio) {
      case 'fill':
        videoWidget = FittedBox(fit: BoxFit.cover, child: videoWidget);
        break;
      case 'stretch':
        videoWidget = StretchVideo(child: videoWidget);
        break;
      case '16:9':
        videoWidget = AspectRatio(
          aspectRatio: 16 / 9,
          child: FittedBox(fit: BoxFit.contain, child: videoWidget),
        );
        break;
      case '4:3':
        videoWidget = AspectRatio(
          aspectRatio: 4 / 3,
          child: FittedBox(fit: BoxFit.contain, child: videoWidget),
        );
        break;
      case 'fit':
      default:
        videoWidget = AspectRatio(
          aspectRatio: videoState.controller!.value.aspectRatio,
          child: videoWidget,
        );
        break;
    }

    return videoWidget;
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Loading Video...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Add retry functionality
                debugPrint('Retry button pressed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for stretched video
class StretchVideo extends StatelessWidget {
  final Widget child;

  const StretchVideo({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform.scale(
          scaleX: constraints.maxWidth / constraints.maxHeight,
          scaleY: constraints.maxHeight / constraints.maxWidth,
          child: child,
        );
      },
    );
  }
}
