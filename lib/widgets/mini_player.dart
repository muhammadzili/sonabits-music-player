// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final song = songProvider.currentSong;
    final theme = Theme.of(context);

    if (song == null) {
      return const SizedBox.shrink();
    }

    final progress = (songProvider.currentPosition.inSeconds > 0 && songProvider.totalDuration.inSeconds > 0)
        ? songProvider.currentPosition.inSeconds / songProvider.totalDuration.inSeconds
        : 0.0;

    return GestureDetector(
      onTap: () => songProvider.maximizePlayer(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'coverArt_${song.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      song.coverArtUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text(song.artist, style: TextStyle(color: theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(songProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  iconSize: 32,
                  onPressed: () => songProvider.togglePlayPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => songProvider.stopSong(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.primary,
              minHeight: 2,
            ),
          ],
        ),
      ),
    );
  }
}
