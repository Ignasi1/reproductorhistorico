import 'dart:typed_data';

class SongTrack {
  const SongTrack({
    required this.fileName,
    required this.publicUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.coverBytes,
  });

  static const String unknownArtist = 'Artista desconegut';
  static const String unknownAlbum = 'Àlbum desconegut';

  final String fileName;
  final String publicUrl;
  final String title;
  final String artist;
  final String album;
  final Duration? duration;
  final Uint8List? coverBytes;

  String get cleanFileName {
    final baseName = _basename(fileName);
    final dot = baseName.lastIndexOf('.');
    if (dot <= 0) {
      return baseName;
    }
    return baseName.substring(0, dot);
  }

  SongTrack copyWith({
    String? fileName,
    String? publicUrl,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    Uint8List? coverBytes,
    bool clearDuration = false,
    bool clearCover = false,
  }) {
    return SongTrack(
      fileName: fileName ?? this.fileName,
      publicUrl: publicUrl ?? this.publicUrl,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: clearDuration ? null : (duration ?? this.duration),
      coverBytes: clearCover ? null : (coverBytes ?? this.coverBytes),
    );
  }

  static String cleanFilename(String filename) {
    final baseName = _basename(filename);
    final dot = baseName.lastIndexOf('.');
    if (dot <= 0) {
      return baseName;
    }
    return baseName.substring(0, dot);
  }

  static String formatDuration(Duration? duration) {
    if (duration == null) {
      return '--:--';
    }
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash < 0 || lastSlash + 1 >= normalized.length) {
      return normalized;
    }
    return normalized.substring(lastSlash + 1);
  }
}
