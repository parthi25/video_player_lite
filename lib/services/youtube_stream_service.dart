import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeStreamException implements Exception {
  final String message;

  const YoutubeStreamException(this.message);

  @override
  String toString() => message;
}

class YoutubeStreamService {
  static final RegExp _youtubePattern = RegExp(
    r'(https?://)?(www\.)?(m\.)?(youtube\.com|youtu\.be)/',
    caseSensitive: false,
  );

  static bool isYoutubeUrl(String url) => _youtubePattern.hasMatch(url);

  static Future<String> resolvePlayableUrl(String url) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(url);

      if (video.isLive) {
        final liveUrl = await yt.videos.streamsClient.getHttpLiveStreamUrl(
          video.id,
        );
        if (liveUrl.isEmpty) {
          throw const YoutubeStreamException('Live stream is unavailable');
        }
        return liveUrl;
      }

      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final muxed = manifest.muxed;
      if (muxed.isNotEmpty) {
        return muxed.bestQuality.url.toString();
      }

      throw const YoutubeStreamException(
        'No compatible YouTube stream found',
      );
    } catch (e) {
      if (e is YoutubeStreamException) rethrow;
      throw const YoutubeStreamException(
        'This YouTube video cannot be streamed in-app. It may be restricted or blocked for third-party playback.',
      );
    } finally {
      yt.close();
    }
  }

  static Future<String> resolveIfNeeded(String url) async {
    if (!isYoutubeUrl(url)) return url;
    return resolvePlayableUrl(url);
  }
}
