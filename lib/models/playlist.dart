// lib/models/playlist.dart
class Playlist {
  final String id;
  final String name;
  final List<String> songIds;
  // --- PENAMBAHAN FIELD BARU ---
  final String ownerId;
  final String ownerUsername;
  final bool isPublic; // true for public, false for private

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.ownerId,
    required this.ownerUsername,
    this.isPublic = false, // Default ke private
  });

  // Method untuk mengubah ke Map (untuk Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'song_ids': songIds,
      'owner_id': ownerId,
      'owner_username': ownerUsername,
      'is_public': isPublic,
    };
  }

  // Factory constructor untuk membuat dari Map (dari Supabase)
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      name: map['name'],
      // Supabase mengembalikan List<dynamic>, perlu di-cast
      songIds: List<String>.from(map['song_ids'] ?? []),
      ownerId: map['owner_id'],
      ownerUsername: map['owner_username'],
      isPublic: map['is_public'] ?? false,
    );
  }
}
