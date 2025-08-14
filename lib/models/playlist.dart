// lib/models/playlist.dart
class Playlist {
  final String id;
  final String name;
  final List<String> songIds; // Simpan ID lagu saja

  Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      songIds: List<String>.from(json['songIds']),
    );
  }
}
