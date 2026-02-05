import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/video_player_controller.dart';
import '../services/subtitle_service.dart';

class SubtitleSelectionWidget extends ConsumerStatefulWidget {
  final String videoPath;
  final VoidCallback? onSubtitleSelected;

  const SubtitleSelectionWidget({
    super.key,
    required this.videoPath,
    this.onSubtitleSelected,
  });

  @override
  ConsumerState<SubtitleSelectionWidget> createState() =>
      _SubtitleSelectionWidgetState();
}

class _SubtitleSelectionWidgetState
    extends ConsumerState<SubtitleSelectionWidget> {
  List<SubtitleTrack> _availableSubtitles = [];
  bool _isLoading = false;
  String? _selectedPath;

  @override
  void initState() {
    super.initState();
    _loadAvailableSubtitles();
  }

  Future<void> _loadAvailableSubtitles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subtitles = await SubtitleService.findSubtitleTracks(
        widget.videoPath,
      );
      setState(() {
        _availableSubtitles = subtitles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSubtitle(SubtitleTrack subtitle) {
    setState(() {
      _selectedPath = subtitle.path;
    });

    // Update video controller with subtitle
    final videoController = ref.read(videoPlayerControllerProvider.notifier);
    videoController.setSubtitle(subtitle.path);

    widget.onSubtitleSelected?.call();
    Navigator.of(context).pop();
  }

  void _disableSubtitle() {
    setState(() {
      _selectedPath = null;
    });

    // Clear subtitle in video controller
    final videoController = ref.read(videoPlayerControllerProvider.notifier);
    videoController.setSubtitle(null);

    widget.onSubtitleSelected?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: Row(
              children: [
                const Icon(Icons.subtitles, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Subtitle Selection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            )
          else if (_availableSubtitles.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.subtitles_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No subtitles found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place .srt or .vtt files in the same folder as the video',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount:
                    _availableSubtitles.length + 1, // +1 for disable option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Disable subtitle option
                    return ListTile(
                      leading: const Icon(
                        Icons.subtitles_off,
                        color: Colors.grey,
                      ),
                      title: const Text(
                        'Disable Subtitles',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: _disableSubtitle,
                    );
                  }

                  final subtitle = _availableSubtitles[index - 1];
                  final isSelected = _selectedPath == subtitle.path;

                  return ListTile(
                    leading: Icon(
                      Icons.subtitles,
                      color: isSelected ? Colors.red : Colors.grey,
                    ),
                    title: Text(
                      subtitle.label,
                      style: TextStyle(
                        color: isSelected ? Colors.red : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      subtitle.language.isNotEmpty
                          ? subtitle.language
                          : 'Unknown',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.red.withValues(alpha: 0.7)
                            : Colors.grey,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.red)
                        : null,
                    onTap: () => _selectSubtitle(subtitle),
                  );
                },
              ),
            ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
