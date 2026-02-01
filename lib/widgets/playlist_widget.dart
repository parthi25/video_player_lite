import 'package:flutter/material.dart';
import '../services/playlist_service.dart';

class PlaylistWidget extends StatelessWidget {
  final Playlist? currentPlaylist;
  final int currentVideoIndex;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShowPlaylist;
  final bool isVisible;

  const PlaylistWidget({
    super.key,
    this.currentPlaylist,
    required this.currentVideoIndex,
    this.onPrevious,
    this.onNext,
    this.onShowPlaylist,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || currentPlaylist == null) {
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
              const Icon(Icons.playlist_play, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentPlaylist!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${currentVideoIndex + 1}/${currentPlaylist!.videos.length}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current video info
          if (currentPlaylist!.videos.isNotEmpty &&
              currentVideoIndex < currentPlaylist!.videos.length)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentPlaylist!.videos[currentVideoIndex].name,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Playlist controls
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  icon: Icons.skip_previous,
                  label: 'Previous',
                  onTap: PlaylistService.hasPreviousVideo() ? onPrevious : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.list,
                  label: 'Playlist',
                  onTap: onShowPlaylist,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildControlButton(
                  icon: Icons.skip_next,
                  label: 'Next',
                  onTap: PlaylistService.hasNextVideo() ? onNext : null,
                ),
              ),
            ],
          ),

          // Mini playlist preview
          if (currentPlaylist!.videos.length > 1)
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentPlaylist!.videos.length,
                itemBuilder: (context, index) {
                  final isCurrentVideo = index == currentVideoIndex;

                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isCurrentVideo
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentVideo ? Colors.red : Colors.grey[600]!,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.movie,
                            color: isCurrentVideo
                                ? Colors.red
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                        if (isCurrentVideo)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: onTap != null ? Colors.grey[800] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: onTap != null ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? Colors.white : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistButton extends StatelessWidget {
  final Playlist? currentPlaylist;
  final int currentVideoIndex;
  final VoidCallback onTap;

  const PlaylistButton({
    super.key,
    this.currentPlaylist,
    required this.currentVideoIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlaylist =
        currentPlaylist != null && currentPlaylist!.videos.isNotEmpty;

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
              Icons.playlist_play,
              color: hasPlaylist ? Colors.red : Colors.grey,
              size: 16,
            ),
            const SizedBox(height: 2),
            if (hasPlaylist)
              Text(
                '${currentVideoIndex + 1}',
                style: const TextStyle(
                  color: Colors.red,
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

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = PlaylistService.getPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Playlists',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No playlists yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create playlists from the file browser',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return _buildPlaylistItem(playlist);
              },
            ),
    );
  }

  Widget _buildPlaylistItem(Playlist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop(playlist);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${playlist.videos.length} videos',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(playlist.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow, color: Colors.red, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }
}
