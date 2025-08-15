// lib/screens/home_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/song.dart';
import '../providers/song_provider.dart';
import 'offline_music_screen.dart'; // Import halaman offline

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Song>>? _songsFuture;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _songsFuture = _fetchSongs();
  }

  Future<List<Song>> _fetchSongs({String query = ''}) async {
    try {
      final client = Supabase.instance.client;
      PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder;

      if (query.isNotEmpty) {
        queryBuilder = client.from('songs').select().ilike('title', '%$query%');
      } else {
        queryBuilder = client.from('songs').select();
      }
      
      final data = await queryBuilder;
      final songs = data.map((map) => Song.fromMap(map)).toList();
      if (query.isEmpty) {
        songs.shuffle(Random());
      }
      return songs;
    } on SocketException {
      // Tangkap error spesifik saat tidak ada koneksi internet
      throw const SocketException("Tidak ada koneksi internet");
    } catch (e) {
      // Tangkap error lainnya
      rethrow;
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        _songsFuture = _fetchSongs();
      }
    });
  }
  
  void _retryFetch() {
    setState(() {
      _songsFuture = _fetchSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isSearching ? 0 : 1,
                  child: Text("Sonabits", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                _buildAnimatedSearchBar(constraints.maxWidth),
              ],
            );
          }
        ),
        actions: const [], 
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // PERBAIKAN: Tampilkan UI khusus saat offline
          if (snapshot.hasError && snapshot.error is SocketException) {
            return _buildOfflineView(context);
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Lagu tidak ditemukan.'));
          }

          final allSongs = snapshot.data!;
          final topSongs = allSongs.take(3).toList();
          final otherSongs = allSongs.skip(3).toList();

          if (_searchController.text.isNotEmpty) {
             return _buildSongList(allSongs, "Hasil Pencarian", allSongs);
          }

          return RefreshIndicator(
            onRefresh: () async => _retryFetch(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Top 3 Pilihan Untukmu",
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: topSongs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final song = topSongs[index];
                      return _TopSongCard(
                        song: song,
                        onTap: () => Provider.of<SongProvider>(context, listen: false).playSong(topSongs, index),
                      );
                    },
                  ),
                ),
                if (otherSongs.isNotEmpty)
                  _buildSongList(otherSongs, "Lagu Lainnya", otherSongs),
              ],
            ),
          );
        },
      ),
    );
  }

  // PERBAIKAN: Widget baru untuk tampilan offline
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
              "Anda sedang offline. Putar musik yang sudah diunduh atau coba lagi.",
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _retryFetch,
                  child: const Text("Coba Lagi"),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineMusicScreen()));
                  },
                  child: const Text("Buka Musik Offline"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSearchBar(double maxWidth) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: _isSearching ? maxWidth : 48,
        height: 50,
        decoration: BoxDecoration(
          color: _isSearching ? theme.inputDecorationTheme.fillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: _isSearching
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _toggleSearch,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: "Cari lagu...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 4),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _songsFuture = _fetchSongs(query: query);
                        });
                      },
                    ),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.search),
                onPressed: _toggleSearch,
                padding: EdgeInsets.zero,
              ),
      ),
    );
  }

  Widget _buildSongList(List<Song> songs, String title, List<Song> playlist) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: Hero(
                tag: 'coverArt_${song.id}',
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
                Provider.of<SongProvider>(context, listen: false).playSong(playlist, index);
              },
            );
          },
        ),
      ],
    );
  }
}

class _TopSongCard extends StatelessWidget {
  const _TopSongCard({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'coverArt_${song.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    song.coverArtUrl,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artist,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
