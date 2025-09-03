// lib/screens/music_player_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:marquee/marquee.dart';
import '../providers/download_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';
import '../models/song.dart';
import 'artist_screen.dart';

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

class _MusicPlayerScreenState extends State<MusicPlayerScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _gradientIndex = 0;
  bool _showLyrics = false;
  List<LyricLine> _lyrics = [];
  final ScrollController _lyricScrollController = ScrollController();
  bool _isLoadingLyrics = false;
  String? _processedSongId;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  double? _dragValue;

  SongProvider? _songProvider;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic));
    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() => _gradientIndex = (_gradientIndex + 1) % _gradientColors.length);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _songProvider = Provider.of<SongProvider>(context, listen: false);
      _songProvider?.addListener(_onProviderUpdate);
      _processNewSongLyrics();
    });
  }

  void _onProviderUpdate() {
    if (mounted) {
      setState(() {
        // This empty call is enough to trigger a rebuild with the latest provider data.
      });
    }
  }

  @override
  void dispose() {
    _songProvider?.removeListener(_onProviderUpdate);
    _timer.cancel();
    _lyricScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _processNewSongLyrics() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final currentSong = songProvider.currentSong;

    if (currentSong != null && currentSong.id != _processedSongId) {
      if (mounted) {
        setState(() {
          _isLoadingLyrics = true;
          _lyrics = [];
          _processedSongId = currentSong.id;
        });
      }
      final parsedLyrics = _parseLyricsFromString(currentSong.lyrics);
      if (mounted) {
        setState(() {
          _lyrics = parsedLyrics;
          _isLoadingLyrics = false;
        });
      }
    }
  }

  List<LyricLine> _parseLyricsFromString(String? lyricsString) {
    if (lyricsString == null || lyricsString.isEmpty) return [];
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
    return parsedLyrics;
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context); // listen: true (default)
    final song = songProvider.currentSong;
    final theme = Theme.of(context);

    if (song == null) {
      return SlideTransition(
        position: _slideAnimation,
        child: const SizedBox.shrink(),
      );
    }

    final hasLyrics = song.lyrics != null && song.lyrics!.isNotEmpty;
    final position = songProvider.currentPosition;
    final duration = songProvider.totalDuration;
    final double maxDuration = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;
    final sliderValue = (_dragValue ?? position.inSeconds.toDouble()).clamp(0.0, maxDuration);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
                child: SingleChildScrollView( // Membuat seluruh konten bisa di-scroll
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30), onPressed: _minimizePlayer),
                          const Text("Now Playing", style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasLyrics)
                                IconButton(
                                  icon: Icon(_showLyrics ? Icons.image_rounded : Icons.lyrics_rounded),
                                  onPressed: () => setState(() => _showLyrics = !_showLyrics),
                                ),
                              IconButton(icon: const Icon(Icons.more_horiz_rounded), onPressed: () => _showMoreOptions(context, song)),
                            ],
                          ),
                        ],
                      ),
                      
                      // Cover atau Lirik
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _showLyrics && hasLyrics
                            ? _buildLyricsView(position)
                            : _buildCoverView(song, theme),
                      ),
                      
                      // Kontrol Player
                      Slider(
                        value: sliderValue,
                        max: maxDuration,
                        onChangeStart: (value) => setState(() => _dragValue = value),
                        onChanged: (value) => setState(() => _dragValue = value),
                        onChangeEnd: (value) {
                          songProvider.seek(Duration(seconds: value.toInt()));
                          setState(() => _dragValue = null);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(icon: const Icon(Icons.skip_previous_rounded), iconSize: 40, onPressed: songProvider.playPrevious),
                            IconButton(
                              icon: Icon(songProvider.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                              iconSize: 70,
                              color: theme.colorScheme.primary,
                              onPressed: songProvider.togglePlayPause,
                            ),
                            IconButton(icon: const Icon(Icons.skip_next_rounded), iconSize: 40, onPressed: songProvider.playNext),
                          ],
                        ),
                      ),
                      
                      // Bagian Credits
                      if (!_showLyrics) _buildCreditsSection(song),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget baru untuk menampilkan bagian credits dengan gaya
  Widget _buildCreditsSection(Song song) {
    final credits = song.credits;
    if (credits == null || credits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'Credits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: credits.length,
            itemBuilder: (context, index) {
              final creditString = credits[index];
              String name = '';
              String role = '';

              final parts = creditString.split('[');
              if (parts.length == 2) {
                name = parts[0].trim();
                role = parts[1].replaceAll(']', '').trim();
              } else {
                name = creditString;
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                leading: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 16),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  role,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    if (!songProvider.isPlayerMinimized) {
      _minimizePlayer();
      return false;
    }
    return true;
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

  Future<void> _minimizePlayer() async {
    await _animationController.reverse();
    if (mounted) {
      Provider.of<SongProvider>(context, listen: false).minimizePlayer();
    }
  }

  Widget _buildCoverView(Song song, ThemeData theme) {
    return Column(
      key: const ValueKey('coverView'),
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
    );
  }

  Widget _buildLyricsView(Duration position) {
    if (_isLoadingLyrics) {
      return const Center(key: ValueKey('lyricsLoading'), child: CircularProgressIndicator());
    }
    if (_lyrics.isEmpty) {
      return const Center(key: ValueKey('noLyrics'), child: Text("Lirik tidak tersedia."));
    }

    int currentLyricIndex = -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (position >= _lyrics[i].timestamp) {
        currentLyricIndex = i;
      } else {
        break;
      }
    }

    if (currentLyricIndex != -1 && _lyricScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lyricScrollController.animateTo(
            (currentLyricIndex * 60.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }

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
            final bool isActive = index == currentLyricIndex;
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

class _DebugInfo extends StatelessWidget {
  final SongProvider songProvider;

  const _DebugInfo({required this.songProvider});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEBUG INFO:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 12)),
          Text('Is Playing: ${songProvider.isPlaying}', style: const TextStyle(color: Colors.white, fontSize: 10)),
          Text('Position: ${songProvider.currentPosition}', style: const TextStyle(color: Colors.white, fontSize: 10)),
          Text('Duration: ${songProvider.totalDuration}', style: const TextStyle(color: Colors.white, fontSize: 10)),
          Text('Cover URL: ${songProvider.currentSong?.coverArtUrl ?? "null"}', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
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
