import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

// Video player state model
class VideoPlayerState {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final bool isFullscreen;
  final bool isLocked;
  final String? errorMessage;
  final bool showControls;
  final String aspectRatio;
  final int? audioTrackIndex;
  final String? subtitlePath;

  const VideoPlayerState({
    this.controller,
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isFullscreen = false,
    this.isLocked = false,
    this.errorMessage,
    this.showControls = true,
    this.aspectRatio = 'fit',
    this.audioTrackIndex,
    this.subtitlePath,
  });

  VideoPlayerState copyWith({
    VideoPlayerController? controller,
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
    bool? isFullscreen,
    bool? isLocked,
    String? errorMessage,
    bool? showControls,
    String? aspectRatio,
    int? audioTrackIndex,
    String? subtitlePath,
  }) {
    return VideoPlayerState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: errorMessage ?? this.errorMessage,
      showControls: showControls ?? this.showControls,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      audioTrackIndex: audioTrackIndex ?? this.audioTrackIndex,
      subtitlePath: subtitlePath ?? this.subtitlePath,
    );
  }
}

// Video player controller using Riverpod
class VideoPlayerControllerNotifier extends StateNotifier<VideoPlayerState> {
  VideoPlayerControllerNotifier() : super(const VideoPlayerState());

  final bool _mounted = true;
  Timer? _debounceTimer;

  Future<void> initializeVideo(String? videoUrl, String? videoPath) async {
    try {
      state = state.copyWith(
        isInitialized: false,
        isBuffering: true,
        errorMessage: null,
      );

      VideoPlayerController controller;

      if (videoUrl != null) {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else if (videoPath != null) {
        controller = VideoPlayerController.file(File(videoPath));
      } else {
        throw Exception('No video source provided');
      }

      await controller.initialize();

      // Optimize listener to reduce unnecessary updates
      controller.addListener(() {
        if (state.controller == controller) {
          // Debounce rapid position updates to improve performance
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 100), () {
            if (_mounted) {
              state = state.copyWith(
                isPlaying: controller.value.isPlaying,
                position: controller.value.position,
                isBuffering: controller.value.isBuffering,
              );
            }
          });
        }
      });

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        isBuffering: false,
        duration: controller.value.duration,
        position: controller.value.position,
        isPlaying: controller.value.isPlaying,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        isBuffering: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> play() async {
    if (state.controller != null) {
      await state.controller!.play();
    }
  }

  Future<void> pause() async {
    if (state.controller != null) {
      await state.controller!.pause();
    }
  }

  Future<void> togglePlayPause() async {
    if (state.controller != null) {
      if (state.isPlaying) {
        await pause();
      } else {
        await play();
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    if (state.controller != null) {
      await state.controller!.seekTo(position);
    }
  }

  Future<void> setVolume(double volume) async {
    if (state.controller != null) {
      await state.controller!.setVolume(volume.clamp(0.0, 1.0));
      state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (state.controller != null) {
      await state.controller!.setPlaybackSpeed(speed.clamp(0.25, 2.0));
      state = state.copyWith(playbackSpeed: speed.clamp(0.25, 2.0));
    }
  }

  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  void showControlsTemporarily() {
    state = state.copyWith(showControls: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (state.showControls) {
        state = state.copyWith(showControls: false);
      }
    });
  }

  void toggleLock() {
    state = state.copyWith(isLocked: !state.isLocked);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setAspectRatio(String ratio) {
    state = state.copyWith(aspectRatio: ratio);
  }

  void setAudioTrack(int? index) {
    state = state.copyWith(audioTrackIndex: index);
  }

  void setSubtitle(String? path) {
    state = state.copyWith(subtitlePath: path);
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

// Provider for the video player controller
final videoPlayerControllerProvider =
    StateNotifierProvider<VideoPlayerControllerNotifier, VideoPlayerState>((
      ref,
    ) {
      return VideoPlayerControllerNotifier();
    });

// Gesture state provider
final gestureStateProvider = StateProvider<GestureState>((ref) {
  return const GestureState();
});

class GestureState {
  final bool isSeeking;
  final double seekPosition;
  final bool showVolumeIndicator;
  final double volume;
  final bool showBrightnessIndicator;
  final double brightness;

  const GestureState({
    this.isSeeking = false,
    this.seekPosition = 0.0,
    this.showVolumeIndicator = false,
    this.volume = 1.0,
    this.showBrightnessIndicator = false,
    this.brightness = 1.0,
  });

  GestureState copyWith({
    bool? isSeeking,
    double? seekPosition,
    bool? showVolumeIndicator,
    double? volume,
    bool? showBrightnessIndicator,
    double? brightness,
  }) {
    return GestureState(
      isSeeking: isSeeking ?? this.isSeeking,
      seekPosition: seekPosition ?? this.seekPosition,
      showVolumeIndicator: showVolumeIndicator ?? this.showVolumeIndicator,
      volume: volume ?? this.volume,
      showBrightnessIndicator:
          showBrightnessIndicator ?? this.showBrightnessIndicator,
      brightness: brightness ?? this.brightness,
    );
  }
}
