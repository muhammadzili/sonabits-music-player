// lib/models/song.dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String songUrl;
  final String coverArtUrl;
  final String? lyrics;
  final String? localPath;
  final String? localCoverPath; // PERBAIKAN: Path untuk gambar sampul lokal

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.songUrl,
    required this.coverArtUrl,
    this.lyrics,
    this.localPath,
    this.localCoverPath,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      songUrl: map['song_url'] ?? '',
      coverArtUrl: map['cover_art_url'] ?? '',
      lyrics: map['lyrics'],
      localPath: map['localPath'],
      localCoverPath: map['localCoverPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'song_url': songUrl,
      'cover_art_url': coverArtUrl,
      'lyrics': lyrics,
      'localPath': localPath,
      'localCoverPath': localCoverPath,
    };
  }
}
