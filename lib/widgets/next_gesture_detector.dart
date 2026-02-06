import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../services/system_controls_service.dart';

class NextGestureDetector extends ConsumerStatefulWidget {
  final Widget child;
  final Function(Duration) onSeek;
  final Function(double) onVolumeChanged;
  final Function(double) onBrightnessChanged;

  const NextGestureDetector({
    super.key,
    required this.child,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onBrightnessChanged,
  });

  @override
  ConsumerState<NextGestureDetector> createState() =>
      _NextGestureDetectorState();
}

class _NextGestureDetectorState extends ConsumerState<NextGestureDetector> {
  double _dragStartX = 0;
  double _dragStartY = 0;
  Duration _dragStartPosition = Duration.zero;
  bool _isSeeking = false;
  bool _isAdjustingVolume = false;
  bool _isAdjustingBrightness = false;

  // Initial values for gestures
  double _startVolume = 0.5;
  double _startBrightness = 0.5;

  // Gesture indicators
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _showSeekIndicator = false;
  bool _showSpeedIndicator = false;
  bool _isForwardSpeed = true;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  Duration _seekPosition = Duration.zero;
  bool _showSkipForward = false;
  bool _showSkipBack = false;
  Timer? _skipTimer;

  @override
  Widget build(BuildContext context) {
    // Removed full state watch to prevent rebuilds
    // final videoState = ref.watch(videoPlayerControllerProvider);

    return GestureDetector(
      onTap: () {
        final videoState = ref.read(videoPlayerControllerProvider);
        if (videoState.isLocked) return;
        // Toggle controls visibility
        final videoController = ref.read(
          videoPlayerControllerProvider.notifier,
        );
        videoController.toggleControls();
      },
      onDoubleTapDown: (details) {
        final videoState = ref.read(videoPlayerControllerProvider);
        if (videoState.isLocked) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final videoController = ref.read(
          videoPlayerControllerProvider.notifier,
        );
        final videoStateCurrent = ref.read(videoPlayerControllerProvider);

        if (details.globalPosition.dx < screenWidth / 3) {
          // Left side -> Rewind
          final newPosition =
              videoStateCurrent.position - const Duration(seconds: 10);
          videoController.seekTo(newPosition);
          _showSkipIndicator(false);
        } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
          // Right side -> Fast Forward
          final newPosition =
              videoStateCurrent.position + const Duration(seconds: 10);
          videoController.seekTo(newPosition);
          _showSkipIndicator(true);
        } else {
          // Center -> Toggle play/pause (original behavior)
          videoController.togglePlayPause();
        }
      },
      onLongPressStart: (details) {
        final videoState = ref.read(videoPlayerControllerProvider);
        if (videoState.isLocked) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final videoController = ref.read(
          videoPlayerControllerProvider.notifier,
        );

        if (details.globalPosition.dx > screenWidth / 2) {
          // Right side long press -> 2x Speed Forward
          videoController.setPlaybackSpeed(2.0);
          setState(() {
            _showSpeedIndicator = true;
            _isForwardSpeed = true;
          });
        } else {
          // Left side long press -> 2x Speed Backward (Rewind)
          // media_kit supports negative rates for reverse playback
          videoController.setPlaybackSpeed(-2.0);
          setState(() {
            _showSpeedIndicator = true;
            _isForwardSpeed = false;
          });
        }
      },
      onLongPressEnd: (details) {
        _endSpeedup();
      },
      onLongPressUp: () {
        _endSpeedup();
      },
      onHorizontalDragStart: (details) {
        final videoState = ref.read(videoPlayerControllerProvider);
        if (videoState.isLocked) return;
        _dragStartX = details.globalPosition.dx;
        _dragStartPosition = videoState.position;
        _isSeeking = true;
        _showSeekIndicator = true;
        _seekPosition = _dragStartPosition;
      },
      onHorizontalDragUpdate: (details) {
        if (!_isSeeking) return;

        final videoState = ref.read(videoPlayerControllerProvider);
        final screenWidth = MediaQuery.of(context).size.width;
        final deltaX = details.globalPosition.dx - _dragStartX;
        final percentage = deltaX / screenWidth;

        final seekAmount = Duration(
          milliseconds: (videoState.duration.inMilliseconds * percentage)
              .round(),
        );

        _seekPosition = Duration(
          milliseconds: (_dragStartPosition + seekAmount).inMilliseconds.clamp(
            0,
            videoState.duration.inMilliseconds,
          ),
        );

        setState(() {});
      },
      onHorizontalDragEnd: (details) {
        if (_isSeeking) {
          widget.onSeek(_seekPosition);
          _isSeeking = false;
          _showSeekIndicator = false;
          setState(() {});
        }
      },
      onVerticalDragStart: (details) async {
        final videoState = ref.read(videoPlayerControllerProvider);
        if (videoState.isLocked) return;
        _dragStartY = details.globalPosition.dy;
        final screenWidth = MediaQuery.of(context).size.width;

        // Determine if we're adjusting volume (right side) or brightness (left side)
        if (details.globalPosition.dx > screenWidth / 2) {
          _isAdjustingVolume = true;
          _showVolumeIndicator = true;
          // Use player volume as baseline if system volume fails
          _startVolume = videoState.volume / 100.0;
          _currentVolume = _startVolume;
        } else {
          _isAdjustingBrightness = true;
          _showBrightnessIndicator = true;
          _startBrightness = await SystemControlsService.getCurrentBrightness();
          _currentBrightness = _startBrightness;
        }
      },
      onVerticalDragUpdate: (details) {
        if (!_isAdjustingVolume && !_isAdjustingBrightness) return;

        final screenHeight = MediaQuery.of(context).size.height;
        // Dragging UP (negative dy) should INCREASE value, so we subtract delta
        final deltaY = (_dragStartY - details.globalPosition.dy) / screenHeight;

        // Scale factor to make controls more responsive (1.5x sensitivity)
        final scaledDelta = deltaY * 1.5;

        if (_isAdjustingVolume) {
          _currentVolume = (_startVolume + scaledDelta).clamp(0.0, 2.0);
          widget.onVolumeChanged(_currentVolume);
          // Set actual system volume (system only supports 0-1)
          SystemControlsService.setVolume(_currentVolume.clamp(0.0, 1.0));
        } else if (_isAdjustingBrightness) {
          _currentBrightness = (_startBrightness + scaledDelta).clamp(0.0, 1.0);
          widget.onBrightnessChanged(_currentBrightness);
          // Set actual system brightness
          SystemControlsService.setBrightness(_currentBrightness);
        }

        setState(() {});
      },
      onVerticalDragEnd: (details) {
        _isAdjustingVolume = false;
        _isAdjustingBrightness = false;
        _showVolumeIndicator = false;
        _showBrightnessIndicator = false;
        setState(() {});
      },
      child: Stack(
        children: [
          // Main content
          widget.child,

          // Speed Indicator
          if (_showSpeedIndicator)
            Positioned(
              top: 80,
              left: _isForwardSpeed ? null : 40,
              right: _isForwardSpeed ? 40 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isForwardSpeed ? Icons.fast_forward : Icons.fast_rewind,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isForwardSpeed ? '2.0x Playing' : '2.0x Rewinding',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Volume indicator (Centered)
          if (_showVolumeIndicator)
            Center(
              child: _buildCenterIndicator(
                _currentVolume > 0 
                  ? (_currentVolume >= 0.5 ? Icons.volume_up : Icons.volume_down)
                  : Icons.volume_off,
                _currentVolume,
                _currentVolume > 1.0 ? Colors.red : Colors.blue,
                isVolume: true,
              ),
            ),

          // Brightness indicator (Centered)
          if (_showBrightnessIndicator)
            Center(
              child: _buildCenterIndicator(
                _currentBrightness > 0.5 ? Icons.brightness_7 : Icons.brightness_6,
                _currentBrightness,
                Colors.orange,
              ),
            ),

          // Skip Indicators (Double tap)
          if (_showSkipBack)
            Positioned(
              left: 50,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_rewind, color: Colors.white, size: 48),
                    Text(
                      "-10s",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_showSkipForward)
            Positioned(
              right: 50,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fast_forward, color: Colors.white, size: 48),
                    Text(
                      "+10s",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Seek indicator
          if (_showSeekIndicator)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final duration = ref.watch(
                    videoPlayerControllerProvider.select((s) => s.duration),
                  );
                  return _buildSeekIndicator(duration);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showSkipIndicator(bool forward) {
    _skipTimer?.cancel();
    setState(() {
      if (forward) {
        _showSkipForward = true;
        _showSkipBack = false;
      } else {
        _showSkipBack = true;
        _showSkipForward = false;
      }
    });
    _skipTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSkipForward = false;
          _showSkipBack = false;
        });
      }
    });
  }

  Widget _buildCenterIndicator(IconData icon, double value, Color color, {bool isVolume = false}) {
    // For volume boost, we show a special label
    final isBoost = isVolume && value > 1.0;
    // Normalize value for display (0-100% or more for boost)
    final displayValue = (value * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isBoost ? Colors.red : color,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isBoost ? 'Boost: $displayValue%' : '$displayValue%',
            style: TextStyle(
              color: isBoost ? Colors.red : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: isVolume ? (value / 2.0).clamp(0.0, 1.0) : value.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isBoost ? Colors.red : color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator(Duration duration) {
    final percentage = duration.inMilliseconds > 0
        ? (_seekPosition.inMilliseconds /
              duration.inMilliseconds *
              100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _seekPosition < _dragStartPosition
                    ? Icons.fast_rewind
                    : Icons.fast_forward,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_seekPosition),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[600],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _endSpeedup() {
    if (_showSpeedIndicator) {
      final videoController = ref.read(videoPlayerControllerProvider.notifier);
      videoController.setPlaybackSpeed(1.0);
      setState(() {
        _showSpeedIndicator = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
