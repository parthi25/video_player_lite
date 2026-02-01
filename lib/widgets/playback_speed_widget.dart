import 'package:flutter/material.dart';

class PlaybackSpeedWidget extends StatelessWidget {
  final double currentSpeed;
  final Function(double) onSpeedChanged;
  final bool isVisible;

  const PlaybackSpeedWidget({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
    this.isVisible = false,
  });

  static const List<double> availableSpeeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Playback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  onSpeedChanged(1.0); // Reset to normal speed
                },
                icon: Icon(
                  Icons.refresh,
                  color: currentSpeed == 1.0 ? Colors.red : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speed slider
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0.25x',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      '${currentSpeed.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '2.0x',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.grey[600],
                    thumbColor: Colors.red,
                    overlayColor: Colors.red.withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: currentSpeed,
                    min: 0.25,
                    max: 2.0,
                    divisions: 7,
                    onChanged: onSpeedChanged,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quick speed buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSpeeds.map((speed) {
              final isSelected = speed == currentSpeed;
              return GestureDetector(
                onTap: () => onSpeedChanged(speed),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${speed.toStringAsFixed(2)}x',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class SpeedControlButton extends StatelessWidget {
  final double currentSpeed;
  final VoidCallback onTap;

  const SpeedControlButton({
    super.key,
    required this.currentSpeed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed,
              color: currentSpeed != 1.0 ? Colors.red : Colors.grey,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              '${currentSpeed.toStringAsFixed(1)}x',
              style: TextStyle(
                color: currentSpeed != 1.0 ? Colors.red : Colors.grey,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
