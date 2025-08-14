// lib/screens/artist_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';

class ArtistScreen extends StatefulWidget {
  final String artistName;
  const ArtistScreen({super.key, required this.artistName});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<List<Song>> _artistSongsFuture;

  @override
  void initState() {
    super.initState();
    _artistSongsFuture = _fetchArtistSongs();
  }

  Future<List<Song>> _fetchArtistSongs() async {
    final data = await Supabase.instance.client
        .from('songs')
        .select()
        .eq('artist', widget.artistName);
    return data.map((map) => Song.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
      ),
      body: FutureBuilder<List<Song>>(
        future: _artistSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada lagu dari artis ini.'));
          }

          final songs = snapshot.data!;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    song.coverArtUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
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
}
