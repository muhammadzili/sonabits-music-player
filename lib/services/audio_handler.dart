// lib/services/audio_handler.dart
import 'package:audio_service/audio_service.dart'; // <-- PERBAIKAN: Path import yang benar
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _updateMediaItemDuration(duration);
      }
    });

    _loadEmptyPlaylist();
  }

  void _updateMediaItemDuration(Duration duration) {
    final index = _player.currentIndex;
    if (index == null || index >= queue.value.length) return;
    
    final mediaItem = queue.value[index];
    if (mediaItem.duration != duration) {
      final updatedMediaItem = mediaItem.copyWith(duration: duration);
      queue.value[index] = updatedMediaItem;
      this.mediaItem.add(updatedMediaItem);
      queue.add(queue.value);
    }
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    await _playlist.clear();
    await _playlist.addAll(newQueue.map(_createAudioSource).toList());
    queue.add(newQueue);
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    if (mediaItem.extras?['isLocal'] == true) {
      return AudioSource.uri(Uri.file(mediaItem.id));
    } else {
      return AudioSource.uri(Uri.parse(mediaItem.id));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    play();
  }
  
  @override
  Future<void> stop() async {
    await _player.stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Tambahkan ini:
  Stream<Duration> get positionStream => _player.positionStream;
}

MediaItem songToMediaItem(Song song) {
  return MediaItem(
    id: song.localPath ?? song.songUrl,
    album: song.artist,
    title: song.title,
    artist: song.artist,
    artUri: Uri.parse(song.coverArtUrl),
    extras: {
      'isLocal': song.localPath != null,
      'originalId': song.id,
    },
  );
}
