import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../widgets/subtitle_selection_widget.dart';
import '../services/playlist_service.dart';
import '../screens/video_cutter_screen.dart';
import '../widgets/equalizer_widget.dart';

class NextPlayerControls extends ConsumerStatefulWidget {
  const NextPlayerControls({super.key});

  @override
  ConsumerState<NextPlayerControls> createState() => _NextPlayerControlsState();
}

class _NextPlayerControlsState extends ConsumerState<NextPlayerControls>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _showSidePanel = false;
  bool _isRibbonExpanded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Timer? _hideTimer;
  bool _isSeeking = false;
  Duration _seekPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _startHideTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    final videoState = ref.read(videoPlayerControllerProvider);

    // Don't auto-hide controls when video is paused
    if (!videoState.isPlaying) {
      return;
    }

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _fadeController.status == AnimationStatus.completed) {
        final currentState = ref.read(videoPlayerControllerProvider);
        // Only hide if video is still playing
        if (currentState.isPlaying) {
          _fadeController.reverse();
        }
      }
    });
  }

  void _toggleControlsVisibility() {
    final videoState = ref.read(videoPlayerControllerProvider);

    if (_fadeController.status == AnimationStatus.completed) {
      _fadeController.reverse();
    } else {
      _fadeController.forward();
      // Only start hide timer if video is playing
      if (videoState.isPlaying) {
        _startHideTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(
      videoPlayerControllerProvider.select((s) => s.isLocked),
    );
    // Removed full state watch to prevent rebuilds on 4Hz position updates
    // final videoState = ref.watch(videoPlayerControllerProvider);
    final videoController = ref.read(videoPlayerControllerProvider.notifier);

    ref.listen(videoPlayerControllerProvider.select((s) => s.isPlaying), (
      _,
      playing,
    ) {
      if (!playing && _fadeController.status == AnimationStatus.dismissed) {
        _fadeController.forward();
      } else if (playing) {
        _startHideTimer();
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggleControlsVisibility,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: IgnorePointer(
          ignoring: _fadeController.status == AnimationStatus.dismissed,
          child: Stack(
            children: [
              Container(color: Colors.black26),
              if (!isLocked) _buildTopControls(videoController),
              _buildBottomControls(videoController),
              if (isLocked)
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.lock, color: Colors.white, size: 64),
                    onPressed: () => videoController.toggleLock(),
                  ),
                ),
              if (_showSidePanel && !isLocked)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: _buildSidePanel(videoController),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(VideoPlayerControllerNotifier videoController) {
    // Select only what we need for the top bar
    final videoName = ref.watch(
      videoPlayerControllerProvider.select(
        (s) => s.videoPath?.split(Platform.pathSeparator).last ?? 'Parthi Play',
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    // Use the provided back callback if available (handles overlay mode)
                    final backCallback = ref.read(
                      videoPlayerBackCallbackProvider,
                    );

                    await videoController.pause();
                    videoController.reset();

                    // Instant navigation - removed delay
                    if (backCallback != null) {
                      backCallback();
                    } else if (mounted) {
                      // Fallback to navigator pop
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        final navigator = Navigator.of(
                          context,
                          rootNavigator: false,
                        );
                        if (navigator.canPop()) {
                          navigator.pop();
                        } else {
                          final rootNavigator = Navigator.of(
                            context,
                            rootNavigator: true,
                          );
                          if (rootNavigator.canPop()) {
                            rootNavigator.pop();
                          }
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          videoName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final useHwDec = ref.watch(
                            videoPlayerControllerProvider.select(
                              (s) => s.useHwDec,
                            ),
                          );
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _startHideTimer();
                                videoController.toggleDecoder();
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: useHwDec ? Colors.blue : Colors.grey,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  color: useHwDec
                                      ? Colors.blue.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  useHwDec ? 'HW' : 'SW',
                                  style: TextStyle(
                                    color: useHwDec ? Colors.blue : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showMoreOptions(videoController),
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildActionRibbon(videoController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRibbon(VideoPlayerControllerNotifier videoController) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final orientation = ref.watch(
      videoPlayerControllerProvider.select((s) => s.orientation),
    );

    final List<Widget> allActions = [
      _buildActionButton(Icons.cast, () => _showCastingControls()),
      _buildActionButton(
        Icons.speed,
        () => _showSpeedSelection(videoController),
      ),
      _buildActionButton(Icons.subtitles, () => _showSubtitleSelection()),
      _buildActionButton(
        Icons.audiotrack,
        () => _showAudioTrackSelection(videoController),
      ),
      _buildActionButton(Icons.equalizer, () => _showEqualizer()),
      _buildActionButton(
        _getRotationIcon(orientation),
        () => _showRotationControls(videoController),
        color: _getRotationColor(orientation),
      ),
      _buildActionButton(Icons.content_cut, () => _showVideoCutter()),
      _buildActionButton(
        Icons.picture_in_picture,
        () => _showPiPControls(videoController),
      ),
    ];

    final List<Widget> visibleActions = _isRibbonExpanded
        ? allActions
        : allActions.take(3).toList();

    if (!_isRibbonExpanded && allActions.length > 3) {
      visibleActions.add(
        _buildActionButton(
          Icons.expand_more,
          () => setState(() => _isRibbonExpanded = true),
          rotationAngle: 1.5708, // 90 degrees in radians
        ),
      );
    } else if (_isRibbonExpanded && allActions.length > 3) {
      visibleActions.add(
        _buildActionButton(
          Icons.expand_less,
          () => setState(() => _isRibbonExpanded = false),
          rotationAngle: 1.5708, // 90 degrees in radians
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(isLandscape ? 4 : 16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleActions,
      ),
    );
  }

  IconData _getRotationIcon(PlayerOrientation orientation) {
    switch (orientation) {
      case PlayerOrientation.auto:
        return Icons.screen_rotation;
      case PlayerOrientation.landscape:
        return Icons.screen_lock_landscape;
      case PlayerOrientation.portrait:
        return Icons.screen_lock_portrait;
    }
  }

  Color? _getRotationColor(PlayerOrientation orientation) {
    return orientation == PlayerOrientation.auto ? null : Colors.red;
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    double? rotationAngle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            _startHideTimer();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Transform.rotate(
              angle: rotationAngle ?? 0,
              child: Icon(icon, color: color ?? Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(VideoPlayerControllerNotifier videoController) {
    final isLocked = ref.watch(
      videoPlayerControllerProvider.select((s) => s.isLocked),
    );
    final position = ref.watch(
      videoPlayerControllerProvider.select((s) => s.position),
    );
    final duration = ref.watch(
      videoPlayerControllerProvider.select((s) => s.duration),
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isLocked) ...[
                  Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            activeTrackColor: Colors.red.shade600,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            thumbColor: Colors.red.shade600,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            min: 0.0,
                            max: duration.inMilliseconds.toDouble(),
                            value: position.inMilliseconds.toDouble().clamp(
                              0.0,
                              duration.inMilliseconds.toDouble(),
                            ),
                            onChangeStart: (_) {
                              _isSeeking = true;
                            },
                            onChangeEnd: (_) {
                              _isSeeking = false;
                            },
                            onChanged: (value) {
                              if (!_isSeeking) {
                                _startHideTimer();
                              }
                              _seekPosition = Duration(
                                milliseconds: value.round(),
                              );
                              videoController.seekTo(_seekPosition);
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLockButton(videoController),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _playPrevious(videoController),
                              ),
                              const SizedBox(width: 16),
                              _buildPlayPauseButton(videoController),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _playNext(videoController),
                              ),
                            ],
                          ),
                        ),
                        _buildAspectRatioButton(videoController),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Center(child: _buildLockButton(videoController)),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playPrevious(
    VideoPlayerControllerNotifier videoController,
  ) async {
    // Check if we have folder videos for navigation
    final videoState = ref.read(videoPlayerControllerProvider);
    if (videoState.currentFolderVideos.isNotEmpty) {
      await videoController.playPreviousInFolder();
    } else {
      // Fallback to playlist navigation
      final prev = PlaylistService.getPreviousVideo();
      if (prev != null) {
        await videoController.initializeVideo(null, prev.path);
      }
    }
  }

  Future<void> _playNext(VideoPlayerControllerNotifier videoController) async {
    // Check if we have folder videos for navigation
    final videoState = ref.read(videoPlayerControllerProvider);
    if (videoState.currentFolderVideos.isNotEmpty) {
      await videoController.playNextInFolder();
    } else {
      // Fallback to playlist navigation
      final next = PlaylistService.getNextVideo();
      if (next != null) {
        await videoController.initializeVideo(null, next.path);
      }
    }
  }

  Widget _buildPlayPauseButton(VideoPlayerControllerNotifier videoController) {
    final isPlaying = ref.watch(
      videoPlayerControllerProvider.select((s) => s.isPlaying),
    );
    return GestureDetector(
      onTap: () {
        _startHideTimer();
        videoController.togglePlayPause();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[100]!],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            color: Colors.black87,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildLockButton(VideoPlayerControllerNotifier videoController) {
    final isLocked = ref.watch(
      videoPlayerControllerProvider.select((s) => s.isLocked),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.red.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: isLocked
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            _startHideTimer();
            videoController.toggleLock();
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                key: ValueKey(isLocked),
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAspectRatioButton(
    VideoPlayerControllerNotifier videoController,
  ) {
    final aspectRatioMode = ref.watch(
      videoPlayerControllerProvider.select((s) => s.aspectRatioMode),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            _startHideTimer();
            videoController.cycleAspectRatio();
          },
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              _getAspectRatioIcon(aspectRatioMode),
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAspectRatioIcon(AspectRatioMode mode) {
    switch (mode) {
      case AspectRatioMode.auto:
        return Icons.aspect_ratio;
      case AspectRatioMode.fit:
        return Icons.fit_screen;
      case AspectRatioMode.fill:
        return Icons.fullscreen;
      case AspectRatioMode.sixteenNine:
        return Icons.crop_16_9;
      case AspectRatioMode.fourThree:
        return Icons.crop_3_2;
      case AspectRatioMode.twentyOneNine:
        return Icons.crop_7_5;
      case AspectRatioMode.oneOne:
        return Icons.crop_square;
      case AspectRatioMode.stretch:
        return Icons.unfold_more;
    }
  }

  Widget _buildSidePanel(VideoPlayerControllerNotifier videoController) {
    return Container(
      width: 250,
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white),
              title: const Text('Close', style: TextStyle(color: Colors.white)),
              onTap: () => setState(() => _showSidePanel = false),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _showAdvancedSettings(videoController),
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
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  void _showRotationControls(VideoPlayerControllerNotifier videoController) {
    videoController.toggleRotation();
  }

  void _showVideoCutter() {
    final videoState = ref.read(videoPlayerControllerProvider);
    if (videoState.videoPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoCutterScreen(videoPath: videoState.videoPath!),
        ),
      );
    }
  }

  void _showCastingControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CastingControlsWidget(),
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
      builder: (context) =>
          PlaybackSpeedSelectionWidget(videoController: videoController),
    );
  }

  void _showSubtitleSelection() {
    final videoState = ref.watch(videoPlayerControllerProvider);
    if (videoState.videoPath == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubtitleSelectionWidget(
        videoPath: videoState.videoPath!,
        onSubtitleSelected: () {},
      ),
    );
  }

  void _showAudioTrackSelection(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final currentState = ref.watch(videoPlayerControllerProvider);
          return Container(
            padding: const EdgeInsets.all(16),
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
                      ListTile(
                        title: const Text(
                          'Default Track',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'System default audio track',
                          style: TextStyle(color: Color(0xFFBDBDBD)),
                        ),
                        leading: const Icon(
                          Icons.audiotrack,
                          color: Colors.white,
                        ),
                        trailing: currentState.audioTrackIndex < 0
                            ? const Icon(Icons.check, color: Colors.red)
                            : null,
                        onTap: () {
                          videoController.setAudioTrack(null);
                          Navigator.pop(context);
                        },
                      ),
                      if (currentState.audioTracks.isNotEmpty)
                        ...currentState.audioTracks.asMap().entries.map((
                          entry,
                        ) {
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
                            trailing: currentState.audioTrackIndex == index
                                ? const Icon(Icons.check, color: Colors.red)
                                : null,
                            onTap: () {
                              videoController.setAudioTrack(index);
                              Navigator.pop(context);
                            },
                          );
                        }),
                      if (currentState.audioTracks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No audio tracks available',
                            style: TextStyle(color: Color(0xFFBDBDBD)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const EqualizerWidget(),
    );
  }

  void _showPiPControls(VideoPlayerControllerNotifier videoController) {
    videoController.enterPIP();
  }

  void _showAdvancedSettings(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(videoPlayerControllerProvider);

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Hardware Decoding (HW)',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    settings.useHwDec
                        ? 'Using Hardware Decoder'
                        : 'Using Software Decoder (SW)',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  value: settings.useHwDec,
                  onChanged: (value) {
                    videoController.toggleDecoder();
                    // Close menu to restart player
                    Navigator.pop(context);
                  },
                  activeThumbColor: Colors.red,
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  title: const Text(
                    'Volume Boost',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Current: ${(settings.volumeBoost * 100).toInt()}%',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: SizedBox(
                    width: 120,
                    child: Slider(
                      value: settings.volumeBoost,
                      min: 1.0,
                      max: 2.0,
                      activeColor: Colors.red,
                      onChanged: (value) =>
                          videoController.setVolumeBoost(value),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMoreOptions(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'More Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.subtitles, color: Colors.white),
                title: const Text(
                  'Subtitles',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSubtitleSelection();
                },
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.white),
                title: const Text(
                  'Playback Speed',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSpeedSelection(videoController);
                },
              ),
              ListTile(
                leading: const Icon(Icons.equalizer, color: Colors.white),
                title: const Text(
                  'Equalizer',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEqualizer();
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAdvancedSettings(videoController);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CastingControlsWidget extends StatelessWidget {
  const CastingControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Casting',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.cast, color: Colors.white),
            title: const Text(
              'Available Devices',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class PlaybackSpeedSelectionWidget extends StatelessWidget {
  final VideoPlayerControllerNotifier videoController;
  const PlaybackSpeedSelectionWidget({
    super.key,
    required this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
