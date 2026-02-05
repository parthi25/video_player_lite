import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:floating/floating.dart';

import '../widgets/subtitle_display_widget.dart';
import '../services/system_controls_service.dart';
import '../services/video_format_service.dart';

enum PlayerOrientation { auto, landscape, portrait }

enum AspectRatioMode {
  auto('Auto'),
  fit('Fit'),
  fill('Fill'),
  sixteenNine('16:9'),
  fourThree('4:3'),
  twentyOneNine('21:9'),
  oneOne('1:1'),
  stretch('Stretch');

  final String label;
  const AspectRatioMode(this.label);
}

// Video player state model
class VideoPlayerState {
  final Player? player;
  final VideoController? videoController;
  final bool isInitialized;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Duration bufferDuration;
  final double volume;
  final bool isLocked;
  final String? subtitlePath;
  final List<SubtitleEntry> subtitles;
  final bool showControls;
  final bool isFullscreen;
  final int audioTrackIndex;
  final bool hasError;
  final String? errorMessage;
  final double playbackSpeed;
  final AspectRatioMode aspectRatioMode;
  final double aspectRatio;
  final String? videoPath;
  final String? videoUrl;
  final bool isLoaded;
  final PlayerOrientation orientation;
  final bool isInPip;
  final bool useHwDec;
  final double audioDelay; // In milliseconds
  final double volumeBoost; // 1.0 is normal, 2.0 is double
  final MediaType type;

  const VideoPlayerState({
    this.player,
    this.videoController,
    this.isInitialized = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferDuration = Duration.zero,
    this.volume = 100.0, // MediaKit uses 0-100
    this.isLocked = false,
    this.subtitlePath,
    this.subtitles = const [],
    this.showControls = true,
    this.isFullscreen = false,
    this.audioTrackIndex = 0,
    this.hasError = false,
    this.errorMessage,
    this.playbackSpeed = 1.0,
    this.aspectRatioMode = AspectRatioMode.fit,
    this.aspectRatio = 1.777, // Default 16:9
    this.videoPath,
    this.videoUrl,
    this.isLoaded = false,
    this.orientation = PlayerOrientation.auto,
    this.isInPip = false,
    this.useHwDec = true,
    this.audioDelay = 0.0,
    this.volumeBoost = 1.0,
    this.type = MediaType.video,
  });

  VideoPlayerState copyWith({
    Player? player,
    VideoController? videoController,
    bool? isInitialized,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    Duration? bufferDuration,
    double? volume,
    bool? isLocked,
    String? subtitlePath,
    List<SubtitleEntry>? subtitles,
    bool? showControls,
    bool? isFullscreen,
    int? audioTrackIndex,
    bool? hasError,
    String? errorMessage,
    double? playbackSpeed,
    double? aspectRatio,
    AspectRatioMode? aspectRatioMode,
    String? videoPath,
    String? videoUrl,
    bool? isLoaded,
    PlayerOrientation? orientation,
    bool? isInPip,
    bool? useHwDec,
    double? audioDelay,
    double? volumeBoost,
    MediaType? type,
  }) {
    return VideoPlayerState(
      player: player ?? this.player,
      videoController: videoController ?? this.videoController,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferDuration: bufferDuration ?? this.bufferDuration,
      volume: volume ?? this.volume,
      isLocked: isLocked ?? this.isLocked,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      subtitles: subtitles ?? this.subtitles,
      showControls: showControls ?? this.showControls,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      audioTrackIndex: audioTrackIndex ?? this.audioTrackIndex,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      aspectRatioMode: aspectRatioMode ?? this.aspectRatioMode,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      isLoaded: isLoaded ?? this.isLoaded,
      orientation: orientation ?? this.orientation,
      isInPip: isInPip ?? this.isInPip,
      useHwDec: useHwDec ?? this.useHwDec,
      audioDelay: audioDelay ?? this.audioDelay,
      volumeBoost: volumeBoost ?? this.volumeBoost,
      type: type ?? this.type,
    );
  }
}

// Video player controller using Riverpod
class VideoPlayerControllerNotifier extends StateNotifier<VideoPlayerState> {
  final Floating _floating = Floating();
  VideoPlayerControllerNotifier() : super(const VideoPlayerState()) {
    _initPipListener();
  }

  void _initPipListener() {
    // PiP status stream not available in floating 2.0.x
  }

  final List<StreamSubscription> _subscriptions = [];

  Future<void> _disposePlayer() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();

    if (state.player != null) {
      await state.player!.dispose();
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void reset() async {
    await _disposePlayer();
    state = const VideoPlayerState();
  }

  Future<void> initializeVideo(String? videoUrl, String? videoPath) async {
    try {
      await _disposePlayer();

      state = state.copyWith(
        isInitialized: false,
        errorMessage: null,
        videoPath: videoPath,
        videoUrl: videoUrl,
        isLoaded: false,
        hasError: false,
        type: videoPath != null
            ? (VideoFormatService.getFormatByPath(videoPath)?.type ??
                  MediaType.video)
            : MediaType.video,
      );

      final player = Player();
      if (state.useHwDec) {
        if (player.platform is NativePlayer) {
          (player.platform as NativePlayer).setProperty('hwdec', 'auto');
        }
      } else {
        if (player.platform is NativePlayer) {
          (player.platform as NativePlayer).setProperty('hwdec', 'no');
        }
      }
      final videoController = VideoController(player);

      _subscriptions.add(
        player.stream.position.listen((position) {
          state = state.copyWith(position: position);
        }),
      );

      _subscriptions.add(
        player.stream.duration.listen((duration) {
          state = state.copyWith(duration: duration);
        }),
      );

      _subscriptions.add(
        player.stream.buffer.listen((buffer) {
          state = state.copyWith(bufferDuration: buffer);
        }),
      );

      _subscriptions.add(
        player.stream.playing.listen((isPlaying) {
          state = state.copyWith(isPlaying: isPlaying);
        }),
      );

      _subscriptions.add(
        player.stream.volume.listen((volume) {
          state = state.copyWith(volume: volume);
        }),
      );

      _subscriptions.add(
        player.stream.error.listen((error) {
          debugPrint('MediaKit Error: $error');
          state = state.copyWith(
            hasError: true,
            errorMessage: 'Playback error: $error',
            isPlaying: false,
          );
        }),
      );

      Media? media;
      if (videoUrl != null) {
        media = Media(videoUrl);
      } else if (videoPath != null) {
        media = Media(videoPath);
      }

      if (media == null) {
        throw Exception('No media source provided');
      }

      await player.open(media, play: true);

      state = state.copyWith(
        player: player,
        videoController: videoController,
        isInitialized: true,
        isLoaded: true,
        isPlaying: true,
        volume: 100.0,
      );
    } catch (e) {
      debugPrint('Video initialization error: $e');
      await _disposePlayer();
      state = state.copyWith(
        isInitialized: false,
        hasError: true,
        errorMessage: 'Failed to initialize video: $e',
      );
    }
  }

  Future<void> play() async {
    await state.player?.play();
  }

  Future<void> pause() async {
    await state.player?.pause();
  }

  Future<void> togglePlayPause() async {
    await state.player?.playOrPause();
  }

  Future<void> seekTo(Duration position) async {
    await state.player?.seek(position);
  }

  Future<void> setVolume(double volume) async {
    final v = (volume * 100).clamp(0.0, 200.0);
    await state.player?.setVolume(v);

    try {
      await SystemControlsService.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error syncing system volume: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await state.player?.setRate(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  void toggleLock() {
    state = state.copyWith(isLocked: !state.isLocked);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setAspectRatio(AspectRatioMode mode) {
    double ratioValue = 16.0 / 9.0;
    switch (mode) {
      case AspectRatioMode.sixteenNine:
        ratioValue = 16.0 / 9.0;
        break;
      case AspectRatioMode.fourThree:
        ratioValue = 4.0 / 3.0;
        break;
      case AspectRatioMode.oneOne:
        ratioValue = 1.0;
        break;
      case AspectRatioMode.twentyOneNine:
        ratioValue = 21.0 / 9.0;
        break;
      case AspectRatioMode.fit:
        ratioValue = -1.0;
        break;
      case AspectRatioMode.fill:
        ratioValue = -2.0;
        break;
      case AspectRatioMode.stretch:
        ratioValue = -3.0;
        break;
      case AspectRatioMode.auto:
        ratioValue = 0.0;
        break;
    }
    state = state.copyWith(aspectRatio: ratioValue, aspectRatioMode: mode);
  }

  void cycleAspectRatio() {
    final modes = AspectRatioMode.values;
    final currentIndex = modes.indexOf(state.aspectRatioMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    setAspectRatio(modes[nextIndex]);
  }

  void setAudioDelay(double delay) {
    state = state.copyWith(audioDelay: delay);
    if (state.player?.platform is NativePlayer) {
      (state.player!.platform as NativePlayer).setProperty(
        'audio-delay',
        (delay / 1000.0).toString(),
      );
    }
  }

  void setVolumeBoost(double boost) {
    state = state.copyWith(volumeBoost: boost);
    if (state.player != null) {
      state.player!.setVolume(state.volume * boost);
    }
  }

  Future<void> setAudioTrack(int? index) async {
    state = state.copyWith(audioTrackIndex: index);
    if (state.player != null && index != null) {
      final tracks = state.player!.state.tracks.audio;
      if (index >= 0 && index < tracks.length) {
        await state.player!.setAudioTrack(tracks[index]);
      }
    }
  }

  void setSubtitle(String? path) {
    state = state.copyWith(subtitlePath: path);
  }

  Future<void> toggleRotation() async {
    late PlayerOrientation newOrientation;
    switch (state.orientation) {
      case PlayerOrientation.auto:
        newOrientation = PlayerOrientation.landscape;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case PlayerOrientation.landscape:
        newOrientation = PlayerOrientation.portrait;
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        break;
      case PlayerOrientation.portrait:
        newOrientation = PlayerOrientation.auto;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
    state = state.copyWith(orientation: newOrientation);
  }

  Future<void> enterPIP() async {
    try {
      final canUsePip = await _floating.isPipAvailable;
      if (canUsePip) {
        final result = await _floating.enable(
          ImmediatePiP(
            aspectRatio: const Rational.landscape(),
          ),
        );
        if (result == PiPStatus.enabled) {
          state = state.copyWith(isInPip: true);
        }
      }
    } catch (e) {
      debugPrint('Error enabling PIP: $e');
    }
  }

  Future<void> takeScreenshot() async {
    if (state.player == null) return;
    try {
      final image = await state.player!.screenshot();
      if (image != null) {
        debugPrint('Screenshot taken! Size: ${image.length} bytes');
      }
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
    }
  }

  void toggleDecoder() {
    final newValue = !state.useHwDec;
    state = state.copyWith(useHwDec: newValue);
    if (state.videoPath != null || state.videoUrl != null) {
      initializeVideo(state.videoUrl, state.videoPath);
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }
}

final videoPlayerControllerProvider =
    StateNotifierProvider<VideoPlayerControllerNotifier, VideoPlayerState>((
      ref,
    ) {
      return VideoPlayerControllerNotifier();
    });

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
