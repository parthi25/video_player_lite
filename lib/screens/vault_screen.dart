import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/vault_service.dart';
import '../widgets/next_video_player.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with TickerProviderStateMixin {
  List<VaultVideo> _vaultVideos = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedVideos = {};

  late AnimationController _fabController;
  late AnimationController _listController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _listAnimation;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));

    _listAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic),
        );

    _loadVaultVideos();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadVaultVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await VaultService.getVaultVideos();
      setState(() {
        _vaultVideos = videos;
        _isLoading = false;
      });

      _listController.forward();
      _fabController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vault: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _toggleSelection(String videoId) {
    setState(() {
      if (_selectedVideos.contains(videoId)) {
        _selectedVideos.remove(videoId);
        if (_selectedVideos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedVideos.add(videoId);
        _isSelectionMode = true;
      }
    });

    HapticFeedback.lightImpact();
  }

  void _clearSelection() {
    setState(() {
      _selectedVideos.clear();
      _isSelectionMode = false;
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _removeSelectedVideos() async {
    if (_selectedVideos.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Remove Videos',
      'Are you sure you want to remove ${_selectedVideos.length} video(s) from this folder?',
    );

    if (!confirmed) return;

    int successCount = 0;

    for (final videoId in _selectedVideos) {
      final success = await VaultService.unhideVideo(videoId);
      if (success) successCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount video(s) removed successfully'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }

    _clearSelection();
    _loadVaultVideos();
  }

  Future<void> _deleteSelectedVideos() async {
    if (_selectedVideos.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete Videos',
      'Are you sure you want to permanently delete ${_selectedVideos.length} video(s)? This action cannot be undone.',
    );

    if (!confirmed) return;

    int successCount = 0;

    for (final videoId in _selectedVideos) {
      final success = await VaultService.deleteFromVault(videoId);
      if (success) successCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount video(s) deleted permanently'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }

    _clearSelection();
    _loadVaultVideos();
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: Colors.grey.shade900,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_vaultVideos.length} videos',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  final navigator = Navigator.of(context);
                  await VaultService.logout();
                  if (mounted) {
                    navigator.pushReplacementNamed('/vault-auth');
                  }
                  break;
                case 'clear_vault':
                  final confirmed = await _showConfirmDialog(
                    'Clear Vault',
                    'Are you sure you want to clear all hidden videos? This action cannot be undone.',
                  );
                  if (confirmed) {
                    await VaultService.clearVault();
                    _loadVaultVideos();
                  }
                  break;
                case 'verify_integrity':
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final isIntact = await VaultService.verifyVaultIntegrity();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isIntact
                              ? 'Vault integrity verified ✓'
                              : 'Vault integrity compromised ⚠️',
                        ),
                        backgroundColor: isIntact
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_vault',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Vault'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'verify_integrity',
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Verify Integrity'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    if (_vaultVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey.shade600),
            const SizedBox(height: 20),
            Text(
              'No videos yet',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add videos to see them here',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SlideTransition(
      position: _listAnimation,
      child: RefreshIndicator(
        onRefresh: _loadVaultVideos,
        color: Colors.red.shade700,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _vaultVideos.length,
          itemBuilder: (context, index) {
            final video = _vaultVideos[index];
            final isSelected = _selectedVideos.contains(video.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.red.shade600
                      : Colors.grey.shade700.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
                title: Text(
                  video.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(video.fileSize),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Added: ${_formatDate(video.hiddenDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(video.id),
                        activeColor: Colors.red.shade700,
                        checkColor: Colors.white,
                      )
                    else ...[
                      IconButton(
                        onPressed: () => _playVideo(video),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade400,
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'unhide':
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final success = await VaultService.unhideVideo(
                                video.id,
                              );
                              if (success && mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Video removed: ${video.fileName}',
                                    ),
                                    backgroundColor: Colors.green.shade700,
                                  ),
                                );
                                _loadVaultVideos();
                              }
                              break;
                            case 'delete':
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              final confirmed = await _showConfirmDialog(
                                'Delete Video',
                                'Are you sure you want to permanently delete ${video.fileName}?',
                              );
                              if (confirmed) {
                                final success =
                                    await VaultService.deleteFromVault(
                                      video.id,
                                    );
                                if (success && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Video deleted: ${video.fileName}',
                                      ),
                                      backgroundColor: Colors.orange.shade700,
                                    ),
                                  );
                                  _loadVaultVideos();
                                }
                              }
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'unhide',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Remove'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(video.id);
                  } else {
                    _playVideo(video);
                  }
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _toggleSelection(video.id);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (!_isSelectionMode) {
      return ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.lightImpact();
            await _pickAndHideVideo();
          },
          backgroundColor: Colors.red.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_selectedVideos.isNotEmpty) ...[
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: _removeSelectedVideos,
              backgroundColor: Colors.green.shade700,
              icon: const Icon(Icons.visibility, color: Colors.white),
              label: Text(
                'Remove (${_selectedVideos.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton.extended(
              onPressed: _deleteSelectedVideos,
              backgroundColor: Colors.red.shade700,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text(
                'Delete (${_selectedVideos.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _playVideo(VaultVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NextVideoPlayer(videoPath: video.hiddenPath),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Future<void> _pickAndHideVideo() async {
    // Capture dependencies before async work
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      HapticFeedback.mediumImpact();

      // Pick video file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      // Check mounted after async call
      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePath = result.files.first.path;
      if (filePath == null) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Securely hiding video...'),
            ],
          ),
        ),
      );

      // Hide the video with encryption
      final success = await VaultService.hideVideo(filePath);

      // Check mounted after async call
      if (!mounted) return;

      if (success) {
        HapticFeedback.heavyImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '✓ Video securely hidden and encrypted',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        // Refresh vault videos list
        _loadVaultVideos();
      } else {
        HapticFeedback.lightImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text(
              '✗ Failed to hide video. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Check mounted before showing error
      if (!mounted) return;

      HapticFeedback.lightImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Always close dialog if open
      if (mounted) {
        navigator.pop();
      }
    }
  }
}
