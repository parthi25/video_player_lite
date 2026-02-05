import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../widgets/subtitle_selection_widget.dart';
import '../services/playlist_service.dart';
import '../screens/video_cutter_screen.dart';

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
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _fadeController.status == AnimationStatus.completed) {
        _fadeController.reverse();
      }
    });
  }

  void _toggleControlsVisibility() {
    if (_fadeController.status == AnimationStatus.completed) {
      _fadeController.reverse();
    } else {
      _fadeController.forward();
      _startHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoPlayerControllerProvider);
    final videoController = ref.read(videoPlayerControllerProvider.notifier);

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
              if (!videoState.isLocked)
                _buildTopControls(videoState, videoController),
              _buildBottomControls(videoState, videoController),
              if (videoState.isLocked)
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.lock, color: Colors.white, size: 64),
                    onPressed: () => videoController.toggleLock(),
                  ),
                ),
              if (_showSidePanel && !videoState.isLocked)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: _buildSidePanel(videoState, videoController),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
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
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    videoState.videoPath?.split(Platform.pathSeparator).last ??
                        'Video Player',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              alignment: isLandscape
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: _buildActionRibbon(videoState, videoController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRibbon(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
        _getRotationIcon(videoState.orientation),
        () => _showRotationControls(videoController),
        color: _getRotationColor(videoState.orientation),
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

  Widget _buildBottomControls(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
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
                if (!videoState.isLocked) ...[
                  Row(
                    children: [
                      Text(
                        _formatDuration(videoState.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: Colors.red,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.red,
                          ),
                          child: Slider(
                            min: 0.0,
                            max: videoState.duration.inMilliseconds.toDouble(),
                            value: videoState.position.inMilliseconds
                                .toDouble()
                                .clamp(
                                  0.0,
                                  videoState.duration.inMilliseconds.toDouble(),
                                ),
                            onChanged: (value) {
                              _startHideTimer();
                              videoController.seekTo(
                                Duration(milliseconds: value.round()),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(videoState.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLockButton(videoState, videoController),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => _playPrevious(videoController),
                          ),
                          const SizedBox(width: 12),
                          _buildPlayPauseButton(videoState, videoController),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => _playNext(videoController),
                          ),
                        ],
                      ),
                      _buildAspectRatioButton(videoState, videoController),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Center(child: _buildLockButton(videoState, videoController)),
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
    final prev = PlaylistService.getPreviousVideo();
    if (prev != null) {
      await videoController.initializeVideo(null, prev.path);
    }
  }

  Future<void> _playNext(VideoPlayerControllerNotifier videoController) async {
    final next = PlaylistService.getNextVideo();
    if (next != null) {
      await videoController.initializeVideo(null, next.path);
    }
  }

  Widget _buildPlayPauseButton(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
    return GestureDetector(
      onTap: () {
        _startHideTimer();
        videoController.togglePlayPause();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          videoState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLockButton(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
    return Material(
      color: videoState.isLocked
          ? Colors.red.withValues(alpha: 0.6)
          : Colors.white12,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          _startHideTimer();
          videoController.toggleLock();
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            videoState.isLocked ? Icons.lock : Icons.lock_open,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildAspectRatioButton(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
    return Material(
      color: Colors.white12,
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
            _getAspectRatioIcon(videoState.aspectRatioMode),
            color: Colors.white,
            size: 22,
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

  Widget _buildSidePanel(
    VideoPlayerState videoState,
    VideoPlayerControllerNotifier videoController,
  ) {
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
      builder: (context) => const CastingControlsWidget(),
    );
  }

  void _showSpeedSelection(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
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

  void _showAudioTrackSelection(
    VideoPlayerControllerNotifier videoController,
  ) {}

  void _showEqualizer() {}

  void _showPiPControls(VideoPlayerControllerNotifier videoController) {
    videoController.enterPIP();
  }

  void _showAdvancedSettings(VideoPlayerControllerNotifier videoController) {}

  void _showMoreOptions(VideoPlayerControllerNotifier videoController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
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
          ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map(
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
          ),
        ],
      ),
    );
  }
}
