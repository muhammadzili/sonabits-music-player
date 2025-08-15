// lib/screens/offline_music_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/song_provider.dart';

class OfflineMusicScreen extends StatelessWidget {
  const OfflineMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Musik Offline'),
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          if (provider.downloadedSongs.isEmpty) {
            return const Center(
              child: Text('Anda belum mengunduh lagu.'),
            );
          }
          final songs = provider.downloadedSongs;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  // PERBAIKAN: Gunakan Image.file untuk menampilkan gambar lokal
                  child: song.localCoverPath != null
                      ? Image.file(
                          File(song.localCoverPath!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(width: 56, height: 56, color: Colors.grey),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist),
                onTap: () {
                  // PERBAIKAN: Mainkan lagu dan kembali ke home
                  Provider.of<SongProvider>(context, listen: false).playSong(songs, index);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              );
            },
          );
        },
      ),
    );
  }
}
