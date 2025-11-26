import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import '../services/favorites_service.dart';

class VideoThumbnailItem extends StatefulWidget {
  final VideoModel video;
  final VoidCallback? onPlay;
  final VoidCallback? onFavoriteChanged;

  const VideoThumbnailItem({
    super.key,
    required this.video,
    this.onPlay,
    this.onFavoriteChanged,
  });

  @override
  State<VideoThumbnailItem> createState() => _VideoThumbnailItemState();
}

class _VideoThumbnailItemState extends State<VideoThumbnailItem>
    with SingleTickerProviderStateMixin {
  String? thumbnailPath;
  bool isLoading = true;
  bool isFavorite = false;
  bool _isLoadingMetadata = false;
  Duration? _cachedDuration;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _generateThumbnail();
    _loadFavoriteStatus();
    // Load metadata lazily if not already loaded
    if (widget.video.duration == Duration.zero) {
      _loadVideoMetadata();
    } else {
      _cachedDuration = widget.video.duration;
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateThumbnail() async {
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.video.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          thumbnailPath = path;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Thumbnail error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
    widget.onFavoriteChanged?.call();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPlay,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildThumbnail(),
                  ),
                  
                  // Gradient overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Play button
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  
                  // Video info
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.video.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getFormattedDuration(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Text(
                              widget.video.formattedSize,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Loading indicator
                  if (isLoading)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnail() {
    if (thumbnailPath != null) {
      return Image.file(
        File(thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.video_library,
        size: 50,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  String _getFormattedDuration() {
    final duration = _cachedDuration ?? widget.video.duration;
    if (duration == Duration.zero) return '--:--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }
}