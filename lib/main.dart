import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/playback_controller.dart';
import 'widgets/metadata_panel.dart';
import 'widgets/player_controls.dart';
import 'widgets/song_list_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // The file may not exist on first run. The app handles missing keys below.
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final songsBucket = (dotenv.env['SUPABASE_BUCKET'] ?? 'songs').trim();
  final songsPath = (dotenv.env['SUPABASE_SONGS_PATH'] ?? '').trim();
  final hasSupabaseConfig =
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  if (hasSupabaseConfig) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  runApp(
    MyApp(
      hasSupabaseConfig: hasSupabaseConfig,
      songsBucket: songsBucket.isEmpty ? 'songs' : songsBucket,
      songsPath: songsPath,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.hasSupabaseConfig,
    required this.songsBucket,
    required this.songsPath,
  });

  final bool hasSupabaseConfig;
  final String songsBucket;
  final String songsPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reproductor Cloud',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1ABC9C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: hasSupabaseConfig
          ? MusicPlayerScreen(bucketName: songsBucket, bucketPath: songsPath)
          : const MissingConfigScreen(),
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuració pendent')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Falta la configuració de Supabase.\n\n'
            'Crea un fitxer .env a l\'arrel amb:\n'
            'SUPABASE_URL=...\n'
            'SUPABASE_ANON_KEY=...\n'
            'SUPABASE_BUCKET=songs (opcional)\n'
            'SUPABASE_SONGS_PATH= (opcional)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({
    super.key,
    required this.bucketName,
    required this.bucketPath,
  });

  final String bucketName;
  final String bucketPath;

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late final PlaybackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlaybackController(
      bucketName: widget.bucketName,
      bucketPath: widget.bucketPath,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final currentSong = state.currentSong;
        final filteredIndexes = _controller.filteredIndexes;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reproductor Cloud'),
            backgroundColor: const Color(0xFF1F3864),
            foregroundColor: Colors.white,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  kIsWeb ? Icons.web : Icons.phone_android,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.error != null) _ErrorBanner(message: state.error!),
              if (currentSong != null)
                MetadataPanel(track: currentSong, isWeb: kIsWeb),
              Expanded(
                child: SongListPanel(
                  songs: state.songs,
                  filteredIndexes: filteredIndexes,
                  currentIndex: state.currentIndex,
                  isPlaying: state.isPlaying,
                  query: state.query,
                  isLoading: state.isLoading,
                  onQueryChanged: _controller.setQuery,
                  onSongSelected: _controller.playAt,
                ),
              ),
              if (currentSong != null)
                PlayerControls(
                  isPlaying: state.isPlaying,
                  isShuffle: state.isShuffle,
                  isRepeatOne: state.isRepeatOne,
                  volume: state.volume,
                  position: state.position,
                  duration: state.duration,
                  onToggleShuffle: _controller.toggleShuffle,
                  onPrevious: _controller.previous,
                  onTogglePlayPause: _controller.togglePlayPause,
                  onNext: _controller.next,
                  onToggleRepeatOne: _controller.toggleRepeatOne,
                  onSeek: _controller.seek,
                  onVolumeChanged: _controller.setVolume,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF7F1D1D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}
