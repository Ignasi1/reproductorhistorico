import 'package:flutter/material.dart';

import '../models/song_track.dart';

class SongListPanel extends StatefulWidget {
  const SongListPanel({
    super.key,
    required this.songs,
    required this.filteredIndexes,
    required this.currentIndex,
    required this.isPlaying,
    required this.query,
    required this.isLoading,
    required this.onQueryChanged,
    required this.onSongSelected,
  });

  final List<SongTrack> songs;
  final List<int> filteredIndexes;
  final int? currentIndex;
  final bool isPlaying;
  final String query;
  final bool isLoading;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onSongSelected;

  @override
  State<SongListPanel> createState() => _SongListPanelState();
}

class _SongListPanelState extends State<SongListPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant SongListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _searchController.text) {
      _searchController.text = widget.query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.songs.isEmpty) {
      return const Center(
        child: Text(
          'No hi ha cançons al bucket songs.\nPuja fitxers MP3 a Supabase Storage.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: widget.onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Cerca per nom de cançó...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        widget.onQueryChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(child: _buildSongList()),
      ],
    );
  }

  Widget _buildSongList() {
    if (widget.filteredIndexes.isEmpty) {
      return const Center(
        child: Text(
          'No hi ha coincidències amb aquesta cerca.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.filteredIndexes.length,
      itemBuilder: (context, listIndex) {
        final songIndex = widget.filteredIndexes[listIndex];
        final song = widget.songs[songIndex];
        final isActive = widget.currentIndex == songIndex;

        return ListTile(
          tileColor: isActive
              ? const Color(0xFF1ABC9C).withValues(alpha: 0.2)
              : null,
          leading: Icon(
            isActive && widget.isPlaying ? Icons.volume_up : Icons.music_note,
            color: isActive ? const Color(0xFF1ABC9C) : null,
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '${song.artist} • ${song.album}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => widget.onSongSelected(songIndex),
        );
      },
    );
  }
}
