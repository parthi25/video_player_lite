import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../widgets/next_video_player.dart';
import '../widgets/auto_video_scanner.dart';
import '../widgets/video_file_item.dart';
import '../services/performance_service.dart';
import '../services/playlist_service.dart';
import '../services/file_browser_service.dart';
import '../services/vault_service.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

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
  bool _isScanning = false;
  List<VideoFile> _localVideos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await PerformanceService.initialize();
    await PlaylistService.initialize();
    _scanAllVideos(); // Auto-scan for videos on startup
    setState(() {});
  }

  Future<void> _scanAllVideos() async {
    setState(() {
      _isScanning = true;
      _localVideos.clear(); // Clear previous results
    });

    try {
      debugPrint('Starting video scan...');
      final videos = await VideoScanner.scanAllVideos();
      debugPrint('Scan completed. Found ${videos.length} videos.');

      setState(() {
        _localVideos = videos;
        _isScanning = false;
      });

      // Show success message
      if (videos.isNotEmpty) {
        _showSuccessSnackBar('Found ${videos.length} videos');
      } else {
        _showErrorSnackBar('No videos found. Check storage permissions.');
      }
    } catch (e) {
      debugPrint('Error during video scan: $e');
      setState(() {
        _isScanning = false;
      });
      _showErrorSnackBar('Failed to scan videos: ${e.toString()}');
    }
  }

  void _playVideo(String videoPath) {
    setState(() {
      _videoPath = videoPath;
      _videoUrl = null;
    });
    _tabController.animateTo(0); // Switch to player tab
  }

  Future<void> _useFilePicker() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'avi',
          'mov',
          'mkv',
          'wmv',
          'flv',
          'webm',
          'm4v',
          '3gp',
          'mpg',
          'mpeg',
          'ts',
          'mts',
          'vob',
          'f4v',
          'asf',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final videoPath = result.files.single.path!;
        _playVideo(videoPath);
        _showSuccessSnackBar('Video loaded successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick video file: $e');
    }
  }

  Future<void> _useFileBrowser() async {
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AutoVideoScannerWidget(),
      );

      if (result != null) {
        _playVideo(result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to browse files: $e');
    }
  }

  void _loadNetworkVideo() {
    if (_urlController.text.trim().isNotEmpty) {
      setState(() {
        _videoUrl = _urlController.text.trim();
        _videoPath = null;
      });
      _urlController.clear();
    } else {
      _showErrorSnackBar('Please enter a valid video URL');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onVideoEnded() {
    setState(() {
      _videoUrl = null;
      _videoPath = null;
    });
    _showSuccessSnackBar('Video completed');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_videoUrl != null || _videoPath != null) {
      // Show video player
      return Scaffold(
        backgroundColor: Colors.black,
        body: NextVideoPlayer(
          videoUrl: _videoUrl,
          videoPath: _videoPath,
          autoPlay: false,
          looping: false,
          onVideoEnded: _onVideoEnded,
        ),
      );
    }

    // Show MX Player main interface
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 50,
        title: const Text(
          'NEXT-GEN VIDEO PLAYER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            padding: const EdgeInsets.all(8),
            onSelected: (value) async {
              switch (value) {
                case 'vault':
                  final navigator = Navigator.of(context);
                  final isSetup = await VaultService.isVaultSetup();
                  if (mounted) {
                    if (isSetup) {
                      navigator.pushNamed('/vault-auth');
                    } else {
                      navigator.pushNamed('/vault-setup');
                    }
                  }
                  break;
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
                case 'about':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'vault',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Secure Vault'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Player'),
            Tab(text: 'Folders'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPlayerTab(), _buildFoldersTab(), _buildVideosTab()],
      ),
    );
  }

  Widget _buildPlayerTab() {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to NEXT-GEN VIDEO PLAYER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a video source to get started',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Video source options
            const Text(
              'Video Sources',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.file_upload,
                    label: 'Local File',
                    description: 'Browse device storage',
                    onTap: _useFilePicker,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.folder,
                    label: 'File Browser',
                    description: 'Browse all videos',
                    onTap: _useFileBrowser,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.link,
                    label: 'Network URL',
                    description: 'Stream from URL',
                    onTap: _showUrlDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.refresh,
                    label: 'Scan Storage',
                    description: 'Find all videos',
                    onTap: _scanAllVideos,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick stats
            if (_localVideos.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.video_library,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_localVideos.length} videos found',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _tabController.animateTo(2),
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Colors.red),
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

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersTab() {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Folders',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildFolderCard(
              Icons.download,
              'Downloads',
              'Downloaded files',
              '/storage/emulated/0/Download',
            ),

            _buildFolderCard(
              Icons.movie,
              'Movies',
              'Movie files',
              '/storage/emulated/0/Movies',
            ),

            _buildFolderCard(
              Icons.photo_camera,
              'DCIM',
              'Camera videos',
              '/storage/emulated/0/DCIM',
            ),

            _buildFolderCard(
              Icons.image,
              'Pictures',
              'Picture folders',
              '/storage/emulated/0/Pictures',
            ),

            _buildFolderCard(
              Icons.storage,
              'WhatsApp',
              'WhatsApp media',
              '/storage/emulated/0/WhatsApp/Media',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(
    IconData icon,
    String title,
    String description,
    String path,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(description, style: TextStyle(color: Colors.grey[400])),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () => _scanStorage(path, title),
      ),
    );
  }

  Future<void> _scanStorage(String path, String title) async {
    setState(() {
      _isScanning = true;
    });

    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        final videos = await FileBrowserService.getVideoFilesInDirectory(path);
        setState(() {
          _localVideos.addAll(videos);
          _isScanning = false;
        });
        _tabController.animateTo(2); // Switch to videos tab
        _showSuccessSnackBar('Found ${videos.length} videos in $title');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorSnackBar('Failed to scan $path: $e');
    }
  }

  Widget _buildVideosTab() {
    return Container(
      color: Colors.black,
      child: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Scanning for videos...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _localVideos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No videos found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try scanning storage folders',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _scanAllVideos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Scan Videos'),
                      ),
                      ElevatedButton(
                        onPressed: _useFilePicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pick File'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _localVideos.length,
              itemBuilder: (context, index) {
                final video = _localVideos[index];
                return VideoFileItem(
                  videoFile: video,
                  onTap: () => _playVideo(video.path),
                );
              },
            ),
    );
  }

  void _showUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Network Video URL',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'Enter video URL',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNetworkVideo();
            },
            child: const Text('Load', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
