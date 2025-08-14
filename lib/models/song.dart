// lib/models/song.dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String songUrl;
  final String coverArtUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.songUrl,
    required this.coverArtUrl,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      songUrl: map['song_url'] ?? '',
      coverArtUrl: map['cover_art_url'] ?? '',
    );
  }
}
