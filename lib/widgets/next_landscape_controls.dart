import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class NextLandscapeControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool showControls;
  final VoidCallback? onPlayPause;
  final VoidCallback? onFullscreen;
  final Function(Duration)? onSeek;
  final Function(double)? onVolumeChanged;
  final Function(double)? onBrightnessChanged;
  final String? aspectRatio;
  final Function(String)? onAspectRatioChanged;

  const NextLandscapeControls({
    super.key,
    required this.controller,
    this.showControls = true,
    this.onPlayPause,
    this.onFullscreen,
    this.onSeek,
    this.onVolumeChanged,
    this.onBrightnessChanged,
    this.aspectRatio,
    this.onAspectRatioChanged,
  });

  @override
  State<NextLandscapeControls> createState() => _NextLandscapeControlsState();
}

class _NextLandscapeControlsState extends State<NextLandscapeControls>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDragging = false;
  double _dragPosition = 0.0;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _showAspectRatioMenu = false;
  double _volume = 1.0;
  double _brightness = 1.0;
  String _currentAspectRatio = 'Fit';
  bool _isLocked = false;

  final List<String> _aspectRatios = ['Fit', 'Fill', 'Stretch', '16:9', '4:3'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.showControls) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NextLandscapeControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showControls != oldWidget.showControls) {
      if (widget.showControls) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = widget.controller.value.position.inSeconds.toDouble();
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isDragging) return;

    final delta = details.primaryDelta! / screenWidth;
    final totalDuration = widget.controller.value.duration.inSeconds.toDouble();
    final newPosition = (_dragPosition + delta * totalDuration).clamp(
      0.0,
      totalDuration,
    );

    setState(() {
      _dragPosition = newPosition;
    });

    widget.onSeek?.call(Duration(seconds: newPosition.round()));
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    widget.controller.seekTo(Duration(seconds: _dragPosition.round()));
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenHeight) {
    final delta = -details.primaryDelta! / screenHeight;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = details.globalPosition.dx < screenWidth / 2;

    if (isLeftSide) {
      // Brightness control
      setState(() {
        _brightness = (_brightness + delta).clamp(0.0, 1.0);
        _showBrightnessIndicator = true;
      });
      widget.onBrightnessChanged?.call(_brightness);
    } else {
      // Volume control
      setState(() {
        _volume = (_volume + delta).clamp(0.0, 1.0);
        _showVolumeIndicator = true;
      });
      widget.onVolumeChanged?.call(_volume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _showVolumeIndicator = false;
      _showBrightnessIndicator = false;
    });
  }

  void _toggleAspectRatioMenu() {
    setState(() {
      _showAspectRatioMenu = !_showAspectRatioMenu;
    });
  }

  void _selectAspectRatio(String ratio) {
    setState(() {
      _currentAspectRatio = ratio;
      _showAspectRatioMenu = false;
    });
    widget.onAspectRatioChanged?.call(ratio);
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });

    // Lock/unlock screen orientation
    if (_isLocked) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: GestureDetector(
            onTap: () {
              if (widget.showControls && !_isLocked) {
                widget.onPlayPause?.call();
              }
            },
            onHorizontalDragStart: _onHorizontalDragStart,
            onHorizontalDragUpdate: (details) =>
                _onHorizontalDragUpdate(details, screenSize.width),
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onVerticalDragUpdate: (details) =>
                _onVerticalDragUpdate(details, screenSize.height),
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Top controls (landscape optimized)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopControls(isLandscape),
                  ),

                  // Center play button (larger in landscape)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildCenterPlayButton(),
                  ),

                  // Bottom controls (landscape optimized)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControls(isLandscape),
                  ),

                  // Volume indicator
                  if (_showVolumeIndicator)
                    Positioned(
                      right: 20,
                      top: screenSize.height * 0.3,
                      child: _buildVerticalIndicator(
                        Icons.volume_up,
                        _volume,
                        Colors.blue,
                      ),
                    ),

                  // Brightness indicator
                  if (_showBrightnessIndicator)
                    Positioned(
                      left: 20,
                      top: screenSize.height * 0.3,
                      child: _buildVerticalIndicator(
                        Icons.brightness_6,
                        _brightness,
                        Colors.yellow,
                      ),
                    ),

                  // Aspect ratio menu
                  if (_showAspectRatioMenu)
                    Positioned(
                      top: 60,
                      right: 60,
                      child: _buildAspectRatioMenu(),
                    ),

                  // Lock indicator
                  if (_isLocked)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls(bool isLandscape) {
    return Container(
      height: isLandscape ? 50 : 60,
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16 : 8,
        vertical: 8,
      ),
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
          if (!isLandscape)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),

          // Title (shorter in landscape)
          Expanded(
            child: Text(
              isLandscape ? 'MX Player' : 'MX Player Lite',
              style: TextStyle(
                color: Colors.white,
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Controls (more compact in landscape)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Aspect ratio button
              IconButton(
                onPressed: _toggleAspectRatioMenu,
                icon: const Icon(
                  Icons.aspect_ratio,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              // Lock button
              IconButton(
                onPressed: _toggleLock,
                icon: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: _isLocked ? Colors.red : Colors.white,
                  size: 20,
                ),
              ),

              // More options
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final buttonSize = isLandscape ? 80.0 : 70.0;

    return Center(
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: IconButton(
          onPressed: widget.onPlayPause,
          icon: Icon(
            widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: isLandscape ? 40 : 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isLandscape) {
    return Container(
      height: isLandscape ? 60 : 80,
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16 : 8,
        vertical: 8,
      ),
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
          // Progress bar (more prominent in landscape)
          _buildProgressBar(),

          const SizedBox(height: 8),

          // Control buttons (landscape optimized layout)
          Row(
            children: [
              // Current time
              Text(
                _formatDuration(
                  _isDragging
                      ? Duration(seconds: _dragPosition.round())
                      : widget.controller.value.position,
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLandscape ? 12 : 12,
                ),
              ),

              const SizedBox(width: 12),

              // Previous button
              IconButton(
                onPressed: () {
                  // Seek back 10 seconds
                  final newPosition =
                      widget.controller.value.position -
                      const Duration(seconds: 10);
                  widget.onSeek?.call(newPosition);
                },
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              // Play/Pause button
              IconButton(
                onPressed: widget.onPlayPause,
                icon: Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              // Next button
              IconButton(
                onPressed: () {
                  // Seek forward 10 seconds
                  final newPosition =
                      widget.controller.value.position +
                      const Duration(seconds: 10);
                  widget.onSeek?.call(newPosition);
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const Spacer(),

              // Volume button
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 4),

              // Subtitle button
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.subtitles,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 4),

              // Settings button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),

              const SizedBox(width: 4),

              // Fullscreen button
              IconButton(
                onPressed: widget.onFullscreen,
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Total time
              Text(
                _formatDuration(widget.controller.value.duration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isLandscape ? 12 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = _isDragging
        ? _dragPosition
        : widget.controller.value.position.inSeconds.toDouble();
    final duration = widget.controller.value.duration.inSeconds.toDouble();
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
            widget.onSeek?.call(Duration(seconds: newPosition.round()));
          },
        ),
      ),
    );
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

  Widget _buildAspectRatioMenu() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.aspect_ratio, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Aspect Ratio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _toggleAspectRatioMenu,
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),

          // Options
          ..._aspectRatios.map((ratio) => _buildAspectRatioOption(ratio)),
        ],
      ),
    );
  }

  Widget _buildAspectRatioOption(String ratio) {
    final isSelected = ratio == _currentAspectRatio;

    return GestureDetector(
      onTap: () => _selectAspectRatio(ratio),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.red : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 12),
            Text(
              ratio,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
