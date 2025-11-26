import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:volume/volume.dart';
import '../utils/recent_files_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<File> _audioFiles = [];
  File? _currentFile;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffling = false;
  bool _isRepeating = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _sleepTimer;
  Duration? _sleepTimerDuration;
  double _audioVolume = 1.0;
  int _maxVolume = 15;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });

    _initializeVolume();
    _scanForAudioFiles();
  }
  
  Future<void> _initializeVolume() async {
    try {
      _maxVolume = await Volume.getMaxVol ?? 15;
      final currentVol = await Volume.getVol ?? _maxVolume;
      _audioVolume = currentVol / _maxVolume;
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing volume: $e');
    }
  }
  
  Future<void> _setAudioVolume(double volume) async {
    try {
      final vol = (volume * _maxVolume).round().clamp(0, _maxVolume);
      await Volume.setVol(vol);
      if (mounted) {
        setState(() {
          _audioVolume = volume.clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }
  
  void _showVolumeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_audioVolume > 0.5
                    ? Icons.volume_up
                    : _audioVolume > 0
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
                        value: _audioVolume,
                        onChanged: _setAudioVolume,
                        min: 0.0,
                        max: 1.0,
                      ),
                      Text(
                        '${(_audioVolume * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _scanForAudioFiles() async {
    setState(() => _isLoading = true);
    try {
      final List<File> files = [];
      
      // Audio file extensions
      const audioExtensions = [
        'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'opus',
        'amr', '3gp', 'aiff', 'au', 'ra', 'mp2', 'ac3', 'dts'
      ];

      // Get common audio directories
      if (Platform.isAndroid) {
        final commonPaths = [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
          '/storage/emulated/0/Telegram/Telegram Audio',
          '/storage/emulated/0/Audio',
          '/storage/emulated/0/Sounds',
        ];

        for (final path in commonPaths) {
          try {
            final dir = Directory(path);
            if (await dir.exists()) {
              await for (final entity in dir.list(recursive: true)) {
                if (entity is File) {
                  final pathLower = entity.path.toLowerCase();
                  final extension = pathLower.split('.').last;
                  
                  // Check both MIME type and file extension
                  bool isAudio = false;
                  final mimeType = lookupMimeType(entity.path);
                  if (mimeType != null && mimeType.startsWith('audio/')) {
                    isAudio = true;
                  } else if (audioExtensions.contains(extension)) {
                    isAudio = true;
                  }
                  
                  if (isAudio) {
                    files.add(entity);
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('Error scanning $path: $e');
          }
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        try {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              final pathLower = entity.path.toLowerCase();
              final extension = pathLower.split('.').last;
              
              bool isAudio = false;
              final mimeType = lookupMimeType(entity.path);
              if (mimeType != null && mimeType.startsWith('audio/')) {
                isAudio = true;
              } else if (audioExtensions.contains(extension)) {
                isAudio = true;
              }
              
              if (isAudio) {
                files.add(entity);
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning iOS directory: $e');
        }
      }

      if (mounted) {
        setState(() {
          _audioFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error scanning audio files: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        allowMultiple: true,
      );

      if (result != null) {
        final newFiles = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .where((file) => file.existsSync())
            .toList();

        setState(() {
          _audioFiles.addAll(newFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking audio files: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
      }
    }
  }

  Future<void> _playAudio(File file, int index) async {
    try {
      if (_currentFile?.path == file.path && _isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      _currentFile = file;
      _currentIndex = index;
      await _audioPlayer.play(DeviceFileSource(file.path));
      
      // Add to recent files
      await RecentFilesService.instance.addRecentAudio(file.path);
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }
  
  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sleep Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sleepTimerDuration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Timer: ${_formatDuration(_sleepTimerDuration!)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ...([15, 30, 45, 60, 90, 120].map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              onTap: () {
                _setSleepTimer(Duration(minutes: minutes));
                Navigator.pop(context);
              },
            ))),
            ListTile(
              title: const Text('Cancel Timer'),
              leading: const Icon(Icons.cancel),
              onTap: () {
                _cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    
    _sleepTimer = Timer(duration, () {
      if (mounted) {
        _audioPlayer.stop();
        _cancelSleepTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sleep timer: Playback stopped')),
        );
      }
    });
    
    setState(() {});
  }
  
  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    setState(() {});
  }

  Future<void> _playNext() async {
    if (_audioFiles.isEmpty || _currentIndex == -1) return;

    int nextIndex;
    if (_isShuffling) {
      nextIndex = (DateTime.now().millisecondsSinceEpoch % _audioFiles.length);
    } else {
      nextIndex = (_currentIndex + 1) % _audioFiles.length;
    }

    if (nextIndex == _currentIndex && !_isRepeating) return;

    await _playAudio(_audioFiles[nextIndex], nextIndex);
  }

  Future<void> _playPrevious() async {
    if (_audioFiles.isEmpty || _currentIndex == -1) return;

    int prevIndex;
    if (_isShuffling) {
      prevIndex = (DateTime.now().millisecondsSinceEpoch % _audioFiles.length);
    } else {
      prevIndex = (_currentIndex - 1) % _audioFiles.length;
      if (prevIndex < 0) prevIndex = _audioFiles.length - 1;
    }

    await _playAudio(_audioFiles[prevIndex], prevIndex);
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _currentFile = null;
      _currentIndex = -1;
      _position = Duration.zero;
    });
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  String _getFileName(File file) {
    final name = file.path.split('/').last;
    return name.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
        actions: [
          if (_sleepTimerDuration != null)
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: _showSleepTimerDialog,
              tooltip: 'Sleep Timer: ${_formatDuration(_sleepTimerDuration!)}',
            ),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            onPressed: _showSleepTimerDialog,
            tooltip: 'Sleep Timer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanForAudioFiles,
            tooltip: 'Scan for audio files',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _audioFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No audio files found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the + button to add audio files',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Now Playing Section - Modern Player UI
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: _currentFile == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.music_note,
                                        size: 80,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Select a song to play',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Album Art - Responsive size
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final size = constraints.maxWidth < 400
                                              ? 200.0
                                              : 280.0;
                                          final iconSize = constraints.maxWidth < 400
                                              ? 80.0
                                              : 120.0;
                                          return Container(
                                            width: size,
                                            height: size,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  blurRadius: 30,
                                                  spreadRadius: 10,
                                                ),
                                              ],
                                            ),
                                            child: _isPlaying
                                                ? Icon(
                                                    Icons.music_note,
                                                    size: iconSize,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  )
                                                : Icon(
                                                    Icons.audiotrack,
                                                    size: iconSize,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      // Song Title
                                      Text(
                                        _getFileName(_currentFile!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Artist/Album info (using file path for now)
                                      Text(
                                        'Music Library',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 24),
                                    // Progress Bar
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Column(
                                        children: [
                                          SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              inactiveTrackColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              thumbColor: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              thumbShape: const RoundSliderThumbShape(
                                                enabledThumbRadius: 8,
                                              ),
                                              trackHeight: 4,
                                            ),
                                            child: Slider(
                                              value: _duration.inSeconds > 0
                                                  ? _position.inSeconds.toDouble()
                                                  : 0,
                                              min: 0,
                                              max: _duration.inSeconds > 0
                                                  ? _duration.inSeconds.toDouble()
                                                  : 100,
                                              onChanged: (value) {
                                                _seekTo(
                                                  Duration(
                                                    seconds: value.toInt(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          // Time indicators
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  _formatDuration(_position),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  _formatDuration(_duration),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Player Controls
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Shuffle button
                                        IconButton(
                                          icon: Icon(
                                            _isShuffling
                                                ? Icons.shuffle
                                                : Icons.shuffle_outlined,
                                            ),
                                          color: _isShuffling
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null,
                                          onPressed: () {
                                            setState(() {
                                              _isShuffling = !_isShuffling;
                                            });
                                          },
                                          iconSize: 28,
                                        ),
                                        const SizedBox(width: 8),
                                        // Previous button
                                        IconButton(
                                          icon: const Icon(Icons.skip_previous),
                                          onPressed: _audioFiles.length > 1
                                              ? _playPrevious
                                              : null,
                                          iconSize: 36,
                                        ),
                                        const SizedBox(width: 16),
                                        // Volume button
                                        IconButton(
                                          icon: Icon(
                                            _audioVolume > 0.5
                                                ? Icons.volume_up
                                                : _audioVolume > 0
                                                    ? Icons.volume_down
                                                    : Icons.volume_off,
                                          ),
                                          onPressed: _showVolumeDialog,
                                          iconSize: 28,
                                        ),
                                        const SizedBox(width: 8),
                                        // Play/Pause button
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              _isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                            ),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            onPressed: _isPlaying
                                                ? _pauseAudio
                                                : () => _playAudio(
                                                      _currentFile!,
                                                      _currentIndex,
                                                    ),
                                            iconSize: 48,
                                            padding: const EdgeInsets.all(16),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Next button
                                        IconButton(
                                          icon: const Icon(Icons.skip_next),
                                          onPressed: _audioFiles.length > 1
                                              ? _playNext
                                              : null,
                                          iconSize: 36,
                                        ),
                                        const SizedBox(width: 8),
                                        // Repeat button
                                        IconButton(
                                          icon: Icon(
                                            _isRepeating
                                                ? Icons.repeat
                                                : Icons.repeat_outlined,
                                          ),
                                          color: _isRepeating
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null,
                                          onPressed: () {
                                            setState(() {
                                              _isRepeating = !_isRepeating;
                                            });
                                          },
                                          iconSize: 28,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                    // Playlist Section
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Playlist (${_audioFiles.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (_currentFile != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Stop'),
                                      onPressed: _stopAudio,
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: _audioFiles.length,
                                itemBuilder: (context, index) {
                                  final file = _audioFiles[index];
                                  final isCurrent = _currentIndex == index;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: isCurrent
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : null,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isCurrent
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        child: Icon(
                                          isCurrent && _isPlaying
                                              ? Icons.equalizer
                                              : Icons.music_note,
                                          color: isCurrent
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                      title: Text(
                                        _getFileName(file),
                                        style: TextStyle(
                                          fontWeight: isCurrent
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        file.path.split('/').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: isCurrent && _isPlaying
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : null,
                                      onTap: () => _playAudio(file, index),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAudioFiles,
        tooltip: 'Add audio files',
        child: const Icon(Icons.add),
      ),
    );
  }
}
