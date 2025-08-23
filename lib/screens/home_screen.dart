// lib/screens/home_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart'; // <-- PERBAIKAN: Path import yang benar
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/song_provider.dart';
import 'offline_music_screen.dart';
import 'playlist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>>? _dataFuture; // Bisa berisi Song atau Playlist
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchInitialSongs();
  }

  Future<List<dynamic>> _fetchInitialSongs() async {
    return _fetchSongs();
  }

  Future<List<Song>> _fetchSongs({String query = ''}) async {
    final client = Supabase.instance.client;
    PostgrestFilterBuilder<List<Map<String, dynamic>>> queryBuilder;
    if (query.isNotEmpty) {
      queryBuilder = client.from('songs').select().ilike('title', '%$query%');
    } else {
      queryBuilder = client.from('songs').select();
    }
    final data = await queryBuilder;
    final songs = data.map((map) => Song.fromMap(map)).toList();
    if (query.isEmpty) songs.shuffle(Random());
    return songs;
  }

  Future<List<dynamic>> _performSearch(String query) async {
    if (query.isEmpty) return _fetchInitialSongs();
    
    final songFuture = _fetchSongs(query: query);
    final playlistFuture = Provider.of<PlaylistProvider>(context, listen: false)
        .searchPublicPlaylists(query);

    final results = await Future.wait([songFuture, playlistFuture]);
    
    final combinedList = <dynamic>[];
    combinedList.addAll(results[0]); // Lagu
    combinedList.addAll(results[1]); // Playlist
    
    return combinedList;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchController.clear();
        _dataFuture = _fetchInitialSongs();
      }
    });
  }
  
  void _retryFetch() {
    setState(() {
      _dataFuture = _fetchInitialSongs();
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
                  child: Image.asset('assets/icon/sona.png', height: 32),
                ),
                _buildAnimatedSearchBar(constraints.maxWidth),
              ],
            );
          }
        ),
        actions: const [], 
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.error is SocketException) {
            return _buildOfflineView(context);
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada hasil ditemukan.'));
          }

          final allData = snapshot.data!;
          
          if (_searchController.text.isNotEmpty) {
             return _buildSearchResultsList(allData);
          }

          final allSongs = allData.whereType<Song>().toList();
          return RefreshIndicator(
            onRefresh: () async => _retryFetch(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Top 3 Pilihan Untukmu", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allSongs.take(3).length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        return _TopSongCard(
                          song: song,
                          onTap: () => Provider.of<SongProvider>(context, listen: false).playSong(allSongs.take(3).toList(), index),
                        );
                      },
                    ),
                  ),
                ),
                if (allSongs.length > 3) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Lagu Lainnya", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = allSongs.skip(3).toList()[index];
                        return _SongListTile(song: song, playlist: allSongs.skip(3).toList(), index: index);
                      },
                      childCount: allSongs.length - 3,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
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
                  IconButton(icon: const Icon(Icons.arrow_back), onPressed: _toggleSearch),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: "Cari lagu atau playlist...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 4),
                      ),
                      onChanged: (query) {
                        setState(() {
                          _dataFuture = _performSearch(query);
                        });
                      },
                    ),
                  ),
                ],
              )
            : IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch, padding: EdgeInsets.zero),
      ),
    );
  }
  
  Widget _buildSearchResultsList(List<dynamic> data) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        if (item is Song) {
          return _SongListTile(song: item, playlist: data.whereType<Song>().toList(), index: data.whereType<Song>().toList().indexOf(item));
        } else if (item is Playlist) {
          return _PlaylistListTile(playlist: item);
        }
        return const SizedBox.shrink();
      },
    );
  }

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
}

class _SongListTile extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final int index;

  const _SongListTile({required this.song, required this.playlist, required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Hero(
        tag: 'coverArt_${song.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(song.coverArtUrl, width: 56, height: 56, fit: BoxFit.cover),
        ),
      ),
      title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(song.artist),
      onTap: () {
        Provider.of<SongProvider>(context, listen: false).playSong(playlist, index);
      },
    );
  }
}

class _PlaylistListTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistListTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.queue_music_rounded),
      ),
      title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Playlist oleh ${playlist.ownerUsername}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlaylistDetailScreen(playlist: playlist)),
        );
      },
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
