import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import '../services/favorites_service.dart';

class VideoDetailsScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailsScreen({super.key, required this.video});

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  String? thumbnailPath;
  bool isFavorite = false;
  Duration? _cachedDuration;
  int? _cachedWidth;
  int? _cachedHeight;
  bool _isLoadingMetadata = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
    _loadFavoriteStatus();
    // Load metadata lazily if not already loaded
    if (widget.video.duration == Duration.zero) {
      _loadVideoMetadata();
    } else {
      _cachedDuration = widget.video.duration;
      _cachedWidth = widget.video.width;
      _cachedHeight = widget.video.height;
    }
  }
  
  Future<void> _loadVideoMetadata() async {
    if (_isLoadingMetadata || _cachedDuration != null) return;
    _isLoadingMetadata = true;
    
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(widget.video.file);
      await controller.initialize();
      if (mounted && controller.value.isInitialized) {
        setState(() {
          _cachedDuration = controller!.value.duration;
          _cachedWidth = controller.value.size.width.toInt();
          _cachedHeight = controller.value.size.height.toInt();
        });
      }
    } catch (e) {
      debugPrint('Error loading video metadata: $e');
    } finally {
      try {
        await controller?.dispose();
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
      _isLoadingMetadata = false;
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.video.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 85,
      );
      if (mounted) {
        setState(() => thumbnailPath = path);
      }
    } catch (e) {
      debugPrint('Thumbnail error: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final favorite = await FavoritesService.instance.isFavorite(widget.video.path);
    if (mounted) {
      setState(() => isFavorite = favorite);
    }
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(widget.video.path);
    await _loadFavoriteStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Center(
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumbnailPath != null
                      ? Image.file(
                          File(thumbnailPath!),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.video_library,
                          size: 80,
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Video name
            Text(
              'File Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.video.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            const SizedBox(height: 24),
            
            // Details grid
            _buildDetailsGrid(context),
            
            const SizedBox(height: 24),
            
            // File path
            Text(
              'File Path',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.video.path,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context) {
    final duration = _cachedDuration ?? widget.video.duration;
    final width = _cachedWidth ?? widget.video.width;
    final height = _cachedHeight ?? widget.video.height;
    
    String formattedDuration;
    if (duration == Duration.zero) {
      formattedDuration = _isLoadingMetadata ? 'Loading...' : '--:--:--';
    } else {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      formattedDuration = "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    
    final resolution = width != null && height != null 
        ? '${width}x$height' 
        : 'Unknown';
    
    final details = [
      _DetailItem('Duration', formattedDuration, Icons.timer),
      _DetailItem('File Size', widget.video.formattedSize, Icons.storage),
      _DetailItem('Resolution', resolution, Icons.aspect_ratio),
      _DetailItem(
        'Modified',
        _formatDate(widget.video.lastModified),
        Icons.access_time,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: details.length,
      itemBuilder: (context, index) {
        final detail = details[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    detail.icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detail.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail.value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;

  _DetailItem(this.label, this.value, this.icon);
}