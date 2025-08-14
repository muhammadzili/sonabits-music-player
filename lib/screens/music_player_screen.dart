// lib/screens/music_player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';
import 'artist_screen.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late Timer _timer;
  int _gradientIndex = 0;

  final List<List<Color>> _gradientColors = [
    [Colors.green.shade800, const Color(0xFF121212)],
    [Colors.blue.shade800, const Color(0xFF121212)],
    [Colors.purple.shade800, const Color(0xFF121212)],
    [Colors.red.shade800, const Color(0xFF121212)],
    [Colors.orange.shade800, const Color(0xFF121212)],
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _gradientIndex = (_gradientIndex + 1) % _gradientColors.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
  
  // PERBAIKAN: Fungsi untuk menampilkan menu opsi
  void _showMoreOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Tambahkan ke Playlist'),
                onTap: () {
                  Navigator.pop(context); // Tutup menu
                  _showAddToPlaylistDialog(context, song); // Buka dialog playlist
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search_rounded),
                title: Text('Lihat Artis (${song.artist})'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistScreen(artistName: song.artist),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // PERBAIKAN: Dialog untuk memilih playlist
  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<PlaylistProvider>(
          builder: (context, playlistProvider, child) {
            return AlertDialog(
              title: const Text('Pilih Playlist'),
              content: SizedBox(
                width: double.maxFinite,
                child: playlistProvider.playlists.isEmpty
                    ? const Text('Anda belum punya playlist.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlistProvider.playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlistProvider.playlists[index];
                          return ListTile(
                            title: Text(playlist.name),
                            onTap: () {
                              playlistProvider.addSongToPlaylist(song, playlist.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ditambahkan ke "${playlist.name}"')),
                              );
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final song = songProvider.currentSong;
    final theme = Theme.of(context);

    if (song == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors[_gradientIndex],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                      onPressed: () => songProvider.minimizePlayer(),
                    ),
                    Row(
                      children: [
                        Icon(Icons.music_note_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text("Now Playing", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onPressed: () => _showMoreOptions(context, song),
                    ),
                  ],
                ),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Hero(
                      tag: 'coverArt_${song.id}',
                      child: AspectRatio(
                        aspectRatio: 1 / 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            song.coverArtUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Marquee(
                          text: song.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          velocity: 40.0,
                          blankSpace: 50.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Slider(
                      value: songProvider.currentPosition.inSeconds.toDouble().clamp(
                        0.0, 
                        songProvider.totalDuration.inSeconds.toDouble()
                      ),
                      max: songProvider.totalDuration.inSeconds.toDouble() > 0 
                           ? songProvider.totalDuration.inSeconds.toDouble() 
                           : 1.0,
                      onChanged: (value) {
                        songProvider.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(songProvider.currentPosition)),
                          Text(_formatDuration(songProvider.totalDuration)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 40,
                            onPressed: () => songProvider.playPrevious(),
                          ),
                          IconButton(
                            icon: Icon(songProvider.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                            iconSize: 70,
                            color: theme.colorScheme.primary,
                            onPressed: () => songProvider.togglePlayPause(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 40,
                            onPressed: () => songProvider.playNext(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
