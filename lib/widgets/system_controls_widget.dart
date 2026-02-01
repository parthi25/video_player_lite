import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrightnessControlService {
  static double _currentBrightness = 0.5;

  static double get currentBrightness => _currentBrightness;

  static Future<void> setBrightness(double brightness) async {
    _currentBrightness = brightness.clamp(0.0, 1.0);
    // TODO: Implement actual system brightness control using platform channels
    debugPrint('Brightness set to: ${(_currentBrightness * 100).round()}%');
  }

  static Future<double> getSystemBrightness() async {
    // TODO: Get actual system brightness using platform channels
    return _currentBrightness;
  }
}

class VolumeControlService {
  static double _currentVolume = 0.5;

  static double get currentVolume => _currentVolume;

  static Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    // TODO: Implement actual system volume control using platform channels
    debugPrint('Volume set to: ${(_currentVolume * 100).round()}%');
  }

  static Future<double> getSystemVolume() async {
    // TODO: Get actual system volume using platform channels
    return _currentVolume;
  }
}

class BrightnessVolumeIndicator extends ConsumerWidget {
  final double value;
  final String label;
  final IconData icon;
  final bool show;

  const BrightnessVolumeIndicator({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.3,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeekPreviewIndicator extends ConsumerWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final bool show;

  const SeekPreviewIndicator({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show || totalDuration == Duration.zero) return const SizedBox.shrink();

    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fast_forward, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                _formatDuration(currentPosition),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '/ ${_formatDuration(totalDuration)}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: 250,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

class LockScreenWidget extends ConsumerWidget {
  final bool isLocked;
  final VoidCallback onToggleLock;

  const LockScreenWidget({
    super.key,
    required this.isLocked,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLocked) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: onToggleLock,
        child: Container(
          color: Colors.black54,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'Screen Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to unlock',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
