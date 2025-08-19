// lib/screens/playlist_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Future<List<Song>> _songsInPlaylistFuture;

  @override
  void initState() {
    super.initState();
    _songsInPlaylistFuture = _fetchSongsInPlaylist();
  }

  Future<List<Song>> _fetchSongsInPlaylist() async {
    if (widget.playlist.songIds.isEmpty) {
      return [];
    }
    try {
      final data = await Supabase.instance.client
          .from('songs')
          .select()
          .inFilter('id', widget.playlist.songIds);
      return data.map((map) => Song.fromMap(map)).toList();
    } on SocketException {
      // Tangkap error saat tidak ada koneksi internet
      throw const SocketException("Tidak ada koneksi internet");
    } catch (e) {
      // Tangkap error lainnya
      rethrow;
    }
  }

  // FUNGSI BARU: Untuk mencoba mengambil data lagi
  void _retryFetch() {
    setState(() {
      _songsInPlaylistFuture = _fetchSongsInPlaylist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsInPlaylistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // PERUBAHAN: Tampilkan UI khusus saat offline
          if (snapshot.hasError && snapshot.error is SocketException) {
            return _buildOfflineView(context);
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Playlist ini kosong.'));
          }

          final songs = snapshot.data!;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Hero(
                  tag: 'playlist_coverArt_${song.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      song.coverArtUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist),
                onTap: () {
                  Provider.of<SongProvider>(context, listen: false).playSong(songs, index);
                },
              );
            },
          );
        },
      ),
    );
  }

  // WIDGET BARU: Untuk tampilan offline
  Widget _buildOfflineView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              "Koneksi Terputus",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak dapat memuat lagu dari playlist. Periksa koneksi internet Anda.",
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _retryFetch,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }
}
