// lib/screens/music_player_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../providers/download_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';
import '../models/song.dart';
import 'artist_screen.dart';

// Kelas untuk menampung data lirik yang sudah diparsing
class LyricLine {
  final Duration timestamp;
  final String text;
  LyricLine(this.timestamp, this.text);
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late Timer _timer;
  int _gradientIndex = 0;
  bool _showLyrics = false;

  // Variabel untuk lirik manual
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  final ScrollController _lyricScrollController = ScrollController();

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
    // Panggil parsing lirik saat pertama kali build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _parseLyrics();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _lyricScrollController.dispose();
    super.dispose();
  }
  
  // Fungsi untuk mem-parsing string LRC menjadi data yang bisa digunakan
  void _parseLyrics() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final lyricsString = songProvider.currentSong?.lyrics;
    if (lyricsString == null || lyricsString.isEmpty) {
      setState(() {
        _lyrics = [];
      });
      return;
    }

    final lines = lyricsString.split('\n');
    final List<LyricLine> parsedLyrics = [];
    final RegExp lrcRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (var line in lines) {
      final match = lrcRegex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!;
        parsedLyrics.add(LyricLine(Duration(minutes: min, seconds: sec, milliseconds: ms), text));
      }
    }
    setState(() {
      _lyrics = parsedLyrics;
    });
  }

  // PERBAIKAN: Fungsi untuk update lirik yang aktif dan scroll ke tengah
  void _updateLyric(Duration position) {
    if (_lyrics.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (position >= _lyrics[i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });
      
      if (_currentLyricIndex != -1 && _lyricScrollController.hasClients) {
        final itemHeight = 60.0; // Tinggi tetap untuk setiap baris lirik
        
        // Offset dihitung agar item berada di tengah viewport
        final scrollOffset = (_currentLyricIndex * itemHeight);

        _lyricScrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _showMoreOptions(BuildContext context, Song song) {
    final isDownloaded = Provider.of<DownloadProvider>(context, listen: false).isDownloaded(song.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded),
                title: Text(isDownloaded ? 'Sudah Diunduh' : 'Unduh untuk mode offline'),
                enabled: !isDownloaded,
                onTap: () {
                  Navigator.pop(context);
                  if (!isDownloaded) {
                    _showDownloadDialog(context, song);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Tambahkan ke Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search_rounded),
                title: Text('Lihat Artis (${song.artist})'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistScreen(artistName: song.artist)));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DownloadDialog(song: song),
    );
  }

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
    
    _updateLyric(songProvider.currentPosition);

    final hasLyrics = song.lyrics != null && song.lyrics!.isNotEmpty;

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
                    const Text("Now Playing", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasLyrics)
                          IconButton(
                            icon: Icon(_showLyrics ? Icons.image_rounded : Icons.lyrics_rounded),
                            onPressed: () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded),
                          onPressed: () => _showMoreOptions(context, song),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _showLyrics && hasLyrics
                        ? _buildLyricsView()
                        : _buildCoverView(song, theme),
                  ),
                ),
                Column(
                  children: [
                    Slider(
                      value: songProvider.currentPosition.inSeconds.toDouble().clamp(0.0, songProvider.totalDuration.inSeconds.toDouble()),
                      max: songProvider.totalDuration.inSeconds.toDouble() > 0 ? songProvider.totalDuration.inSeconds.toDouble() : 1.0,
                      onChanged: (value) => songProvider.seek(Duration(seconds: value.toInt())),
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
                          IconButton(icon: const Icon(Icons.skip_previous_rounded), iconSize: 40, onPressed: () => songProvider.playPrevious()),
                          IconButton(
                            icon: Icon(songProvider.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                            iconSize: 70,
                            color: theme.colorScheme.primary,
                            onPressed: () => songProvider.togglePlayPause(),
                          ),
                          IconButton(icon: const Icon(Icons.skip_next_rounded), iconSize: 40, onPressed: () => songProvider.playNext()),
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

  Widget _buildCoverView(Song song, ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('coverView'),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Hero(
            tag: 'coverArt_${song.id}',
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(song.coverArtUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 40),
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
          Text(song.artist, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildLyricsView() {
    return LayoutBuilder(
      key: const ValueKey('lyricsView'),
      builder: (context, constraints) {
        final viewHeight = constraints.maxHeight;
        const itemHeight = 60.0;
        return ListView.builder(
          controller: _lyricScrollController,
          padding: EdgeInsets.symmetric(vertical: (viewHeight / 2) - (itemHeight / 2)),
          itemCount: _lyrics.length,
          itemBuilder: (context, index) {
            final line = _lyrics[index];
            final bool isActive = index == _currentLyricIndex;
            return Container(
              height: itemHeight,
              alignment: Alignment.center,
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: isActive
                    ? GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
                    : GoogleFonts.poppins(color: Colors.white.withOpacity(0.4), fontSize: 18),
              ),
            );
          },
        );
      },
    );
  }
}

class _DownloadDialog extends StatefulWidget {
  final Song song;
  const _DownloadDialog({required this.song});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await Provider.of<DownloadProvider>(context, listen: false)
          .downloadSong(widget.song, (p) {
        if (mounted) {
          setState(() {
            _progress = p;
          });
        }
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lagu berhasil diunduh!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_error == null ? 'Mengunduh Lagu...' : 'Unduhan Gagal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
          else ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ]
        ],
      ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          )
      ],
    );
  }
}
