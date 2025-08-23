// lib/screens/public_playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import 'playlist_detail_screen.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({super.key});

  @override
  State<PublicPlaylistsScreen> createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends State<PublicPlaylistsScreen> {
  final _searchController = TextEditingController();
  Future<List<Playlist>>? _searchFuture;

  void _search() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _searchFuture = Provider.of<PlaylistProvider>(context, listen: false)
            .searchPublicPlaylists(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Playlist Publik'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama playlist...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: _searchFuture == null
                ? const Center(child: Text('Mulai cari playlist publik.'))
                : FutureBuilder<List<Playlist>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Playlist tidak ditemukan.'));
                      }

                      final playlists = snapshot.data!;
                      return ListView.builder(
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return _PlaylistCard(playlist: playlist);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistCard({required this.playlist});

  // Helper untuk mendapatkan gambar lagu pertama
  Future<String?> _getFirstSongCover() async {
    if (playlist.songIds.isEmpty) return null;
    try {
      final data = await Supabase.instance.client
          .from('songs')
          .select('cover_art_url')
          .eq('id', playlist.songIds.first)
          .single();
      return data['cover_art_url'];
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: FutureBuilder<String?>(
          future: _getFirstSongCover(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(snapshot.data!, width: 56, height: 56, fit: BoxFit.cover),
              );
            }
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.queue_music_rounded),
            );
          },
        ),
        title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Playlist oleh ${playlist.ownerUsername}\n${playlist.songIds.length} lagu'),
        isThreeLine: true,
        onTap: () {
          // Navigasi ke halaman detail yang sama, tapi dengan playlist publik
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
      ),
    );
  }
}
