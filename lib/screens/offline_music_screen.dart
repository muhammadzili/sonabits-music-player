// lib/screens/offline_music_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/download_provider.dart';
import '../providers/song_provider.dart';

class OfflineMusicScreen extends StatelessWidget {
  const OfflineMusicScreen({super.key});

  // FUNGSI BARU: Untuk menampilkan dialog konfirmasi penghapusan
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, DownloadProvider provider, Song song) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lagu'),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${song.title}" dari musik offline? Tindakan ini tidak dapat diurungkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Mengembalikan false
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true), // Mengembalikan true
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    // Jika pengguna menekan "Hapus" di dialog
    if (shouldDelete == true && context.mounted) {
      await provider.deleteSong(song.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${song.title}" telah dihapus')),
      );
    }
  }

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off_rounded, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Anda belum mengunduh lagu.'),
                ],
              ),
            );
          }
          final songs = provider.downloadedSongs;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: song.localCoverPath != null
                      ? Image.file(
                          File(song.localCoverPath!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56, height: 56, color: Colors.grey),
                ),
                title: Text(song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artist),
                // PERUBAHAN: Mengganti Dismissible dengan IconButton
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error),
                  onPressed: () {
                    // Panggil dialog konfirmasi saat ikon ditekan
                    _showDeleteConfirmationDialog(context, provider, song);
                  },
                ),
                onTap: () {
                  Provider.of<SongProvider>(context, listen: false)
                      .playSong(songs, index);
                },
              );
            },
          );
        },
      ),
    );
  }
}
