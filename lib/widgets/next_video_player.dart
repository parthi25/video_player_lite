import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../core/video_player_controller.dart';
import '../services/performance_service.dart';
import '../services/system_controls_service.dart';
import 'next_player_controls.dart';
import 'next_gesture_detector.dart';
import 'subtitle_display_widget.dart';
import 'video_error_handler.dart';

class NextVideoPlayer extends ConsumerStatefulWidget {
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
  ConsumerState<NextVideoPlayer> createState() => _NextVideoPlayerState();
}

class _NextVideoPlayerState extends ConsumerState<NextVideoPlayer> {
  late VideoPlayerControllerNotifier _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = ref.read(videoPlayerControllerProvider.notifier);
    PerformanceService.initialize();
    PerformanceService.optimizeForVideoPlayback();
    _initializeVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoState = ref.read(videoPlayerControllerProvider);
      _applyOrientation(videoState.orientation);
    });
  }

  @override
  void dispose() {
    _videoController.reset();
    _resetOrientation();
    PerformanceService.resetPerformanceSettings();
    super.dispose();
  }

  void _initializeVideo() {
    final videoState = ref.read(videoPlayerControllerProvider);

    if (!videoState.isInitialized &&
        (widget.videoUrl != null || widget.videoPath != null) &&
        videoState.player == null) {
      _videoController.initializeVideo(widget.videoUrl, widget.videoPath);
    }
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _applyOrientation(PlayerOrientation orientation) {
    switch (orientation) {
      case PlayerOrientation.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case PlayerOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case PlayerOrientation.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(videoPlayerControllerProvider.select((s) => s.orientation), (
      _,
      next,
    ) {
      _applyOrientation(next);
    });

    final videoState = ref.watch(videoPlayerControllerProvider);
    final bool isLoading = !videoState.isInitialized || !videoState.isLoaded;

    return VideoPlayerErrorHandler(
      videoPath: widget.videoPath,
      videoUrl: widget.videoUrl,
      onRetry: () => _initializeVideo(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (videoState.isInitialized)
              NextGestureDetector(
                onSeek: (position) {
                  ref
                      .read(videoPlayerControllerProvider.notifier)
                      .seekTo(position);
                },
                onVolumeChanged: (volume) {
                  ref
                      .read(videoPlayerControllerProvider.notifier)
                      .setVolume(volume);
                },
                onBrightnessChanged: (brightness) async {
                  try {
                    await SystemControlsService.setBrightness(brightness);
                  } catch (e) {
                    debugPrint('Error setting brightness: $e');
                  }
                },
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final currentRatio = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.aspectRatio,
                              ),
                            );
                            final videoController = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.videoController,
                              ),
                            );

                            if (videoController == null) {
                              return const SizedBox.shrink();
                            }

                            Widget videoWidget = Video(
                              controller: videoController,
                              fit: BoxFit.contain,
                              controls: NoVideoControls,
                              width: double.infinity,
                              height: double.infinity,
                            );

                            if (currentRatio > 0) {
                              return AspectRatio(
                                aspectRatio: currentRatio,
                                child: videoWidget,
                              );
                            }
                            return videoWidget;
                          },
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final isLoaded = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.isLoaded,
                              ),
                            );
                            if (!isLoaded) return const SizedBox.shrink();
                            return const NextPlayerControls();
                          },
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final position = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.position,
                              ),
                            );
                            final subtitles = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.subtitles,
                              ),
                            );
                            final subtitlePath = ref.watch(
                              videoPlayerControllerProvider.select(
                                (s) => s.subtitlePath,
                              ),
                            );

                            if (subtitles.isEmpty || subtitlePath == null) {
                              return const SizedBox.shrink();
                            }

                            return SubtitleDisplayWidget(
                              currentPosition: position,
                              subtitles: subtitles,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
    );
  }
}
