class VideoFormat {
  final String extension;
  final String name;
  final List<String> mimeTypes;
  final List<String> commonCodecs;
  final bool isSupported;
  final String? notes;

  const VideoFormat({
    required this.extension,
    required this.name,
    required this.mimeTypes,
    required this.commonCodecs,
    required this.isSupported,
    this.notes,
  });
}

class VideoFormatService {
  static const List<VideoFormat> supportedFormats = [
    // Most common formats
    VideoFormat(
      extension: 'mp4',
      name: 'MP4 (MPEG-4)',
      mimeTypes: ['video/mp4', 'video/x-m4v'],
      commonCodecs: ['H.264', 'H.265/HEVC', 'AV1', 'VP9'],
      isSupported: true,
      notes: 'Most compatible format',
    ),

    // High quality formats
    VideoFormat(
      extension: 'mkv',
      name: 'MKV (Matroska)',
      mimeTypes: ['video/x-matroska'],
      commonCodecs: ['H.264', 'H.265/HEVC', 'VP9', 'AV1', 'DTS', 'AC3'],
      isSupported: true,
      notes: 'Supports multiple audio/subtitle tracks',
    ),

    // Apple formats
    VideoFormat(
      extension: 'mov',
      name: 'QuickTime MOV',
      mimeTypes: ['video/quicktime', 'video/x-quicktime'],
      commonCodecs: ['H.264', 'H.265/HEVC', 'ProRes'],
      isSupported: true,
      notes: 'Native Apple format',
    ),

    // Android formats
    VideoFormat(
      extension: '3gp',
      name: '3GPP',
      mimeTypes: ['video/3gpp', 'video/3gpp2'],
      commonCodecs: ['H.263', 'H.264', 'MPEG-4'],
      isSupported: true,
      notes: 'Legacy mobile format',
    ),

    // Web formats
    VideoFormat(
      extension: 'webm',
      name: 'WebM',
      mimeTypes: ['video/webm'],
      commonCodecs: ['VP8', 'VP9', 'AV1', 'Opus', 'Vorbis'],
      isSupported: true,
      notes: 'Optimized for web streaming',
    ),

    // Legacy formats
    VideoFormat(
      extension: 'avi',
      name: 'AVI (Audio Video Interleave)',
      mimeTypes: ['video/x-msvideo'],
      commonCodecs: ['DivX', 'XviD', 'H.264', 'MPEG-4'],
      isSupported: true,
      notes: 'Legacy Windows format',
    ),

    VideoFormat(
      extension: 'wmv',
      name: 'Windows Media Video',
      mimeTypes: ['video/x-ms-wmv'],
      commonCodecs: ['WMV', 'WMA'],
      isSupported: true,
      notes: 'Windows Media format',
    ),

    VideoFormat(
      extension: 'flv',
      name: 'Flash Video',
      mimeTypes: ['video/x-flv'],
      commonCodecs: ['H.264', 'Sorenson Spark', 'VP6'],
      isSupported: true,
      notes: 'Adobe Flash format',
    ),

    // Blu-ray and high quality
    VideoFormat(
      extension: 'm2ts',
      name: 'Blu-ray BDAV',
      mimeTypes: ['video/mp2t'],
      commonCodecs: ['H.264', 'H.265/HEVC', 'AVC'],
      isSupported: true,
      notes: 'Blu-ray disc format',
    ),

    VideoFormat(
      extension: 'ts',
      name: 'MPEG Transport Stream',
      mimeTypes: ['video/mp2t'],
      commonCodecs: ['H.264', 'H.265/HEVC', 'MPEG-2'],
      isSupported: true,
      notes: 'Broadcast format',
    ),

    // Additional formats
    VideoFormat(
      extension: 'm4v',
      name: 'iTunes Video',
      mimeTypes: ['video/x-m4v'],
      commonCodecs: ['H.264', 'H.265/HEVC'],
      isSupported: true,
      notes: 'iTunes video format',
    ),

    VideoFormat(
      extension: 'ogv',
      name: 'Ogg Video',
      mimeTypes: ['video/ogg'],
      commonCodecs: ['Theora', 'VP8', 'VP9'],
      isSupported: true,
      notes: 'Open source format',
    ),

    VideoFormat(
      extension: 'mpg',
      name: 'MPEG Video',
      mimeTypes: ['video/mpeg'],
      commonCodecs: ['MPEG-1', 'MPEG-2'],
      isSupported: true,
      notes: 'Standard MPEG format',
    ),

    VideoFormat(
      extension: 'mpeg',
      name: 'MPEG Video',
      mimeTypes: ['video/mpeg'],
      commonCodecs: ['MPEG-1', 'MPEG-2'],
      isSupported: true,
      notes: 'Standard MPEG format',
    ),

    // Less common but supported
    VideoFormat(
      extension: 'vob',
      name: 'DVD Video Object',
      mimeTypes: ['video/dvd'],
      commonCodecs: ['MPEG-2', 'AC3'],
      isSupported: true,
      notes: 'DVD format',
    ),

    VideoFormat(
      extension: 'f4v',
      name: 'Flash MP4 Video',
      mimeTypes: ['video/x-f4v'],
      commonCodecs: ['H.264', 'AAC'],
      isSupported: true,
      notes: 'Flash MP4 format',
    ),

    VideoFormat(
      extension: 'asf',
      name: 'Advanced Systems Format',
      mimeTypes: ['video/x-ms-asf'],
      commonCodecs: ['WMV', 'WMA'],
      isSupported: true,
      notes: 'Microsoft format',
    ),

    // Real media formats
    VideoFormat(
      extension: 'rm',
      name: 'RealMedia',
      mimeTypes: ['application/vnd.rn-realmedia'],
      commonCodecs: ['RealVideo', 'RealAudio'],
      isSupported: false,
      notes: 'Limited support',
    ),

    VideoFormat(
      extension: 'rmvb',
      name: 'RealMedia Variable Bitrate',
      mimeTypes: ['application/vnd.rn-realmedia-vbr'],
      commonCodecs: ['RealVideo', 'RealAudio'],
      isSupported: false,
      notes: 'Limited support',
    ),
  ];

  static VideoFormat? getFormatByExtension(String extension) {
    try {
      final ext = extension.toLowerCase();
      return supportedFormats.firstWhere(
        (format) => format.extension.toLowerCase() == ext,
      );
    } catch (e) {
      return null;
    }
  }

  static VideoFormat? getFormatByPath(String filePath) {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      return getFormatByExtension(extension);
    } catch (e) {
      return null;
    }
  }

  static bool isFormatSupported(String extension) {
    final format = getFormatByExtension(extension);
    return format?.isSupported ?? false;
  }

  static bool isFileSupported(String filePath) {
    final format = getFormatByPath(filePath);
    return format?.isSupported ?? false;
  }

  static List<VideoFormat> getSupportedFormats() {
    return supportedFormats.where((format) => format.isSupported).toList();
  }

  static List<VideoFormat> getUnsupportedFormats() {
    return supportedFormats.where((format) => !format.isSupported).toList();
  }

  static List<String> getSupportedExtensions() {
    return getSupportedFormats()
        .map((format) => format.extension.toLowerCase())
        .toList();
  }

  static String getMimeTypeForFile(String filePath) {
    final format = getFormatByPath(filePath);
    if (format != null && format.mimeTypes.isNotEmpty) {
      return format.mimeTypes.first;
    }
    return 'video/mp4'; // Default fallback
  }

  static String getFormatName(String filePath) {
    final format = getFormatByPath(filePath);
    return format?.name ?? 'Unknown Format';
  }

  static String getFormatNotes(String filePath) {
    final format = getFormatByPath(filePath);
    return format?.notes ?? '';
  }

  static List<String> getCommonCodecs(String filePath) {
    final format = getFormatByPath(filePath);
    return format?.commonCodecs ?? [];
  }

  static bool isHighQualityFormat(String filePath) {
    final format = getFormatByPath(filePath);
    if (format == null) return false;

    // Consider these formats as high quality
    final highQualityFormats = ['mkv', 'm2ts', 'ts', 'mov'];
    return highQualityFormats.contains(format.extension.toLowerCase());
  }

  static bool isStreamingOptimized(String filePath) {
    final format = getFormatByPath(filePath);
    if (format == null) return false;

    // Consider these formats as streaming optimized
    final streamingFormats = ['mp4', 'webm', 'm4v'];
    return streamingFormats.contains(format.extension.toLowerCase());
  }

  static String getQualityIndicator(String filePath) {
    final format = getFormatByPath(filePath);
    if (format == null) return 'Unknown';

    if (isHighQualityFormat(filePath)) return 'High Quality';
    if (isStreamingOptimized(filePath)) return 'Streaming';
    if (format.extension.toLowerCase() == 'avi') return 'Standard';
    if (format.extension.toLowerCase() == '3gp') return 'Mobile';

    return 'Standard';
  }

  static Map<String, dynamic> getVideoInfo(String filePath) {
    final format = getFormatByPath(filePath);

    return {
      'format': format?.name ?? 'Unknown',
      'extension': format?.extension ?? '',
      'isSupported': format?.isSupported ?? false,
      'mimeTypes': format?.mimeTypes ?? [],
      'codecs': format?.commonCodecs ?? [],
      'notes': format?.notes ?? '',
      'quality': getQualityIndicator(filePath),
      'isHighQuality': isHighQualityFormat(filePath),
      'isStreamingOptimized': isStreamingOptimized(filePath),
    };
  }
}
