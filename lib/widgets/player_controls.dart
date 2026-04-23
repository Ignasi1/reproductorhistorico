import 'package:flutter/material.dart';

import '../models/song_track.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isShuffle,
    required this.isRepeatOne,
    required this.volume,
    required this.position,
    required this.duration,
    required this.onToggleShuffle,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
    required this.onToggleRepeatOne,
    required this.onSeek,
    required this.onVolumeChanged,
  });

  final bool isPlaying;
  final bool isShuffle;
  final bool isRepeatOne;
  final double volume;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggleShuffle;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;
  final VoidCallback onToggleRepeatOne;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    final durationMs = duration.inMilliseconds;
    final hasDuration = durationMs > 0;
    final safeMaxMs = hasDuration ? durationMs : 1;
    final clampedPositionMs = position.inMilliseconds
        .clamp(0, safeMaxMs)
        .toDouble();

    return Container(
      color: const Color(0xFF2E5C8A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  SongTrack.formatDuration(position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              Expanded(
                child: Slider(
                  value: clampedPositionMs,
                  min: 0,
                  max: safeMaxMs.toDouble(),
                  onChanged: hasDuration
                      ? (value) => onSeek(Duration(milliseconds: value.round()))
                      : null,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  SongTrack.formatDuration(duration),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Shuffle',
                onPressed: onToggleShuffle,
                icon: Icon(
                  Icons.shuffle,
                  color: isShuffle ? const Color(0xFF1ABC9C) : Colors.white70,
                  size: 24,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: onPrevious,
              ),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: const Color(0xFF1ABC9C),
                  size: 56,
                ),
                onPressed: onTogglePlayPause,
              ),
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: onNext,
              ),
              IconButton(
                tooltip: 'Repeat one',
                onPressed: onToggleRepeatOne,
                icon: Icon(
                  Icons.repeat_one,
                  color: isRepeatOne ? const Color(0xFF1ABC9C) : Colors.white70,
                  size: 24,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white70),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: onVolumeChanged,
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white70),
              SizedBox(
                width: 44,
                child: Text(
                  '${(volume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
