// lib/providers/playlist_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class PlaylistProvider with ChangeNotifier {
  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    loadPlaylists();
  }

  // Memuat semua playlist dari local storage
  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getStringList('playlists') ?? [];
    _playlists = playlistsJson.map((json) => Playlist.fromJson(jsonDecode(json))).toList();
    notifyListeners();
  }

  // Menyimpan semua playlist ke local storage
  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = _playlists.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('playlists', playlistsJson);
  }

  // Membuat playlist baru
  Future<void> createPlaylist(String name) async {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
    );
    _playlists.add(newPlaylist);
    await _savePlaylists();
    notifyListeners();
  }

  // Menambahkan lagu ke playlist yang dipilih
  Future<void> addSongToPlaylist(Song song, String playlistId) async {
    try {
      final playlist = _playlists.firstWhere((p) => p.id == playlistId);
      if (!playlist.songIds.contains(song.id)) {
        playlist.songIds.add(song.id);
        await _savePlaylists();
        notifyListeners();
      }
    } catch (e) {
      // Handle jika playlist tidak ditemukan
      print("Error adding song: Playlist not found.");
    }
  }
}
