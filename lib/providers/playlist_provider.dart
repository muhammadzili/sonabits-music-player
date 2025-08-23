// lib/providers/playlist_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class PlaylistProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  PlaylistProvider() {
    loadUserPlaylists();
  }

  // Memuat playlist milik user yang sedang login
  Future<void> loadUserPlaylists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await _supabase
          .from('playlists')
          .select()
          .eq('owner_id', userId);
          
      _playlists = data.map((map) => Playlist.fromMap(map)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading playlists: $e');
    }
  }

  // Membuat playlist baru
  Future<void> createPlaylist(String name) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newPlaylist = Playlist(
      id: '${DateTime.now().millisecondsSinceEpoch}-${user.id}',
      name: name,
      songIds: [],
      ownerId: user.id,
      ownerUsername: user.userMetadata?['username'] ?? 'User',
      isPublic: false, // Default private
    );

    try {
      await _supabase.from('playlists').insert(newPlaylist.toMap());
      _playlists.add(newPlaylist);
      notifyListeners();
    } catch (e) {
      print('Error creating playlist: $e');
    }
  }

  // Menambahkan lagu ke playlist
  Future<void> addSongToPlaylist(Song song, String playlistId) async {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return;

    final playlist = _playlists[playlistIndex];
    if (!playlist.songIds.contains(song.id)) {
      final updatedSongIds = List<String>.from(playlist.songIds)..add(song.id);
      
      try {
        await _supabase
            .from('playlists')
            .update({'song_ids': updatedSongIds})
            .eq('id', playlistId);
        
        _playlists[playlistIndex] = Playlist.fromMap(playlist.toMap()..['song_ids'] = updatedSongIds);
        notifyListeners();
      } catch (e) {
        print('Error adding song to playlist: $e');
      }
    }
  }

  // --- FUNGSI BARU: Menghapus lagu dari playlist ---
  Future<void> removeSongFromPlaylist(String songId, String playlistId) async {
     final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return;

    final playlist = _playlists[playlistIndex];
    final updatedSongIds = List<String>.from(playlist.songIds)..remove(songId);

    try {
      await _supabase
          .from('playlists')
          .update({'song_ids': updatedSongIds})
          .eq('id', playlistId);
      
      _playlists[playlistIndex] = Playlist.fromMap(playlist.toMap()..['song_ids'] = updatedSongIds);
      notifyListeners();
    } catch (e) {
      print('Error removing song from playlist: $e');
    }
  }

  // --- FUNGSI BARU: Mengubah visibilitas playlist ---
  Future<void> setPlaylistVisibility(String playlistId, bool isPublic) async {
    final playlistIndex = _playlists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex == -1) return;

    try {
       await _supabase
          .from('playlists')
          .update({'is_public': isPublic})
          .eq('id', playlistId);
      
      _playlists[playlistIndex] = Playlist.fromMap(_playlists[playlistIndex].toMap()..['is_public'] = isPublic);
      notifyListeners();
    } catch(e) {
       print('Error updating visibility: $e');
    }
  }

  // --- FUNGSI BARU: Menghapus playlist ---
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _supabase.from('playlists').delete().eq('id', playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
    } catch (e) {
      print('Error deleting playlist: $e');
    }
  }

  // --- FUNGSI BARU: Mencari playlist publik ---
  Future<List<Playlist>> searchPublicPlaylists(String query) async {
    if (query.isEmpty) return [];
    try {
      final data = await _supabase
          .from('playlists')
          .select()
          .eq('is_public', true)
          .ilike('name', '%$query%');
      
      return data.map((map) => Playlist.fromMap(map)).toList();
    } catch (e) {
      print('Error searching public playlists: $e');
      return [];
    }
  }
}
