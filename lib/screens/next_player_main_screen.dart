import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'dart:io';

import '../widgets/next_video_player.dart';
import '../services/memory_monitor_service.dart';
import '../services/video_scanner_service.dart';
import '../services/playlist_service.dart';
import '../services/file_browser_service.dart';
import '../services/theme_service.dart';
import '../core/video_player_controller.dart';
import 'settings_screen.dart';

class NextPlayerMainScreen extends ConsumerStatefulWidget {
  const NextPlayerMainScreen({super.key});

  @override
  ConsumerState<NextPlayerMainScreen> createState() =>
      _NextPlayerMainScreenState();
}

class _NextPlayerMainScreenState extends ConsumerState<NextPlayerMainScreen>
    with TickerProviderStateMixin {
  String? _videoUrl;
  String? _videoPath;
  final TextEditingController _urlController = TextEditingController();
  late TabController _tabController;
  List<VideoFile> _localVideos = [];
  List<VideoFile> _filteredVideos = [];
  String? _currentFilter;
  String? _currentFolderName;
  final Map<String, List<VideoFile>> _foldersMap = {};
  final List<String> _folderNames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    MemoryMonitorService.startMonitoring();
    _initializeVideoScanner();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    MemoryMonitorService.stopMonitoring();
    super.dispose();
  }

  Future<void> _initializeVideoScanner() async {
    try {
      final cachedVideos = await VideoScannerService.getCachedVideos();
      if (mounted && cachedVideos.isNotEmpty) {
        setState(() {
          _localVideos = cachedVideos;
          _filteredVideos = cachedVideos;
        });
      }
      await PlaylistService.initialize();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _scanVideos(background: true);
        }
      });
    } catch (e) {
      debugPrint('Error initializing video scanner: $e');
    }
  }

  Future<void> _scanVideos({bool background = false}) async {
    try {
      final videos = await VideoScannerService.scanAllVideos(useCache: false);
      if (mounted) {
        setState(() {
          _localVideos = videos;
          _organizeVideosByFolders();
          _applyFilter();
        });

        if (!background) {
          if (videos.isNotEmpty) {
            _showSuccessSnackBar('Found ${videos.length} files');
          } else {
            _showErrorSnackBar('No files found.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (!background) {
          _showErrorSnackBar('Failed to scan files: ${e.toString()}');
        }
      }
    }
  }

  void _playVideo(String videoPath) {
    // Set current folder in video controller for navigation
    if (_currentFolderName != null &&
        _foldersMap.containsKey(_currentFolderName)) {
      final videoController = ref.read(videoPlayerControllerProvider.notifier);
      videoController.setCurrentFolder(
        _foldersMap[_currentFolderName]!,
        _currentFolderName!,
      );
    }

    setState(() {
      _videoPath = videoPath;
      _videoUrl = null;
    });
  }

  void _organizeVideosByFolders() {
    _foldersMap.clear();
    _folderNames.clear();

    for (final video in _localVideos) {
      final folderPath = video.path.contains(Platform.pathSeparator)
          ? video.path.substring(
              0,
              video.path.lastIndexOf(Platform.pathSeparator),
            )
          : 'Root';
      final folderName = folderPath.contains(Platform.pathSeparator)
          ? folderPath.substring(
              folderPath.lastIndexOf(Platform.pathSeparator) + 1,
            )
          : folderPath;

      if (!_foldersMap.containsKey(folderName)) {
        _foldersMap[folderName] = [];
        _folderNames.add(folderName);
      }
      _foldersMap[folderName]!.add(video);
    }

    _folderNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _onVideoEnded() {
    setState(() {
      _videoUrl = null;
      _videoPath = null;
    });
    _showSuccessSnackBar('Video completed');
  }

  void _applyFilter() {
    setState(() {
      if (_currentFilter == 'folders') {
        // Show folders list
        _filteredVideos = [];
      } else if (_currentFolderName != null) {
        // Show videos from selected folder
        _filteredVideos = _foldersMap[_currentFolderName] ?? [];
      } else if (_currentFilter == null && _currentFolderName == null) {
        // Only show video files
        _filteredVideos = _localVideos
            .where((v) => v.type == MediaType.video)
            .toList();
      } else if (_currentFilter != null) {
        if (_currentFilter == 'videos') {
          _filteredVideos = _localVideos
              .where((v) => v.type == MediaType.video)
              .toList();
        } else {
          // Default to videos only for any other filter
          _filteredVideos = _localVideos
              .where((v) => v.type == MediaType.video)
              .toList();
        }
      } else {
        // Default case - show videos only
        _filteredVideos = _localVideos
            .where((v) => v.type == MediaType.video)
            .toList();
      }
    });
  }

  void _onChipTap(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      if (label == 'Privacy') {
        Navigator.of(context).pushNamed('/vault-auth');
      } else {
        _currentFilter = label.toLowerCase() == 'all'
            ? null
            : label.toLowerCase();
        _currentFolderName = null;
        _applyFilter();
      }
    });
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Play from URL'),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'Enter video URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_urlController.text.isNotEmpty) {
                setState(() {
                  _videoUrl = _urlController.text;
                  _videoPath = null;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sort By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha),
                    title: const Text('Name'),
                    onTap: () {
                      _sortVideos((a, b) => a.name.compareTo(b.name));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.date_range),
                    title: const Text('Date'),
                    onTap: () {
                      _sortVideos(
                        (a, b) => b.lastModified.compareTo(a.lastModified),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.straighten),
                    title: const Text('Size'),
                    onTap: () {
                      _sortVideos((a, b) => b.size.compareTo(a.size));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _sortVideos(int Function(VideoFile, VideoFile) compare) {
    setState(() {
      _localVideos.sort(compare);
      _applyFilter();
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildFolderListItem(String folderName, int videoCount) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentFolderName = folderName;
              _currentFilter = null;
              _applyFilter();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.orange.shade700, Colors.orange.shade900],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$videoCount videos',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    if (_videoPath != null || _videoUrl != null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: NextVideoPlayer(
          videoUrl: _videoUrl,
          videoPath: _videoPath,
          autoPlay: false,
          looping: false,
          onVideoEnded: _onVideoEnded,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme == ThemeMode.dark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: theme == ThemeMode.dark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'NEXT PLAYER',
          style: TextStyle(
            color: theme == ThemeMode.dark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              theme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.cast,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onPressed: _showUrlDialog,
          ),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildChip(
                  'Videos',
                  Icons.movie_outlined,
                  Colors.red,
                  () => _onChipTap('Videos'),
                  isActive: _currentFilter == 'videos',
                ),
                _buildChip(
                  'Folders',
                  Icons.folder_outlined,
                  Colors.orange,
                  () => _onChipTap('Folders'),
                  isActive: _currentFilter == 'folders',
                ),
                _buildChip(
                  'Streaming',
                  Icons.sensors,
                  Colors.purple,
                  () => _onChipTap('Streaming'),
                  isActive: _currentFilter == 'streaming',
                ),
                _buildChip(
                  'Privacy',
                  Icons.lock_outline,
                  Colors.blue,
                  () => _onChipTap('Privacy'),
                ),
                _buildChip(
                  'Share',
                  Icons.share_outlined,
                  Colors.purple,
                  () => _onChipTap('Share'),
                ),
                _buildChip(
                  'Downloads',
                  Icons.download_outlined,
                  Colors.indigo,
                  () => _onChipTap('Downloads'),
                  isActive: _currentFilter == 'downloads',
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _scanVideos(background: false),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    final bool isFiltering =
        _currentFilter != null || _currentFolderName != null;
    final List<VideoFile> displayVideos = isFiltering
        ? _filteredVideos
        : _localVideos;

    // Show folders when folders filter is active
    if (_currentFilter == 'folders') {
      return _buildFoldersList();
    }

    if (displayVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try scanning for videos or check your storage permissions',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayVideos.length,
      itemBuilder: (context, index) {
        final video = displayVideos[index];
        return _buildVideoListItem(video);
      },
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isActive,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isActive ? color : Colors.grey[700],
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide.none,
      elevation: 0,
      pressElevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFoldersList() {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    if (_folderNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No folders found',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan for videos to see folders',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _folderNames.length,
      itemBuilder: (context, index) {
        final folderName = _folderNames[index];
        final videoCount = _foldersMap[folderName]?.length ?? 0;
        return _buildFolderListItem(folderName, videoCount);
      },
    );
  }

  Widget _buildVideoListItem(VideoFile video) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playVideo(video.path),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'video_thumb_${video.path}',
                  child: Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: video.type == MediaType.audio
                            ? [Colors.blue.shade700, Colors.blue.shade900]
                            : video.type == MediaType.streaming
                            ? [Colors.purple.shade700, Colors.purple.shade900]
                            : [Colors.red.shade700, Colors.orange.shade800],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (video.type == MediaType.audio
                                      ? Colors.blue
                                      : (video.type == MediaType.streaming
                                            ? Colors.purple
                                            : Colors.red))
                                  .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      video.type == MediaType.audio
                          ? Icons.music_note_rounded
                          : video.type == MediaType.streaming
                          ? Icons.sensors_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (video.type == MediaType.audio
                                          ? Colors.blue
                                          : (video.type == MediaType.streaming
                                                ? Colors.purple
                                                : Colors.red))
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              video.type == MediaType.audio
                                  ? 'Audio'
                                  : video.type == MediaType.streaming
                                  ? 'Stream'
                                  : 'Video',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: video.type == MediaType.audio
                                    ? Colors.blue.shade600
                                    : video.type == MediaType.streaming
                                    ? Colors.purple.shade600
                                    : Colors.red.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            video.formattedSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'play':
                        _playVideo(video.path);
                        break;
                      case 'info':
                        _showVideoInfo(video);
                        break;
                      case 'share':
                        _shareVideo(video);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text('Play'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text('Info'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVideoInfo(VideoFile video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.name),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Path: ${video.path}'),
              const SizedBox(height: 8),
              Text('Size: ${video.formattedSize}'),
              const SizedBox(height: 8),
              Text('Type: ${video.type.name}'),
              const SizedBox(height: 8),
              Text('Format: ${video.format}'),
              const SizedBox(height: 8),
              Text('Modified: ${video.lastModified}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareVideo(VideoFile video) {
    // Implement share functionality
    _showSuccessSnackBar('Share functionality coming soon!');
  }
}
