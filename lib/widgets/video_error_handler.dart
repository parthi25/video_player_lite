import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';

class CodecErrorHandler {
  static bool _isHEVCUnsupported = false;
  static String? _lastFailedVideo;

  static bool isHEVCUnsupported(String? videoPath) {
    if (videoPath == null) return false;

    // Check if we already know this device has HEVC issues
    if (_isHEVCUnsupported) return true;

    // Check if this specific video failed before
    if (_lastFailedVideo == videoPath) return true;

    return false;
  }

  static void markHEVCUnsupported(String videoPath) {
    _isHEVCUnsupported = true;
    _lastFailedVideo = videoPath;
    debugPrint('HEVC codec marked as unsupported for this device');
  }

  static void reset() {
    _isHEVCUnsupported = false;
    _lastFailedVideo = null;
  }

  static String getUnsupportedMessage() {
    return 'HEVC (H.265) codec is not supported on this device. Try converting the video to H.264 format or use a different video.';
  }
}

class VideoPlayerErrorHandler extends ConsumerStatefulWidget {
  final Widget child;
  final String? videoPath;
  final String? videoUrl;
  final VoidCallback? onRetry;

  const VideoPlayerErrorHandler({
    super.key,
    required this.child,
    this.videoPath,
    this.videoUrl,
    this.onRetry,
  });

  @override
  ConsumerState<VideoPlayerErrorHandler> createState() =>
      _VideoPlayerErrorHandlerState();
}

class _VideoPlayerErrorHandlerState
    extends ConsumerState<VideoPlayerErrorHandler> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  void _retryPlayback() {
    setState(() {
      _hasError = false;
    });

    CodecErrorHandler.reset();
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for error states - this is the correct place for ref.listen
    ref.listen<VideoPlayerState>(videoPlayerControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = next.errorMessage ?? 'Unknown error occurred';
        });
      } else if (!next.hasError && _hasError) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
      }
    });

    if (_hasError) {
      return _buildErrorScreen();
    }

    return widget.child;
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Playback Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : CodecErrorHandler.getUnsupportedMessage(),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: _retryPlayback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
