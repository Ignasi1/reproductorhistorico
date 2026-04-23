import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/playback_state.dart';
import '../models/song_track.dart';
import '../services/metadata_service.dart';
import '../services/supabase_song_service.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({
    AudioPlayer? player,
    SupabaseSongService? songService,
    MetadataService? metadataService,
    Random? random,
    this.bucketName = 'songs',
    this.bucketPath = '',
  }) : _player = player ?? AudioPlayer(),
       _songService =
           songService ??
           SupabaseSongService(bucketName: bucketName, basePath: bucketPath),
       _metadataService = metadataService ?? MetadataService(),
       _random = random ?? Random() {
    _bindPlayerStreams();
    unawaited(_player.setVolume(_state.volume));
  }

  final AudioPlayer _player;
  final SupabaseSongService _songService;
  final MetadataService _metadataService;
  final Random _random;
  final String bucketName;
  final String bucketPath;
  final Map<String, SongMetadata> _metadataCache = {};
  final Map<String, Future<SongMetadata>> _metadataLoadsInFlight = {};

  PlaybackState _state = const PlaybackState.initial();
  PlaybackState get state => _state;

  List<int> get filteredIndexes => _state.filteredSongIndexes();

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  bool _handlingCompletion = false;
  int _playRequestId = 0;
  int _songsRevision = 0;

  Future<void> initialize() async {
    await loadSongs();
  }

  Future<void> loadSongs() async {
    _setState(_state.copyWith(isLoading: true, error: null));
    try {
      final songs = await _songService.loadSongs();
      _metadataCache.clear();
      _metadataLoadsInFlight.clear();
      _songsRevision++;
      final revision = _songsRevision;
      _setState(
        _state.copyWith(
          songs: songs,
          currentIndex: null,
          isPlaying: false,
          position: Duration.zero,
          duration: Duration.zero,
          isLoading: false,
          error: songs.isEmpty
              ? _buildEmptyBucketMessage(
                  bucketName: bucketName,
                  path: bucketPath,
                )
              : null,
        ),
      );
      if (songs.isNotEmpty) {
        unawaited(_preloadMetadataForAllSongs(revision));
      }
    } catch (e) {
      _setState(
        _state.copyWith(
          isLoading: false,
          error:
              'No s\'han pogut carregar les cancons de Supabase '
              '(bucket: $bucketName): $e',
        ),
      );
    }
  }

  void setQuery(String query) {
    _setState(_state.copyWith(query: query));
  }

  Future<void> playAt(int index) async {
    if (index < 0 || index >= _state.songs.length) {
      return;
    }

    final requestId = ++_playRequestId;
    final song = _state.songs[index];
    _setState(
      _state.copyWith(
        currentIndex: index,
        isPlaying: false,
        position: Duration.zero,
        duration: song.duration ?? Duration.zero,
        error: null,
      ),
    );

    try {
      await _player.stop();
      if (!_isLatestPlayRequest(requestId)) {
        return;
      }

      final loadedDuration = await _player.setUrl(song.publicUrl);
      if (!_isLatestPlayRequest(requestId)) {
        return;
      }

      _setState(
        _state.copyWith(
          currentIndex: index,
          isPlaying: false,
          position: Duration.zero,
          duration: loadedDuration ?? song.duration ?? Duration.zero,
          error: null,
        ),
      );
      unawaited(_startPlayback(requestId));

      unawaited(_loadMetadataForSong(index));
    } catch (e) {
      if (!_isLatestPlayRequest(requestId)) {
        return;
      }
      _setState(
        _state.copyWith(
          isPlaying: false,
          error: _buildPlaybackErrorMessage(e),
        ),
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (_state.currentIndex == null) {
      if (_state.songs.isNotEmpty) {
        await playAt(0);
      }
      return;
    }

    if (_state.isPlaying) {
      await _player.pause();
      _setState(_state.copyWith(isPlaying: false));
    } else {
      await _player.play();
      _setState(_state.copyWith(isPlaying: true));
    }
  }

  Future<void> next() async {
    if (_state.songs.isEmpty) {
      return;
    }

    final currentIndex = _state.currentIndex;
    if (currentIndex == null) {
      await playAt(0);
      return;
    }

    if (_state.isShuffle) {
      final nextIndex = _randomIndexDifferent(
        currentIndex,
        _state.songs.length,
      );
      await playAt(nextIndex);
      return;
    }

    final nextIndex = currentIndex + 1;
    if (nextIndex < _state.songs.length) {
      await playAt(nextIndex);
    }
  }

  Future<void> previous() async {
    final currentIndex = _state.currentIndex;
    if (currentIndex == null) {
      return;
    }
    final previousIndex = currentIndex - 1;
    if (previousIndex >= 0) {
      await playAt(previousIndex);
    }
  }

  Future<void> seek(Duration position) async {
    if (_state.currentIndex == null) {
      return;
    }
    final totalDuration = _state.duration;
    final maxMs = max(totalDuration.inMilliseconds, 0);
    final clampedMs = position.inMilliseconds.clamp(0, maxMs);
    final clamped = Duration(milliseconds: clampedMs);
    await _player.seek(clamped);
    _setState(_state.copyWith(position: clamped));
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    _setState(_state.copyWith(volume: clamped));
    try {
      await _player.setVolume(clamped);
    } catch (e) {
      _setState(
        _state.copyWith(
          error: 'No s\'ha pogut canviar el volum: $e',
        ),
      );
    }
  }

  void toggleShuffle() {
    _setState(_state.copyWith(isShuffle: !_state.isShuffle));
  }

  void toggleRepeatOne() {
    _setState(_state.copyWith(isRepeatOne: !_state.isRepeatOne));
  }

  void _bindPlayerStreams() {
    _positionSub = _player.positionStream.listen((position) {
      _setState(_state.copyWith(position: position));
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null) {
        _setState(_state.copyWith(duration: duration));
      }
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      _setState(_state.copyWith(isPlaying: playerState.playing));
      if (playerState.processingState == ProcessingState.completed) {
        unawaited(_handleTrackCompleted());
      }
    });
  }

  Future<void> _handleTrackCompleted() async {
    if (_handlingCompletion) {
      return;
    }
    _handlingCompletion = true;

    try {
      final currentIndex = _state.currentIndex;
      if (currentIndex == null) {
        return;
      }

      if (_state.isRepeatOne) {
        await _player.seek(Duration.zero);
        await _player.play();
        _setState(
          _state.copyWith(
            position: Duration.zero,
            isPlaying: true,
            isRepeatOne: false,
          ),
        );
        return;
      }

      if (_state.isShuffle) {
        final nextIndex = _randomIndexDifferent(
          currentIndex,
          _state.songs.length,
        );
        await playAt(nextIndex);
        return;
      }

      final nextIndex = currentIndex + 1;
      if (nextIndex < _state.songs.length) {
        await playAt(nextIndex);
      } else {
        await _player.pause();
        _setState(_state.copyWith(isPlaying: false, position: _state.duration));
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  int _randomIndexDifferent(int current, int length) {
    if (length <= 1) {
      return current;
    }

    var candidate = current;
    while (candidate == current) {
      candidate = _random.nextInt(length);
    }
    return candidate;
  }

  Future<void> _loadMetadataForSong(int index) async {
    if (index < 0 || index >= _state.songs.length) {
      return;
    }

    final song = _state.songs[index];
    final cached = _metadataCache[song.fileName];
    if (cached != null) {
      _applyMetadata(
        index: index,
        expectedFileName: song.fileName,
        metadata: cached,
      );
      return;
    }

    final existingLoad = _metadataLoadsInFlight[song.fileName];
    final load = existingLoad ??
        _metadataService.loadFromUrl(
          url: song.publicUrl,
          fileName: song.fileName,
        );
    if (existingLoad == null) {
      _metadataLoadsInFlight[song.fileName] = load;
    }

    late final SongMetadata metadata;
    try {
      metadata = await load;
    } finally {
      _metadataLoadsInFlight.remove(song.fileName);
    }
    _metadataCache[song.fileName] = metadata;
    _applyMetadata(
      index: index,
      expectedFileName: song.fileName,
      metadata: metadata,
    );
  }

  Future<void> _preloadMetadataForAllSongs(int revision) async {
    for (var i = 0; i < _state.songs.length; i++) {
      if (revision != _songsRevision) {
        return;
      }
      await _loadMetadataForSong(i);
    }
  }

  Future<void> _startPlayback(int requestId) async {
    try {
      await _player.play();
    } catch (e) {
      if (!_isLatestPlayRequest(requestId)) {
        return;
      }
      _setState(
        _state.copyWith(
          isPlaying: false,
          error: _buildPlaybackErrorMessage(e),
        ),
      );
    }
  }

  bool _isLatestPlayRequest(int requestId) => requestId == _playRequestId;

  void _applyMetadata({
    required int index,
    required String expectedFileName,
    required SongMetadata metadata,
  }) {
    if (index < 0 || index >= _state.songs.length) {
      return;
    }

    final targetSong = _state.songs[index];
    if (targetSong.fileName != expectedFileName) {
      return;
    }
    final updatedSong = targetSong.copyWith(
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      duration: metadata.duration,
      coverBytes: metadata.coverBytes,
    );

    final updatedSongs = List<SongTrack>.from(_state.songs);
    updatedSongs[index] = updatedSong;

    final shouldUpdateDuration =
        _state.currentIndex == index &&
        _state.duration == Duration.zero &&
        metadata.duration != null;

    _setState(
      _state.copyWith(
        songs: updatedSongs,
        duration: shouldUpdateDuration ? metadata.duration : _state.duration,
      ),
    );
  }

  void _setState(PlaybackState newState) {
    _state = newState;
    notifyListeners();
  }

  String _buildEmptyBucketMessage({
    required String bucketName,
    required String path,
  }) {
    final trimmedPath = path.trim();
    if (trimmedPath.isNotEmpty) {
      return 'No s\'han trobat audios a "$bucketName/$trimmedPath". '
          'Revisa permisos SELECT a storage.objects per anon.';
    }
    return 'No s\'han trobat audios al bucket "$bucketName". '
        'Revisa permisos SELECT a storage.objects per anon.';
  }

  String _buildPlaybackErrorMessage(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('missingpluginexception')) {
      return 'No s\'ha pogut reproduir la canco: backend d\'audio no disponible '
          'aquesta plataforma. Si executes en Windows, comprova '
          'just_audio_windows.';
    }

    if (lower.contains('source error') ||
        lower.contains('url') ||
        lower.contains('http')) {
      return 'No s\'ha pogut reproduir la canco (error de streaming): $raw';
    }

    return 'No s\'ha pogut reproduir la canco: $raw';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
