import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoCutterScreen extends StatefulWidget {
  final String videoPath;

  const VideoCutterScreen({super.key, required this.videoPath});

  @override
  State<VideoCutterScreen> createState() => _VideoCutterScreenState();
}

class _VideoCutterScreenState extends State<VideoCutterScreen> {
  late final Player _player;
  late final VideoController _controller;

  double _startValue = 0.0;
  double _endValue = 1.0;
  Duration _duration = Duration.zero;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.open(Media(widget.videoPath));
    _player.stream.duration.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d;
          _endValue = d.inMilliseconds.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _cutVideo() async {
    setState(() => _isProcessing = true);

    try {
      final directory = await getTemporaryDirectory();
      final fileName = p.basenameWithoutExtension(widget.videoPath);
      final extension = p.extension(widget.videoPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFilePath = p.join(
        directory.path,
        '${fileName}_cut_$timestamp$extension',
      );

      final startPos = _formatDuration(
        Duration(milliseconds: _startValue.toInt()),
      );
      final durationToCut = _formatDuration(
        Duration(milliseconds: (_endValue - _startValue).toInt()),
      );

      // FFmpeg command: -ss (start), -t (duration), -i (input), -c copy (fast)
      final command =
          '-ss $startPos -t $durationToCut -i "${widget.videoPath}" -c copy "$outputFilePath"';

      await FFmpegKit.execute(command).then((session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          setState(() {
            _isProcessing = false;
          });
          if (mounted) {
            _showSuccessDialog(outputFilePath);
          }
        } else {
          setState(() => _isProcessing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to cut video')),
            );
          }
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = d.inMilliseconds
        .remainder(1000)
        .toString()
        .padLeft(3, '0');
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Success', style: TextStyle(color: Colors.white)),
        content: Text(
          'Video saved to:\n$path',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Logic to open/play the new file could be here
            },
            child: const Text('Play Cut Video'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Cutter'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: Center(child: Video(controller: _controller)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                Duration(milliseconds: _startValue.toInt()),
                              ),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDuration(
                                Duration(milliseconds: _endValue.toInt()),
                              ),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(_startValue, _endValue),
                          min: 0.0,
                          max: _duration.inMilliseconds.toDouble() > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0,
                          activeColor: Colors.red,
                          inactiveColor: Colors.white12,
                          onChanged: (values) {
                            setState(() {
                              _startValue = values.start;
                              _endValue = values.end;
                            });
                          },
                          onChangeStart: (values) => _player.pause(),
                          onChangeEnd: (values) {
                            _player.seek(
                              Duration(milliseconds: values.start.toInt()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _cutVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'CUT VIDEO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Select range and click "CUT VIDEO" to trim.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
