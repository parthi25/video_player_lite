import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:floating/floating.dart';

import '../widgets/subtitle_display_widget.dart';
import '../services/system_controls_service.dart';
import '../services/file_browser_service.dart';
import '../services/video_format_service.dart';

enum MediaType { video, audio, streaming, image }

class AudioTrackInfo {
  final int id;
  final String title;
  final String language;
  final String? codec;
  final int? channels;
  final int? bitrate;

  const AudioTrackInfo({
    required this.id,
    required this.title,
    required this.language,
    this.codec,
    this.channels,
    this.bitrate,
  });

  String get displayName {
    if (title.isNotEmpty) return title;

    // Build descriptive name with codec and language
    final parts = <String>[];
    if (codec != null && codec!.isNotEmpty) {
      parts.add(codec!.toUpperCase());
    }
    if (language.isNotEmpty && language != 'Unknown') {
      parts.add(language.toUpperCase());
    }
    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // Fallback to track number with language if available
    if (language.isNotEmpty && language != 'Unknown') {
      return 'Track $id ($language)';
    }
    return 'Track $id';
  }
}

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
  final List<VideoFile> currentFolderVideos;
  final String? currentFolderName;
  final List<double> equalizerBands;
  final bool isEqualizerEnabled;
  final List<AudioTrackInfo> audioTracks;

  const VideoPlayerState({
    this.player,
    this.videoController,
    this.isInitialized = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferDuration = Duration.zero,
    this.volume = 100.0,
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
    this.aspectRatio = 1.777,
    this.videoPath,
    this.videoUrl,
    this.isLoaded = false,
    this.orientation = PlayerOrientation.auto,
    this.isInPip = false,
    this.useHwDec = true,
    this.audioDelay = 0.0,
    this.volumeBoost = 1.0,
    this.type = MediaType.video,
    this.currentFolderVideos = const [],
    this.currentFolderName,
    this.equalizerBands = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.isEqualizerEnabled = false,
    this.audioTracks = const [],
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
    List<VideoFile>? currentFolderVideos,
    String? currentFolderName,
    List<double>? equalizerBands,
    bool? isEqualizerEnabled,
    List<AudioTrackInfo>? audioTracks,
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
      currentFolderVideos: currentFolderVideos ?? this.currentFolderVideos,
      currentFolderName: currentFolderName ?? this.currentFolderName,
      equalizerBands: equalizerBands ?? this.equalizerBands,
      isEqualizerEnabled: isEqualizerEnabled ?? this.isEqualizerEnabled,
      audioTracks: audioTracks ?? this.audioTracks,
    );
  }
}

class VideoPlayerControllerNotifier extends StateNotifier<VideoPlayerState> {
  final Floating _floating = Floating();
  final List<StreamSubscription> _subscriptions = [];

  VideoPlayerControllerNotifier() : super(const VideoPlayerState()) {
    _initPipListener();
  }

  void _initPipListener() {}

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

      try {
        if (state.useHwDec) {
          if (player.platform is NativePlayer) {
            (player.platform as NativePlayer).setProperty('hwdec', 'auto');
          }
        } else {
          if (player.platform is NativePlayer) {
            (player.platform as NativePlayer).setProperty('hwdec', 'no');
          }
        }
      } catch (e) {
        debugPrint('Hardware decoding setup error: $e');
      }

      final videoController = VideoController(player);

      _subscriptions.add(
        player.stream.position.listen(
          (p) => state = state.copyWith(position: p),
        ),
      );
      _subscriptions.add(
        player.stream.duration.listen(
          (d) => state = state.copyWith(duration: d),
        ),
      );
      _subscriptions.add(
        player.stream.buffer.listen(
          (b) => state = state.copyWith(bufferDuration: b),
        ),
      );
      _subscriptions.add(
        player.stream.playing.listen(
          (isPlaying) => state = state.copyWith(isPlaying: isPlaying),
        ),
      );
      _subscriptions.add(
        player.stream.volume.listen((v) => state = state.copyWith(volume: v)),
      );
      _subscriptions.add(
        player.stream.error.listen((e) {
          state = state.copyWith(
            hasError: true,
            errorMessage: 'Playback error: $e',
            isPlaying: false,
          );
        }),
      );

      Media? media;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        media = Media(videoUrl);
      } else if (videoPath != null && videoPath.isNotEmpty) {
        media = Media(videoPath);
      }

      if (media == null) throw Exception('No valid media source');

      await player.open(media, play: false);

      // Extract audio tracks information with multiple attempts
      final audioTracks = <AudioTrackInfo>[];
      try {
        // Wait longer for tracks to be loaded, especially for HEVC content
        await Future.delayed(const Duration(milliseconds: 1000));

        // Try multiple times to get tracks
        for (int attempt = 0; attempt < 3; attempt++) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          final tracks = player.state.tracks.audio;

          if (tracks.isNotEmpty) {
            for (int i = 0; i < tracks.length; i++) {
              final track = tracks[i];
              // Extract detailed codec information
              String? codecInfo = track.codec;
              String? titleInfo = track.title;

              // Try to get more detailed codec info
              if (codecInfo == null || codecInfo.isEmpty) {
                // Fallback to common codec names based on track properties
                if (track.channels != null) {
                  final channels = track.channels.toString();
                  if (channels.contains('2')) {
                    codecInfo = 'STEREO';
                  } else if (channels.contains('6')) {
                    codecInfo = '5.1';
                  } else if (channels.contains('8')) {
                    codecInfo = '7.1';
                  }
                }
              }

              audioTracks.add(
                AudioTrackInfo(
                  id: i,
                  title: titleInfo?.isNotEmpty == true
                      ? titleInfo!
                      : (codecInfo?.isNotEmpty == true
                            ? 'Audio $codecInfo'
                            : 'Track ${i + 1}'),
                  language: track.language ?? 'Unknown',
                  codec: codecInfo,
                  channels: track.channels != null
                      ? int.tryParse(track.channels.toString())
                      : null,
                ),
              );
            }
            break; // Success, exit retry loop
          }
        }

        // If no tracks found, add a default audio track as fallback for better UX
        if (audioTracks.isEmpty) {
          audioTracks.add(
            AudioTrackInfo(
              id: 0,
              title: 'Default Audio',
              language: 'Unknown',
              codec: null,
              channels: null,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error extracting audio tracks: $e');
        // Add a default audio track as fallback
        audioTracks.add(
          AudioTrackInfo(
            id: 0,
            title: 'Default Audio',
            language: 'Unknown',
            codec: null,
            channels: null,
          ),
        );
      }

      if (mounted) {
        state = state.copyWith(
          player: player,
          videoController: videoController,
          isInitialized: true,
          isLoaded: true,
          isPlaying: false,
          volume: 100.0,
          audioTracks: audioTracks,
        );
      }
    } catch (e) {
      await _disposePlayer();
      if (mounted) {
        state = state.copyWith(
          isInitialized: false,
          hasError: true,
          errorMessage: 'Failed: $e',
        );
      }
    }
  }

  Future<void> play() async => await state.player?.play();
  Future<void> pause() async => await state.player?.pause();
  Future<void> togglePlayPause() async => await state.player?.playOrPause();
  Future<void> seekTo(Duration position) async =>
      await state.player?.seek(position);

  Future<void> setVolume(double volume) async {
    final v = (volume * 100).clamp(0.0, 200.0);
    await state.player?.setVolume(v);
    try {
      await SystemControlsService.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      // Ignore system volume sync errors
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await state.player?.setRate(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  void toggleControls() =>
      state = state.copyWith(showControls: !state.showControls);
  void toggleLock() => state = state.copyWith(isLocked: !state.isLocked);
  void toggleFullscreen() =>
      state = state.copyWith(isFullscreen: !state.isFullscreen);

  void setAspectRatio(AspectRatioMode mode) {
    double ratio = 16.0 / 9.0;
    switch (mode) {
      case AspectRatioMode.sixteenNine:
        ratio = 16.0 / 9.0;
        break;
      case AspectRatioMode.fourThree:
        ratio = 4.0 / 3.0;
        break;
      case AspectRatioMode.oneOne:
        ratio = 1.0;
        break;
      case AspectRatioMode.twentyOneNine:
        ratio = 21.0 / 9.0;
        break;
      case AspectRatioMode.fit:
        ratio = -1.0;
        break;
      case AspectRatioMode.fill:
        ratio = -2.0;
        break;
      case AspectRatioMode.stretch:
        ratio = -3.0;
        break;
      case AspectRatioMode.auto:
        ratio = 0.0;
        break;
    }
    state = state.copyWith(aspectRatio: ratio, aspectRatioMode: mode);
  }

  void cycleAspectRatio() {
    final modes = AspectRatioMode.values;
    setAspectRatio(
      modes[(modes.indexOf(state.aspectRatioMode) + 1) % modes.length],
    );
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
    if (state.player != null) state.player!.setVolume(state.volume * boost);
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

  void setSubtitle(String? path) => state = state.copyWith(subtitlePath: path);

  Future<void> toggleRotation() async {
    late PlayerOrientation newO;
    switch (state.orientation) {
      case PlayerOrientation.auto:
        newO = PlayerOrientation.landscape;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case PlayerOrientation.landscape:
        newO = PlayerOrientation.portrait;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;
      case PlayerOrientation.portrait:
        newO = PlayerOrientation.auto;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
    state = state.copyWith(orientation: newO);
  }

  Future<void> enterPIP() async {
    try {
      if (await _floating.isPipAvailable) {
        if (await _floating.enable(
              ImmediatePiP(aspectRatio: const Rational.landscape()),
            ) ==
            PiPStatus.enabled) {
          state = state.copyWith(isInPip: true);
        }
      }
    } catch (e) {
      // Ignore PiP errors
    }
  }

  Future<void> takeScreenshot() async {
    if (state.player == null) return;
    try {
      await state.player!.screenshot();
    } catch (e) {
      // Ignore screenshot errors
    }
  }

  void toggleDecoder() {
    state = state.copyWith(useHwDec: !state.useHwDec);
    if (state.videoPath != null || state.videoUrl != null) {
      initializeVideo(state.videoUrl, state.videoPath);
    }
  }

  void setCurrentFolder(List<VideoFile> folderVideos, String folderName) {
    state = state.copyWith(
      currentFolderVideos: folderVideos,
      currentFolderName: folderName,
    );
  }

  Future<void> playNextInFolder() async {
    if (state.currentFolderVideos.isEmpty || state.videoPath == null) return;
    final idx = state.currentFolderVideos.indexWhere(
      (v) => v.path == state.videoPath,
    );
    if (idx != -1 && idx < state.currentFolderVideos.length - 1) {
      await initializeVideo(null, state.currentFolderVideos[idx + 1].path);
    }
  }

  Future<void> playPreviousInFolder() async {
    if (state.currentFolderVideos.isEmpty || state.videoPath == null) return;
    final idx = state.currentFolderVideos.indexWhere(
      (v) => v.path == state.videoPath,
    );
    if (idx > 0) {
      await initializeVideo(null, state.currentFolderVideos[idx - 1].path);
    }
  }

  void toggleEqualizer() {
    state = state.copyWith(isEqualizerEnabled: !state.isEqualizerEnabled);
    _applyEqualizer();
  }

  void setEqualizerBand(int index, double value) {
    final bands = List<double>.from(state.equalizerBands);
    bands[index] = value;
    state = state.copyWith(equalizerBands: bands);
    if (state.isEqualizerEnabled) _applyEqualizer();
  }

  void _applyEqualizer() {
    if (state.player?.platform is NativePlayer) {
      if (!state.isEqualizerEnabled) {
        (state.player!.platform as NativePlayer).setProperty('af', '');
        return;
      }
      String filter = 'superequalizer=';
      for (int i = 0; i < state.equalizerBands.length; i++) {
        filter += '${i + 1}b=${state.equalizerBands[i].toStringAsFixed(1)}';
        if (i < state.equalizerBands.length - 1) filter += ':';
      }
      (state.player!.platform as NativePlayer).setProperty('af', filter);
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }
}

final videoPlayerControllerProvider =
    StateNotifierProvider<VideoPlayerControllerNotifier, VideoPlayerState>(
      (ref) => VideoPlayerControllerNotifier(),
    );

final gestureStateProvider = StateProvider<GestureState>(
  (ref) => const GestureState(),
);

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
