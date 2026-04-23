import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/song_track.dart';

class SupabaseSongService {
  SupabaseSongService({
    SupabaseClient? client,
    this.bucketName = 'songs',
    this.basePath = '',
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String bucketName;
  final String basePath;

  static const _supportedAudioExtensions = <String>{
    '.mp3',
    '.wav',
    '.m4a',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.webm',
  };

  Future<List<SongTrack>> loadSongs() async {
    final normalizedBasePath = _normalizePath(basePath);
    final filePaths = await _listFilePathsRecursively(normalizedBasePath);
    final audioPaths = filePaths.where(_isAudioPath).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return audioPaths.map((path) {
      final fallbackTitle = SongTrack.cleanFilename(path);
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(path);
      return SongTrack(
        fileName: path,
        publicUrl: publicUrl,
        title: fallbackTitle,
        artist: SongTrack.unknownArtist,
        album: SongTrack.unknownAlbum,
        duration: null,
        coverBytes: null,
      );
    }).toList();
  }

  Future<List<String>> _listFilePathsRecursively(String prefix) async {
    final entries = prefix.isEmpty
        ? await _client.storage.from(bucketName).list()
        : await _client.storage.from(bucketName).list(path: prefix);
    final paths = <String>[];

    for (final entry in entries) {
      final name = entry.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final fullPath = _joinPath(prefix, name);
      if (_isAudioPath(fullPath)) {
        paths.add(fullPath);
        continue;
      }

      if (_looksLikeFolder(entry)) {
        try {
          final nested = await _listFilePathsRecursively(fullPath);
          paths.addAll(nested);
          continue;
        } catch (_) {
          // Some providers can report folder-like entries for files.
          // If listing as a folder fails, treat it as a file path.
        }
      }
      if (_looksLikeFolderName(name)) {
        try {
          final nested = await _listFilePathsRecursively(fullPath);
          if (nested.isNotEmpty) {
            paths.addAll(nested);
          }
        } catch (_) {
          // Not a folder, ignore.
        }
      }
    }

    return paths;
  }

  bool _looksLikeFolder(FileObject entry) {
    if (entry.id == null) {
      return true;
    }
    final noMetadata = entry.metadata == null;
    final hasNoExtension = !entry.name.contains('.');
    return noMetadata && hasNoExtension;
  }

  bool _isAudioPath(String path) {
    final lower = path.toLowerCase();
    return _supportedAudioExtensions.any(lower.endsWith);
  }

  bool _looksLikeFolderName(String name) {
    return !name.contains('.');
  }

  String _normalizePath(String path) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  String _joinPath(String prefix, String name) {
    if (prefix.isEmpty) {
      return name;
    }
    return '$prefix/$name';
  }
}
