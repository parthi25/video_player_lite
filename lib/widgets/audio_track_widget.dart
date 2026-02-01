import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';

class AudioTrackWidget extends ConsumerWidget {
  const AudioTrackWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoPlayerControllerProvider);

    // Mock audio tracks for demonstration
    final audioTracks = [
      {'index': 0, 'language': 'English', 'label': 'Default'},
      {'index': 1, 'language': 'Spanish', 'label': 'Español'},
      {'index': 2, 'language': 'French', 'label': 'Français'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          ...audioTracks.map(
            (track) => RadioListTile<int>(
              title: Text(track['label'] as String),
              subtitle: Text(track['language'] as String),
              value: track['index'] as int,
              selected: videoState.audioTrackIndex == (track['index'] as int),
              toggleable: true,
            ),
          ),
        ],
      ),
    );
  }
}
