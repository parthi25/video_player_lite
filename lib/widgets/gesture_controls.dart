import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class GestureControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onTogglePlayPause;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onToggleFullscreen;
  final Function(double)? onVolumeChanged;
  final Function(double)? onBrightnessChanged;

  const GestureControls({
    super.key,
    required this.controller,
    this.onTogglePlayPause,
    this.onSeekForward,
    this.onSeekBackward,
    this.onToggleFullscreen,
    this.onVolumeChanged,
    this.onBrightnessChanged,
  });

  @override
  State<GestureControls> createState() => _GestureControlsState();
}

class _GestureControlsState extends State<GestureControls> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _volume = 1.0;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    _resetHideControlsTimer();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetHideControlsTimer();
    }
  }

  void _handleTap() {
    _toggleControls();
    widget.onTogglePlayPause?.call();
  }

  void _handleDoubleTap() {
    widget.onTogglePlayPause?.call();
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercentage = details.primaryDelta! / screenWidth;
    final seekAmount = Duration(
      milliseconds: (dragPercentage * 10000).round(), // 10 seconds max
    );

    Duration newPosition;
    if (details.primaryDelta! > 0) {
      newPosition = widget.controller.value.position - seekAmount;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > widget.controller.value.duration) {
        newPosition = widget.controller.value.duration;
      }
    } else {
      newPosition = widget.controller.value.position + seekAmount.abs();
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > widget.controller.value.duration) {
        newPosition = widget.controller.value.duration;
      }
    }

    widget.controller.seekTo(newPosition);
  }

  void _handleVerticalDrag(DragUpdateDetails details, bool onLeftSide) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dragPercentage = -details.primaryDelta! / screenHeight;

    if (onLeftSide) {
      // Adjust brightness
      setState(() {
        _brightness = (_brightness + dragPercentage).clamp(0.0, 1.0);
      });
      widget.onBrightnessChanged?.call(_brightness);
    } else {
      // Adjust volume
      setState(() {
        _volume = (_volume + dragPercentage).clamp(0.0, 1.0);
      });
      widget.onVolumeChanged?.call(_volume);
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      onHorizontalDragUpdate: _handleHorizontalDrag,
      onHorizontalDragEnd: (_) => _resetHideControlsTimer(),
      onVerticalDragUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLeftSide = details.globalPosition.dx < screenWidth / 2;
        _handleVerticalDrag(details, isLeftSide);
      },
      onVerticalDragEnd: (_) => _resetHideControlsTimer(),
      child: Stack(
        children: [
          // Video content (passed through)
          Container(),

          // Volume indicator
          if (_showControls)
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height * 0.3,
              child: _buildVerticalIndicator(
                Icons.volume_up,
                _volume,
                Colors.blue,
              ),
            ),

          // Brightness indicator
          if (_showControls)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.3,
              child: _buildVerticalIndicator(
                Icons.brightness_6,
                _brightness,
                Colors.yellow,
              ),
            ),

          // Center play/pause indicator
          if (_showControls)
            Center(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalIndicator(IconData icon, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 40,
                height: 100 * value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
