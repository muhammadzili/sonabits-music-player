// lib/screens/playlist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<Song>> _songsInPlaylistFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _songsInPlaylistFuture = _fetchSongsInPlaylist();
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlist.songIds.length != oldWidget.playlist.songIds.length) {
      _songsInPlaylistFuture = _fetchSongsInPlaylist();
    }
  }

  Future<List<Song>> _fetchSongsInPlaylist() async {
    if (widget.playlist.songIds.isEmpty) return [];
    try {
      final data = await supabase.from('songs').select().inFilter('id', widget.playlist.songIds);
      final songMap = {for (var e in data) e['id'].toString(): Song.fromMap(e)};
      return widget.playlist.songIds.map((id) => songMap[id]).whereType<Song>().toList();
    } catch (e) {
      rethrow;
    }
  }
  
  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final provider = Provider.of<PlaylistProvider>(context, listen: false);
        return Wrap(
          children: [
            ListTile(
              leading: Icon(playlist.isPublic ? Icons.lock_outline : Icons.public),
              title: Text(playlist.isPublic ? 'Jadikan Private' : 'Jadikan Publik'),
              onTap: () {
                Navigator.pop(ctx);
                provider.setPlaylistVisibility(playlist.id, !playlist.isPublic);
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Visibilitas diubah ke ${!playlist.isPublic ? "Publik" : "Private"}')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
              title: Text('Hapus Playlist', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                 Navigator.pop(ctx);
                 _confirmDeletePlaylist(context, provider, playlist.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePlaylist(BuildContext context, PlaylistProvider provider, String playlistId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Playlist?'),
        content: const Text('Tindakan ini tidak dapat diurungkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deletePlaylist(playlistId).then((_) {
                 Navigator.pop(context);
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = supabase.auth.currentUser?.id == widget.playlist.ownerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPlaylistOptions(context, widget.playlist),
            ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsInPlaylistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final songs = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PlaylistHeader(
                  playlist: widget.playlist,
                  firstSong: songs.isNotEmpty ? songs.first : null,
                ),
              ),
              if (songs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Playlist ini kosong.')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(song.coverArtUrl, width: 56, height: 56, fit: BoxFit.cover),
                        ),
                        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(song.artist),
                        trailing: isOwner
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  Provider.of<PlaylistProvider>(context, listen: false)
                                      .removeSongFromPlaylist(song.id, widget.playlist.id);
                                  setState(() {
                                     _songsInPlaylistFuture = _fetchSongsInPlaylist();
                                  });
                                },
                              )
                            : null,
                        onTap: () {
                          Provider.of<SongProvider>(context, listen: false).playSong(songs, index);
                        },
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  final Playlist playlist;
  final Song? firstSong;

  const _PlaylistHeader({required this.playlist, this.firstSong});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: firstSong != null
                  ? Image.network(firstSong!.coverArtUrl, fit: BoxFit.cover)
                  : const Icon(Icons.queue_music_rounded, size: 80),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            playlist.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Playlist oleh ${playlist.ownerUsername}',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
