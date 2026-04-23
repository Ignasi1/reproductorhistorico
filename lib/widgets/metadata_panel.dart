import 'package:flutter/material.dart';

import '../models/song_track.dart';

class MetadataPanel extends StatelessWidget {
  const MetadataPanel({super.key, required this.track, required this.isWeb});

  final SongTrack track;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1F3864),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCover(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Artista: ${track.artist}',
                  style: const TextStyle(
                    color: Color(0xFFA8C4E0),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Àlbum: ${track.album}',
                  style: const TextStyle(
                    color: Color(0xFFA8C4E0),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Durada: ${SongTrack.formatDuration(track.duration)}',
                  style: const TextStyle(
                    color: Color(0xFF1ABC9C),
                    fontSize: 14,
                  ),
                ),
                if (isWeb)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Metadades/portada ID3 poden estar limitades en web.',
                      style: TextStyle(color: Color(0xFFFFC107), fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    if (track.coverBytes != null && track.coverBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          track.coverBytes!,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFF2E5C8A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Colors.white70, size: 40),
    );
  }
}
