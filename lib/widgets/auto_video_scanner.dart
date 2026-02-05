import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_browser_service.dart';
import '../services/video_scanner_service.dart';
import 'video_file_item.dart';

class AutoVideoScannerWidget extends ConsumerStatefulWidget {
  const AutoVideoScannerWidget({super.key});

  @override
  ConsumerState<AutoVideoScannerWidget> createState() =>
      _AutoVideoScannerWidgetState();
}

class _AutoVideoScannerWidgetState
    extends ConsumerState<AutoVideoScannerWidget> {
  List<VideoFile> videos = [];
  bool isScanning = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // 1. Load cache first
    final cached = await VideoScannerService.getCachedVideos();
    if (mounted && cached.isNotEmpty) {
      setState(() {
        videos = cached;
      });
    }

    // 2. Start fresh scan
    _scanVideos();
  }

  Future<void> _scanVideos() async {
    // If we already have cached videos, we don't need to show a fullscreen loader,
    // just a small indicator (which is already in the header).
    final bool showFullLoader = videos.isEmpty;

    if (showFullLoader) {
      setState(() {
        isScanning = true;
        error = null;
      });
    } else {
      setState(() {
        isScanning = true;
      });
    }

    try {
      final scannedVideos = await VideoScannerService.scanAllVideos(
        useCache: false,
      );
      if (mounted) {
        setState(() {
          videos = scannedVideos;
          isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (showFullLoader) error = e.toString();
          isScanning = false;
        });
      }
    }
  }

  void _selectVideo(VideoFile video) {
    Navigator.of(context).pop(video.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'All Videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                IconButton(
                  onPressed: isScanning ? null : _scanVideos,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Scanning for videos...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error scanning videos',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanVideos,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Try scanning again or check your storage',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Video count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${videos.length} videos found',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Tap to play',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        // Video list
        Expanded(
          child: ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoFileItem(
                videoFile: video,
                onTap: () => _selectVideo(video),
              );
            },
          ),
        ),
      ],
    );
  }
}
