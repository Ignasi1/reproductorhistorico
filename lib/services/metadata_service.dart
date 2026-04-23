import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/song_track.dart';

class SongMetadata {
  const SongMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.coverBytes,
  });

  final String title;
  final String artist;
  final String album;
  final Duration? duration;
  final Uint8List? coverBytes;
}

class MetadataService {
  Future<SongMetadata> loadFromUrl({
    required String url,
    required String fileName,
  }) async {
    final fallbackTitle = SongTrack.cleanFilename(fileName);
    final fallback = SongMetadata(
      title: fallbackTitle,
      artist: SongTrack.unknownArtist,
      album: SongTrack.unknownAlbum,
      duration: null,
      coverBytes: null,
    );

    if (kIsWeb) {
      return fallback;
    }

    File? tempFile;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return fallback;
      }

      final directory = await getTemporaryDirectory();
      final safeFileName = _safeTempFileName(fileName);
      tempFile = File('${directory.path}/$safeFileName');
      await tempFile.writeAsBytes(response.bodyBytes, flush: true);

      final metadata = readMetadata(tempFile, getImage: true);
      final cover = metadata.pictures.isEmpty
          ? null
          : metadata.pictures.first.bytes;

      return SongMetadata(
        title: _withFallback(metadata.title, fallbackTitle),
        artist: _withFallback(metadata.artist, SongTrack.unknownArtist),
        album: _withFallback(metadata.album, SongTrack.unknownAlbum),
        duration: metadata.duration,
        coverBytes: cover,
      );
    } catch (_) {
      return fallback;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _withFallback(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  String _safeTempFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
