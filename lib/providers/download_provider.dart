// lib/providers/download_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class DownloadProvider with ChangeNotifier {
  final Dio _dio;
  List<Song> _downloadedSongs = [];
  List<Song> get downloadedSongs => _downloadedSongs;

  DownloadProvider()
      // PERBAIKAN: Konfigurasi Dio untuk koneksi yang lebih stabil
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 5), // Waktu lebih lama untuk menerima file besar
        )) {
    loadDownloadedSongs();
  }

  Future<void> loadDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson = prefs.getStringList('downloaded_songs') ?? [];
    _downloadedSongs = downloadedJson
        .map((json) => Song.fromMap(jsonDecode(json)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson = _downloadedSongs
        .map((song) => jsonEncode(song.toMap()))
        .toList();
    await prefs.setStringList('downloaded_songs', downloadedJson);
  }

  bool isDownloaded(String songId) {
    return _downloadedSongs.any((s) => s.id == songId);
  }

  Future<void> downloadSong(Song song, Function(double) onProgress) async {
    if (isDownloaded(song.id)) return;

    final dir = await getApplicationDocumentsDirectory();
    final songFilePath = '${dir.path}/${song.id}.mp3';
    final coverFilePath = '${dir.path}/${song.id}.jpg';

    try {
      // Unduh file lagu
      await _dio.download(
        song.songUrl,
        songFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress((received / total) * 0.95);
          }
        },
      );

      // Unduh file gambar
      await _dio.download(song.coverArtUrl, coverFilePath);
      onProgress(1.0);

      final downloadedSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        songUrl: song.songUrl,
        coverArtUrl: song.coverArtUrl,
        lyrics: song.lyrics,
        localPath: songFilePath,
        localCoverPath: coverFilePath,
      );

      _downloadedSongs.add(downloadedSong);
      await _saveDownloadedSongs();
      notifyListeners();
    } catch (e) {
      print('Error downloading song: $e');
      // PERBAIKAN: Cek apakah file ada sebelum menghapusnya
      final songFile = File(songFilePath);
      if (await songFile.exists()) {
        await songFile.delete();
      }
      final coverFile = File(coverFilePath);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }
      // Lempar error agar bisa ditangkap oleh UI
      throw Exception('Gagal mengunduh lagu. Periksa koneksi internet Anda.');
    }
  }
}
