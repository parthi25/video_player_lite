// This file is deprecated - use mx_video_player.dart instead
// Keeping for reference only

import 'package:flutter/material.dart';

class OptimizedVideoPlayer extends StatelessWidget {
  final String? videoUrl;
  final String? videoPath;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final VoidCallback? onVideoEnded;

  const OptimizedVideoPlayer({
    super.key,
    this.videoUrl,
    this.videoPath,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.onVideoEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 64),
            SizedBox(height: 16),
            Text(
              'OptimizedVideoPlayer is deprecated',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Use MXVideoPlayer instead',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
