import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_pip_mode/simple_pip.dart';
import 'package:flutter_screen_brightness/flutter_screen_brightness.dart';
import 'package:volume/volume.dart';

// Local imports
import 'models/video_model.dart';
import 'services/video_scanner_service.dart';
import 'services/favorites_service.dart';
import 'utils/app_theme.dart';
import 'utils/responsive_grid.dart';
import 'utils/theme_preferences.dart';
import 'utils/recent_files_service.dart';
import 'widgets/video_thumbnail_item.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/sort_options_widget.dart';
import 'screens/video_details_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/audio_player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await ThemePreferences.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = themeMode;
      });
    }
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemePreferences.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Video Player',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: VideoPlayerHomePage(
        onThemeModeChanged: updateThemeMode,
        currentThemeMode: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VideoPlayerHomePage extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const VideoPlayerHomePage({
    super.key,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<VideoPlayerHomePage> createState() => _VideoPlayerHomePageState();
}

class _VideoPlayerHomePageState extends State<VideoPlayerHomePage> {
  final List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  final Map<String, List<VideoModel>> _folderVideos = {};
  final List<String> _folders = [];
  String? _selectedFolder;
  bool _isScanning = false;
  int _selectedIndex = 0;
  final SimplePip _pip = SimplePip();

  // Search and sort
  String _searchQuery = '';
  SortOption _currentSort = SortOption.name;
  SortOrder _currentOrder = SortOrder.ascending;
  Timer? _searchDebounceTimer;

  // Scan progress
  String _scanMessage = '';
  double _scanProgress = 0.0;

  // Player mode
  bool _isAudioMode = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _scanForVideos();
    // Initialize with empty filtered list
    _applyFiltersAndSort();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      // Web doesn't need storage permissions
      return;
    }

    if (!Platform.isAndroid) {
      return;
    }

    try {
      // For Android 13+ (API 33+), use READ_MEDIA_VIDEO
      // For Android 12 (API 31-32), use READ_EXTERNAL_STORAGE
      // Try videos permission first (Android 13+)
      try {
        var videoStatus = await Permission.videos.status;
        if (!videoStatus.isGranted) {
          await Permission.videos.request();
        }
        // If videos permission works, we're done (Android 13+)
        return;
      } catch (e) {
        // Videos permission not available, fall through to storage permission
        debugPrint(
          'Videos permission not available (likely Android 12 or below): $e',
        );
      }

      // For Android 12 and below, use storage permission
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        await Permission.storage.request();
      }
    } catch (e) {
      debugPrint('Permission check failed: $e');
    }
  }

  Future<void> _scanForVideos() async {
    setState(() {
      _isScanning = true;
      _scanMessage = 'Starting scan...';
      _scanProgress = 0.0;
    });

    try {
      await for (final progress
          in VideoScannerService.instance.scanForVideos()) {
        if (!mounted) break;

        setState(() {
          _scanMessage = progress.message;
          _scanProgress = progress.progress;
        });

        if (progress.status == ScanStatus.completed) {
          _allVideos.clear();
          _allVideos.addAll(progress.videos);
          _organizeVideosByFolder();
          _applyFiltersAndSort();
          setState(() => _isScanning = false);
          break;
        } else if (progress.status == ScanStatus.error) {
          setState(() => _isScanning = false);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(progress.message)));
          }
          break;
        }
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning videos: $e')));
      }
    }
  }

  void _organizeVideosByFolder() {
    _folderVideos.clear();
    _folders.clear();
    final Set<String> folderSet = {}; // Use Set for O(1) lookup

    for (final video in _allVideos) {
      final folder = video.file.parent.path.split('/').last;
      _folderVideos.putIfAbsent(folder, () => []);
      _folderVideos[folder]!.add(video);
      folderSet.add(folder);
    }

    _folders.addAll(folderSet);
    _folders.sort();
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        // Create VideoModel objects for picked files
        for (final path in result.paths) {
          if (path != null) {
            try {
              final file = File(path);
              if (!await file.exists()) {
                debugPrint('File does not exist: $path');
                continue;
              }
              final stat = await file.stat();
              final video = VideoModel(
                file: file,
                name: file.path.split('/').last,
                path: file.path,
                size: stat.size,
                duration: Duration
                    .zero, // Will be updated when thumbnail is generated
                lastModified: stat.modified,
              );
              _allVideos.add(video);
            } catch (e) {
              debugPrint('Error processing picked file $path: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error loading file: ${path.split('/').last}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          }
        }
        _organizeVideosByFolder();
        _applyFiltersAndSort();
      }
    } catch (e) {
      debugPrint('Error picking videos: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking videos: $e')));
      }
    }
  }

  void _onFolderSelected(String folder) {
    setState(() => _selectedFolder = folder);
    Navigator.pop(context);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    // Debounce search to avoid excessive filtering
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _applyFiltersAndSort();
        });
      }
    });
  }

  void _onSortChanged(SortOption sort) {
    _currentSort = sort;
    _applyFiltersAndSort();
  }

  void _onOrderChanged(SortOrder order) {
    _currentOrder = order;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    // Get base list - avoid unnecessary copying
    final baseList = _selectedFolder != null
        ? _folderVideos[_selectedFolder] ?? []
        : _allVideos;

    // Apply search filter efficiently
    final filtered = _searchQuery.isEmpty
        ? baseList
        : baseList
              .where((video) => video.name.toLowerCase().contains(_searchQuery))
              .toList();

    // Sort in-place to avoid extra copy
    filtered.sort((a, b) {
      int comparison;
      switch (_currentSort) {
        case SortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortOption.dateModified:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case SortOption.size:
          comparison = a.size.compareTo(b.size);
          break;
        case SortOption.duration:
          comparison = a.duration.compareTo(b.duration);
          break;
      }
      return _currentOrder == SortOrder.ascending ? comparison : -comparison;
    });

    setState(() {
      _filteredVideos = filtered;
    });
  }

  Future<List<VideoModel>> _getFavoriteVideos() async {
    final favorites = await FavoritesService.instance.getFavorites();
    return _allVideos.where((video) => favorites.contains(video.path)).toList();
  }

  Future<List<VideoModel>> _getRecentVideos() async {
    final recent = await RecentFilesService.instance.getRecentVideos();
    return _allVideos.where((video) => recent.contains(video.path)).toList();
  }

  Widget _buildRecentView() {
    return FutureBuilder<List<VideoModel>>(
      future: _getRecentVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final recent = snapshot.data ?? [];

        if (recent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent videos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Play videos to see them here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveGrid.getCrossAxisCount(context),
            childAspectRatio: ResponsiveGrid.getChildAspectRatio(context),
            crossAxisSpacing: ResponsiveGrid.getSpacing(context),
            mainAxisSpacing: ResponsiveGrid.getSpacing(context),
          ),
          padding: ResponsiveGrid.getPadding(context),
          itemCount: recent.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () => _showVideoDetails(recent[index]),
              child: VideoThumbnailItem(
                video: recent[index],
                onPlay: () => _playVideo(recent[index]),
                onFavoriteChanged: () => setState(() {}),
              ),
            );
          },
        );
      },
    );
  }

  void _enterPIP() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture-in-picture not available on web'),
        ),
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        await _pip.enterPipMode();
      }
    } catch (e) {
      debugPrint('PiP mode failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Picture-in-picture not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Video Player'),
        actions: [
          if (_selectedIndex == 0) ...[
            SortOptionsWidget(
              currentSort: _currentSort,
              currentOrder: _currentOrder,
              onSortChanged: _onSortChanged,
              onOrderChanged: _onOrderChanged,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanForVideos,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
                case 'pip':
                  _enterPIP();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'pip',
                child: ListTile(
                  leading: Icon(Icons.picture_in_picture_alt),
                  title: Text('Picture in Picture'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'All Videos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Folders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Recent',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickVideos,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Center(
              child: Text(
                _isAudioMode ? 'Audio Player' : 'Video Player',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          // Dark mode toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(_getThemeModeText(widget.currentThemeMode)),
            secondary: Icon(
              widget.currentThemeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : widget.currentThemeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
            ),
            value: widget.currentThemeMode == ThemeMode.dark,
            onChanged: (value) {
              final newMode = value ? ThemeMode.dark : ThemeMode.light;
              widget.onThemeModeChanged(newMode);
            },
          ),
          // MP3/Audio player mode toggle
          SwitchListTile(
            title: const Text('MP3 Player Mode'),
            subtitle: Text(
              _isAudioMode ? 'Audio mode active' : 'Video mode active',
            ),
            secondary: Icon(
              _isAudioMode ? Icons.audiotrack : Icons.video_library,
            ),
            value: _isAudioMode,
            onChanged: (value) {
              setState(() {
                _isAudioMode = value;
              });
              Navigator.pop(context);
              if (_isAudioMode) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AudioPlayerScreen(),
                  ),
                );
              }
            },
          ),
          const Divider(),
          // Video folders section
          if (!_isAudioMode) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Video Folders',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (context, i) {
                  final folder = _folders[i];
                  final count = _folderVideos[folder]?.length ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder),
                    subtitle: Text('$count videos'),
                    onTap: () => _onFolderSelected(folder),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: Text('Switch to video mode to see folders')),
            ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Widget _buildBody() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _scanProgress),
            const SizedBox(height: 16),
            Text(_scanMessage),
            const SizedBox(height: 8),
            Text('${(_scanProgress * 100).toInt()}%'),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildAllVideos();
      case 1:
        return _buildFolderView();
      case 2:
        return _buildFavoritesView();
      case 3:
        return _buildRecentView();
      default:
        return _buildAllVideos();
    }
  }

  Widget _buildAllVideos() {
    return Column(
      children: [
        SearchBarWidget(
          onChanged: _onSearchChanged,
          onClear: () => _applyFiltersAndSort(),
        ),
        Expanded(
          child: _filteredVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No videos match your search'
                            : kIsWeb
                            ? 'No videos found. Use the + button to add videos.'
                            : 'No videos found',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Video scanning is not available on web. Please use the file picker to add videos.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveGrid.getCrossAxisCount(context),
                    childAspectRatio: ResponsiveGrid.getChildAspectRatio(
                      context,
                    ),
                    crossAxisSpacing: ResponsiveGrid.getSpacing(context),
                    mainAxisSpacing: ResponsiveGrid.getSpacing(context),
                  ),
                  padding: ResponsiveGrid.getPadding(context),
                  itemCount: _filteredVideos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onLongPress: () =>
                          _showVideoDetails(_filteredVideos[index]),
                      child: VideoThumbnailItem(
                        video: _filteredVideos[index],
                        onPlay: () => _playVideo(_filteredVideos[index]),
                        onFavoriteChanged: () => _applyFiltersAndSort(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFolderView() {
    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No folders found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        final count = _folderVideos[folder]?.length ?? 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              folder,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$count video${count != 1 ? 's' : ''}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedFolder = folder;
                _selectedIndex = 0;
              });
              _applyFiltersAndSort();
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoritesView() {
    return FutureBuilder<List<VideoModel>>(
      future: _getFavoriteVideos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite videos yet ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on videos to add them to favorites',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveGrid.getCrossAxisCount(context),
            childAspectRatio: ResponsiveGrid.getChildAspectRatio(context),
            crossAxisSpacing: ResponsiveGrid.getSpacing(context),
            mainAxisSpacing: ResponsiveGrid.getSpacing(context),
          ),
          padding: ResponsiveGrid.getPadding(context),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPress: () => _showVideoDetails(favorites[index]),
              child: VideoThumbnailItem(
                video: favorites[index],
                onPlay: () => _playVideo(favorites[index]),
                onFavoriteChanged: () => setState(() {}),
              ),
            );
          },
        );
      },
    );
  }

  void _playVideo(VideoModel video) async {
    // Add to recent files
    await RecentFilesService.instance.addRecentVideo(video.path);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(file: video.file, pip: _pip),
      ),
    );
  }

  void _showVideoDetails(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoDetailsScreen(video: video)),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File file;
  final SimplePip pip;

  const VideoPlayerScreen({super.key, required this.file, required this.pip});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController videoController;
  ChewieController? chewieController;
  late Future<void> initializePlayerFuture;
  bool wasPlayingBeforePIP = false;
  
  // Volume and brightness controls
  double _currentVolume = 1.0;
  double _currentBrightness = 1.0;
  double _savedBrightness = 1.0;
  int _maxVolume = 15;
  bool _showControls = true;
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  
  // Gesture detection
  double _initialBrightness = 1.0;
  int _initialVolume = 15;
  Offset? _initialPanPosition;
  bool _isAdjustingBrightness = false;
  bool _isAdjustingVolume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    videoController = VideoPlayerController.file(widget.file);
    initializePlayerFuture = _initializePlayer();
    _initializeVolumeAndBrightness();
  }
  
  Future<void> _initializeVolumeAndBrightness() async {
    try {
      // Get current volume
      _maxVolume = await Volume.getMaxVol ?? 15;
      final currentVol = await Volume.getVol ?? _maxVolume;
      _currentVolume = currentVol / _maxVolume;
      _initialVolume = currentVol;
      
      // Get current brightness
      final brightness = ScreenBrightness();
      _currentBrightness = await brightness.current ?? 1.0;
      _savedBrightness = _currentBrightness;
      
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing volume/brightness: $e');
    }
  }
  
  void _showControlsTemporarily() {
    setState(() {
      _isControlsVisible = true;
    });
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showControls) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }
  
  Future<void> _setBrightness(double brightness) async {
    try {
      final screenBrightness = ScreenBrightness();
      await screenBrightness.setScreenBrightness(brightness.clamp(0.0, 1.0));
      if (mounted) {
        setState(() {
          _currentBrightness = brightness.clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
  }
  
  Future<void> _setVolume(double volume) async {
    try {
      final vol = (volume * _maxVolume).round().clamp(0, _maxVolume);
      await Volume.setVol(vol);
      if (mounted) {
        setState(() {
          _currentVolume = volume.clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }
  
  void _showVolumeBrightnessDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brightness control
            Row(
              children: [
                const Icon(Icons.brightness_6),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brightness',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: _currentBrightness,
                        onChanged: _setBrightness,
                        min: 0.0,
                        max: 1.0,
                      ),
                      Text(
                        '${(_currentBrightness * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Volume control
            Row(
              children: [
                Icon(_currentVolume > 0.5
                    ? Icons.volume_up
                    : _currentVolume > 0
                        ? Icons.volume_down
                        : Icons.volume_off),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Slider(
                        value: _currentVolume,
                        onChanged: _setVolume,
                        min: 0.0,
                        max: 1.0,
                      ),
                      Text(
                        '${(_currentVolume * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Reset brightness button
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Reset Brightness'),
              onPressed: () {
                _setBrightness(_savedBrightness);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializePlayer() async {
    await videoController.initialize();
    chewieController = ChewieController(
      videoPlayerController: videoController,
      autoPlay: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
      placeholder: const Center(child: CircularProgressIndicator()),
    );
  }

  void _enterPIP() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await widget.pip.enterPipMode();
      }
    } catch (e) {
      debugPrint('PiP mode failed: $e');
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    chewieController?.dispose();
    videoController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isControlsVisible
          ? AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                widget.file.path.split('/').last,
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.brightness_6, color: Colors.white),
                  onPressed: _showVolumeBrightnessDialog,
                  tooltip: 'Brightness & Volume',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
                  onPressed: _enterPIP,
                  tooltip: 'Picture in Picture',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
            _isControlsVisible = _showControls;
          });
          if (_showControls) {
            _showControlsTemporarily();
          }
        },
        onVerticalDragStart: (details) async {
          _initialPanPosition = details.globalPosition;
          _initialBrightness = _currentBrightness;
          _initialVolume = await Volume.getVol ?? _maxVolume;
        },
        onVerticalDragUpdate: (details) async {
          if (_initialPanPosition == null) return;
          
          final screenHeight = MediaQuery.of(context).size.height;
          final delta = (_initialPanPosition!.dy - details.globalPosition.dy) / screenHeight;
          
          // Left side = brightness, Right side = volume
          final screenWidth = MediaQuery.of(context).size.width;
          final isLeftSide = details.globalPosition.dx < screenWidth / 2;
          
          if (isLeftSide) {
            // Adjust brightness
            _isAdjustingBrightness = true;
            _setBrightness((_initialBrightness + delta).clamp(0.0, 1.0));
          } else {
            // Adjust volume
            _isAdjustingVolume = true;
            final newVol = (_initialVolume + (delta * _maxVolume)).round().clamp(0, _maxVolume);
            await Volume.setVol(newVol);
            if (mounted) {
              setState(() {
                _currentVolume = newVol / _maxVolume;
              });
            }
          }
          
          _showControlsTemporarily();
        },
        onVerticalDragEnd: (details) {
          _initialPanPosition = null;
          _isAdjustingBrightness = false;
          _isAdjustingVolume = false;
        },
        child: Stack(
          children: [
            FutureBuilder(
              future: initializePlayerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    chewieController != null) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: Chewie(controller: chewieController!),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            // Gesture indicators
            if (_isAdjustingBrightness || _isAdjustingVolume)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAdjustingBrightness
                              ? Icons.brightness_6
                              : Icons.volume_up,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isAdjustingBrightness
                              ? '${(_currentBrightness * 100).toInt()}%'
                              : '${(_currentVolume * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
