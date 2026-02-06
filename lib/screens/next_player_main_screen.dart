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
import '../services/thumbnail_service.dart';
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
    ThumbnailService.initialize();
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
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
                        colors: [Colors.orange.shade600, Colors.orange.shade800],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Colors.white,
                      size: 28,
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
          onBackPressed: () {
            setState(() {
              _videoPath = null;
              _videoUrl = null;
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme == ThemeMode.dark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: theme == ThemeMode.dark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'NEXT PLAYER',
                style: TextStyle(
                  color: theme == ThemeMode.dark ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme == ThemeMode.dark ? Colors.white54 : Colors.black54,
            ),
            onSelected: (value) {
              switch (value) {
                case 'theme':
                  ref.read(themeModeProvider.notifier).toggleTheme();
                  break;
                case 'cast':
                  break;
                case 'url':
                  _showUrlDialog();
                  break;
                case 'sort':
                  _showSortOptions();
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      theme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(theme == ThemeMode.dark ? 'Light Mode' : 'Dark Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cast',
                child: const Row(
                  children: [
                    Icon(Icons.cast, size: 20),
                    SizedBox(width: 12),
                    Text('Cast'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'url',
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 12),
                    Text('Play URL'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort',
                child: const Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 12),
                    Text('Sort'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: const Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
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
        color: Colors.red.shade600,
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1A1A1A),
                                    const Color(0xFF2A2A2A),
                                  ]
                                : [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.movie_outlined,
                          size: 64,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'No videos found',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pull down to scan for videos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or check your storage permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.orange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _scanVideos(background: false),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Scan Videos',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (_localVideos.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${displayVideos.length} ${displayVideos.length == 1 ? 'video' : 'videos'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = displayVideos[index];
                return _buildVideoListItem(video);
              },
              childCount: displayVideos.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        selected: isActive,
        onSelected: (_) => onTap(),
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[200],
        selectedColor: color.withValues(alpha: isDark ? 0.3 : 0.2),
        labelStyle: TextStyle(
          color: isActive
              ? (isDark ? Colors.white : color)
              : (isDark ? Colors.grey[300] : Colors.grey[700]),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        side: BorderSide.none,
        elevation: isActive ? 4 : 0,
        pressElevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        avatar: isActive
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isDark ? Colors.white : color,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFoldersList() {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    if (_folderNames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No folders found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pull down to scan for videos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_folderNames.length} ${_folderNames.length == 1 ? 'folder' : 'folders'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final folderName = _folderNames[index];
                final videoCount = _foldersMap[folderName]?.length ?? 0;
                return _buildFolderListItem(folderName, videoCount);
              },
              childCount: _folderNames.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoListItem(VideoFile video) {
    final theme = ref.watch(themeModeProvider);
    final isDark = theme == ThemeMode.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playVideo(video.path),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'video_thumb_${video.path}',
                  child: _VideoThumbnailWidget(
                    videoPath: video.path,
                    videoType: video.type,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
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

class _VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final MediaType videoType;

  const _VideoThumbnailWidget({
    required this.videoPath,
    required this.videoType,
  });

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (widget.videoType == MediaType.video) {
      final cached = await ThumbnailService.getThumbnailPath(widget.videoPath);
      if (cached != null && mounted) {
        setState(() {
          _thumbnailPath = cached;
          _isLoading = false;
        });
      } else {
        _generateThumbnail();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateThumbnail() async {
    if (widget.videoType != MediaType.video) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final thumbnail = await ThumbnailService.generateThumbnail(widget.videoPath);
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _isLoading || _thumbnailPath == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.videoType == MediaType.audio
                    ? [Colors.blue.shade600, Colors.blue.shade800]
                    : widget.videoType == MediaType.streaming
                    ? [Colors.purple.shade600, Colors.purple.shade800]
                    : [Colors.red.shade600, Colors.orange.shade700],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (widget.videoType == MediaType.audio
                    ? Colors.blue
                    : (widget.videoType == MediaType.streaming
                          ? Colors.purple
                          : Colors.red))
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _thumbnailPath != null && File(_thumbnailPath!).existsSync()
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_thumbnailPath!),
                width: 100,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.videoType == MediaType.audio
              ? [Colors.blue.shade600, Colors.blue.shade800]
              : widget.videoType == MediaType.streaming
              ? [Colors.purple.shade600, Colors.purple.shade800]
              : [Colors.red.shade600, Colors.orange.shade700],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Icon(
              widget.videoType == MediaType.audio
                  ? Icons.music_note_rounded
                  : widget.videoType == MediaType.streaming
                  ? Icons.sensors_rounded
                  : Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 32,
            ),
    );
  }
}
