import 'song_track.dart';

class PlaybackState {
  const PlaybackState({
    required this.songs,
    required this.currentIndex,
    required this.isPlaying,
    required this.isShuffle,
    required this.isRepeatOne,
    required this.volume,
    required this.position,
    required this.duration,
    required this.query,
    required this.isLoading,
    required this.error,
  });

  const PlaybackState.initial()
    : songs = const [],
      currentIndex = null,
      isPlaying = false,
      isShuffle = false,
      isRepeatOne = false,
      volume = 1,
      position = Duration.zero,
      duration = Duration.zero,
      query = '',
      isLoading = true,
      error = null;

  final List<SongTrack> songs;
  final int? currentIndex;
  final bool isPlaying;
  final bool isShuffle;
  final bool isRepeatOne;
  final double volume;
  final Duration position;
  final Duration duration;
  final String query;
  final bool isLoading;
  final String? error;

  SongTrack? get currentSong {
    if (currentIndex == null) {
      return null;
    }
    if (currentIndex! < 0 || currentIndex! >= songs.length) {
      return null;
    }
    return songs[currentIndex!];
  }

  List<int> filteredSongIndexes() {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return List<int>.generate(songs.length, (index) => index);
    }

    final lowerQuery = trimmed.toLowerCase();
    final indexes = <int>[];
    for (var i = 0; i < songs.length; i++) {
      final song = songs[i];
      final matchesName = song.cleanFileName.toLowerCase().contains(lowerQuery);
      final matchesTitle = song.title.toLowerCase().contains(lowerQuery);
      if (matchesName || matchesTitle) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  static const Object _unset = Object();

  PlaybackState copyWith({
    List<SongTrack>? songs,
    Object? currentIndex = _unset,
    bool? isPlaying,
    bool? isShuffle,
    bool? isRepeatOne,
    double? volume,
    Duration? position,
    Duration? duration,
    String? query,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return PlaybackState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex == _unset
          ? this.currentIndex
          : currentIndex as int?,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeatOne: isRepeatOne ?? this.isRepeatOne,
      volume: volume ?? this.volume,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }
}
