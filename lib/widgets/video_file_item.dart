import 'package:flutter/material.dart';
import '../services/file_browser_service.dart';

class VideoFileItem extends StatelessWidget {
  final VideoFile videoFile;
  final VoidCallback onTap;

  const VideoFileItem({
    super.key,
    required this.videoFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_arrow, color: Colors.red, size: 24),
      ),
      title: Text(
        videoFile.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        videoFile.formattedSize,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
