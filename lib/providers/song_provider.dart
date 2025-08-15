// lib/providers/song_provider.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Song> _playlist = [];
  int _currentIndex = -1;
  
  bool _isPlaying = false;
  bool _isPlayerMinimized = true;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  Song? get currentSong => _currentIndex != -1 && _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  bool get isPlaying => _isPlaying;
  bool get isPlayerMinimized => _isPlayerMinimized;
  Duration get totalDuration => _totalDuration;
  Duration get currentPosition => _currentPosition;

  SongProvider() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentPosition = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      playNext();
    });
  }

  Future<void> playSong(List<Song> newPlaylist, int startIndex) async {
    _playlist = newPlaylist;
    _currentIndex = startIndex;
    _isPlayerMinimized = true; 
    await _playCurrentSong();
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await _playCurrentSong();
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await _playCurrentSong();
  }

  Future<void> _playCurrentSong() async {
    if (currentSong == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isCrossfadeOn = prefs.getBool('crossfade') ?? true;
    final double durationInSeconds = prefs.getDouble('crossfadeDuration') ?? 6.0;
    final fadeDuration = Duration(milliseconds: (durationInSeconds * 250).clamp(250, 1500).toInt());

    if (isCrossfadeOn && _isPlaying) {
      await _audioPlayer.setVolume(0.1);
      await Future.delayed(fadeDuration);
    }
    
    await _audioPlayer.stop();

    // PERBAIKAN: Cek apakah lagu punya path lokal
    if (currentSong!.localPath != null && currentSong!.localPath!.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(currentSong!.localPath!));
    } else {
      await _audioPlayer.play(UrlSource(currentSong!.songUrl));
    }
    
    await _audioPlayer.setVolume(1.0);
    
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (currentSong != null) {
        await _audioPlayer.resume();
      }
    }
    notifyListeners();
  }

  Future<void> stopSong() async {
    await _audioPlayer.stop();
    _currentIndex = -1;
    _playlist = [];
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }
  
  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void minimizePlayer() {
    _isPlayerMinimized = true;
    notifyListeners();
  }

  void maximizePlayer() {
    _isPlayerMinimized = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
