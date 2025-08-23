// lib/providers/song_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';

class SongProvider with ChangeNotifier {
  final AudioHandler _audioHandler;

  // HAPUS: Timer untuk update UI
  // Timer? _progressTimer;
  StreamSubscription<Duration>? _positionSubscription;

  List<Song> _playlist = [];
  Song? _currentSong;
  bool _isPlayerMinimized = true;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  Song? get currentSong => _currentSong;
  bool get isPlayerMinimized => _isPlayerMinimized;
  Duration get totalDuration => _totalDuration;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;

  SongProvider(this._audioHandler) {
    _listenToPlaybackState();
    _listenToCurrentSong();
    _listenToPosition();
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final mediaItem = _audioHandler.mediaItem.value;
      _isPlaying = playbackState.playing;
      
      if (mediaItem?.duration != null && mediaItem!.duration! > Duration.zero) {
        _totalDuration = mediaItem.duration!;
      }

      // HAPUS: Timer logic
      // if (_isPlaying) {
      //   _startProgressTimer();
      // } else {
      //   _stopProgressTimer();
      //   _currentPosition = playbackState.updatePosition;
      // }

      notifyListeners();
    });
  }

  // HAPUS:
  // void _startProgressTimer() { ... }
  // void _stopProgressTimer() { ... }

  void _listenToCurrentSong() {
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem == null) {
        _currentSong = null;
        // HAPUS: _stopProgressTimer();
      } else {
        final originalId = mediaItem.extras?['originalId'];
        try {
          _currentSong = _playlist.firstWhere((s) => s.id == originalId);
          _totalDuration = mediaItem.duration ?? Duration.zero;
        } catch (e) {
          _currentSong = null;
        }
      }
      notifyListeners();
    });
  }

  void _listenToPosition() {
    _positionSubscription = (_audioHandler as dynamic).positionStream.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });
  }

  Future<void> playSong(List<Song> newPlaylist, int startIndex) async {
    _playlist = newPlaylist;
    _isPlayerMinimized = true;
    _currentPosition = Duration.zero;
    
    if (startIndex >= 0 && startIndex < newPlaylist.length) {
      _currentSong = newPlaylist[startIndex];
    }

    notifyListeners();

    final mediaItems = _playlist.map(songToMediaItem).toList();
    await _audioHandler.updateQueue(mediaItems);
    await _audioHandler.skipToQueueItem(startIndex);
    await _audioHandler.play();
  }

  Future<void> stopSong() async {
    await _audioHandler.stop();
    // HAPUS: _stopProgressTimer();
    
    _playlist = [];
    _currentSong = null;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isPlaying = false;
    
    notifyListeners();
  }

  @override
  void dispose() {
    // HAPUS: _stopProgressTimer();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> playNext() => _audioHandler.skipToNext();
  Future<void> playPrevious() => _audioHandler.skipToPrevious();
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }
  
  void seek(Duration position) {
    // Update posisi secara optimis untuk UI yang responsif
    _currentPosition = position;
    notifyListeners();
    _audioHandler.seek(position);
  }

  void minimizePlayer() {
    _isPlayerMinimized = true;
    notifyListeners();
  }

  void maximizePlayer() {
    _isPlayerMinimized = false;
    notifyListeners();
  }
}
