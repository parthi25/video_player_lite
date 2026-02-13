import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_browser_service.dart';

class FileBrowserService {
  static const videoExtensions = {
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
  };

  static Future<List<VideoFile>> getVideoFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return [];

      final files = <VideoFile>[];
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final extension = entity.path.toLowerCase().split('.').last;
          if (videoExtensions.contains('.$extension')) {
            final stat = await entity.stat();
            files.add(
              VideoFile(
                path: entity.path,
                name: entity.path.split('/').last,
                size: stat.size,
                lastModified: stat.modified,
              ),
            );
          }
        }
      }

      // Sort by name
      files.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return files;
    } catch (e) {
      debugPrint('Error getting video files: $e');
      return [];
    }
  }

  static Future<List<String>> getVideoDirectories() async {
    try {
      final directories = <String>[];

      // Common video directories on Android
      final commonPaths = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
      ];

      for (final path in commonPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          directories.add(path);
        }
      }

      return directories;
    } catch (e) {
      debugPrint('Error getting video directories: $e');
      return [];
    }
  }
}

class FileBrowserWidget extends ConsumerStatefulWidget {
  const FileBrowserWidget({super.key});

  @override
  ConsumerState<FileBrowserWidget> createState() => _FileBrowserWidgetState();
}

class _FileBrowserWidgetState extends ConsumerState<FileBrowserWidget> {
  String? currentDirectory;
  List<String> directories = [];
  List<VideoFile> videoFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() => isLoading = true);
    try {
      final dirs = await FileBrowserService.getVideoDirectories();
      if (!mounted) return;
      setState(() {
        directories = dirs;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading directories: $e')),
        );
      }
    }
  }

  Future<void> _loadVideoFiles(String directoryPath) async {
    setState(() => isLoading = true);
    try {
      final files = await FileBrowserService.getVideoFiles(directoryPath);
      if (!mounted) return;
      setState(() {
        currentDirectory = directoryPath;
        videoFiles = files;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
      }
    }
  }

  void _selectVideo(VideoFile videoFile) {
    Navigator.of(context).pop(videoFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Browse Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  )
                : currentDirectory == null
                ? _buildDirectoryList()
                : _buildVideoFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryList() {
    if (directories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No video directories found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: directories.length,
      itemBuilder: (context, index) {
        final directory = directories[index];
        final dirName = directory.split('/').last;

        return ListTile(
          leading: const Icon(Icons.folder, color: Colors.red),
          title: Text(dirName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            directory,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          onTap: () => _loadVideoFiles(directory),
        );
      },
    );
  }

  Widget _buildVideoFileList() {
    return Column(
      children: [
        // Breadcrumb
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    currentDirectory = null;
                    videoFiles = [];
                  });
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  currentDirectory!.split('/').last,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: videoFiles.isEmpty
              ? const Center(
                  child: Text(
                    'No video files found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: videoFiles.length,
                  itemBuilder: (context, index) {
                    final file = videoFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.video_file, color: Colors.red),
                      title: Text(
                        file.name,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        file.formattedSize,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _selectVideo(file),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
