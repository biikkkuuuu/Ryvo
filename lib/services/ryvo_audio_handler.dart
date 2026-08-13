import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/audio_service.dart' as ryvo;
import 'package:music_app/services/library_service.dart';

class RyvoAudioHandler extends audio_service.BaseAudioHandler {
  RyvoAudioHandler({
    required this.audioService,
  }) {
    _init();
  }

  final ryvo.AudioService audioService;

  // Songs played before the current song.
  // Most recent previous song is at index 0.
  final List<Song> _previousSongs = <Song>[];

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  Song? _lastKnownSong;
  bool _handlingPrevious = false;

  // ============================================================
  // INITIALISE
  // ============================================================

  void _init() {
    _playerStateSubscription =
        audioService.player.playerStateStream.listen((_) {
          _broadcastPlaybackState();
        });

    _durationSubscription =
        audioService.player.durationStream.listen((duration) {
          _updateMediaItemDuration(duration);
          _broadcastPlaybackState();
        });

    _bufferedPositionSubscription =
        audioService.player.bufferedPositionStream.listen((_) {
          _broadcastPlaybackState();
        });

    audioService.currentSong.addListener(
      _onCurrentSongChanged,
    );

    _onCurrentSongChanged();
    _broadcastPlaybackState();
  }

  // ============================================================
  // CURRENT SONG
  // ============================================================

  void _onCurrentSongChanged() {
    final song = audioService.currentSong.value;

    if (song == null) {
      return;
    }

    final previousSong = _lastKnownSong;

    // When moving normally to another song, remember the old
    // song so notification Previous can return to it.
    //
    // During an explicit Previous operation we do NOT add the
    // current song back into history.
    if (previousSong != null &&
        previousSong.id != song.id &&
        !_handlingPrevious) {
      _previousSongs.removeWhere(
            (item) => item.id == previousSong.id,
      );

      _previousSongs.insert(
        0,
        previousSong,
      );

      if (_previousSongs.length > 20) {
        _previousSongs.removeRange(
          20,
          _previousSongs.length,
        );
      }
    }

    _lastKnownSong = song;

    final duration = audioService.player.duration;

    mediaItem.add(
      _toMediaItem(
        song,
        duration: duration,
      ),
    );

    _broadcastPlaybackState();
  }

  audio_service.MediaItem _toMediaItem(
      Song song, {
        Duration? duration,
      }) {
    Uri? artUri;

    final image = song.thumbnail.trim();

    if (image.isNotEmpty) {
      final parsed = Uri.tryParse(image);

      if (parsed != null && parsed.hasScheme) {
        artUri = parsed;
      }
    }

    return audio_service.MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: artUri,
      duration: duration,
    );
  }

  void _updateMediaItemDuration(Duration? duration) {
    final current = mediaItem.value;

    if (current == null) {
      return;
    }

    if (current.duration == duration) {
      return;
    }

    mediaItem.add(
      current.copyWith(
        duration: duration,
      ),
    );
  }

  // ============================================================
  // PLAYBACK STATE
  // ============================================================

  void _broadcastPlaybackState() {
    final playerState = audioService.player.playerState;
    final playing = playerState.playing;

    final controls = <audio_service.MediaControl>[
      audio_service.MediaControl.skipToPrevious,
      playing
          ? audio_service.MediaControl.pause
          : audio_service.MediaControl.play,
      audio_service.MediaControl.skipToNext,
      _likeControl(),
    ];

    playbackState.add(
      audio_service.PlaybackState(
        controls: controls,
        systemActions: const {
          audio_service.MediaAction.seek,
        },
        androidCompactActionIndices: const [
          0,
          1,
          2,
        ],
        processingState: _mapProcessingState(
          playerState.processingState,
        ),
        playing: playing,
        updatePosition: audioService.player.position,
        bufferedPosition:
        audioService.player.bufferedPosition,
        speed: audioService.player.speed,
        updateTime: DateTime.now(),
        queueIndex: 0,
      ),
    );
  }

  audio_service.MediaControl _likeControl() {
    final song = audioService.currentSong.value;

    final liked = song != null &&
        LibraryService.instance.isLiked(song.id);

    return audio_service.MediaControl.custom(
      androidIcon: liked
          ? 'drawable/ic_favorite'
          : 'drawable/ic_favorite_border',
      label: liked ? 'Unlike' : 'Like',
      name: 'toggleLike',
    );
  }

  audio_service.AudioProcessingState _mapProcessingState(
      ProcessingState state,
      ) {
    switch (state) {
      case ProcessingState.idle:
        return audio_service.AudioProcessingState.idle;

      case ProcessingState.loading:
        return audio_service.AudioProcessingState.loading;

      case ProcessingState.buffering:
        return audio_service.AudioProcessingState.buffering;

      case ProcessingState.ready:
        return audio_service.AudioProcessingState.ready;

      case ProcessingState.completed:
        return audio_service.AudioProcessingState.completed;
    }
  }

  // ============================================================
  // PLAY
  // ============================================================

  @override
  Future<void> play() async {
    await audioService.resume();
    _broadcastPlaybackState();
  }

  // ============================================================
  // PAUSE
  // ============================================================

  @override
  Future<void> pause() async {
    await audioService.pause();
    _broadcastPlaybackState();
  }

  // ============================================================
  // STOP
  // ============================================================

  @override
  Future<void> stop() async {
    await audioService.stop();
    _broadcastPlaybackState();
  }

  // ============================================================
  // SEEK
  // ============================================================

  @override
  Future<void> seek(Duration position) async {
    final duration = audioService.player.duration;

    var safePosition = position;

    if (safePosition < Duration.zero) {
      safePosition = Duration.zero;
    }

    if (duration != null && safePosition > duration) {
      safePosition = duration;
    }

    await audioService.seek(safePosition);

    _broadcastPlaybackState();
  }

  // ============================================================
  // NEXT
  // ============================================================

  @override
  Future<void> skipToNext() async {
    await audioService.skipToNext();
    _broadcastPlaybackState();
  }

  // ============================================================
  // PREVIOUS
  // ============================================================

  @override
  Future<void> skipToPrevious() async {
    if (_handlingPrevious) {
      return;
    }

    if (_previousSongs.isEmpty) {
      return;
    }

    _handlingPrevious = true;

    try {
      final previousSong = _previousSongs.removeAt(0);

      final currentSong =
          audioService.currentSong.value;

      if (currentSong != null) {
        final updatedQueue = <Song>[
          currentSong,
          ...audioService.queue.value,
        ];

        audioService.queue.value = updatedQueue;
      }

      await audioService.playSong(
        previousSong.id,
        title: previousSong.title,
        artist: previousSong.artist,
        image: previousSong.thumbnail,
      );
    } finally {
      _handlingPrevious = false;
    }

    _broadcastPlaybackState();
  }

  // ============================================================
  // CUSTOM LIKE ACTION
  // ============================================================

  @override
  Future<dynamic> customAction(
      String name, [
        Map<String, dynamic>? extras,
      ]) async {
    if (name != 'toggleLike') {
      return super.customAction(
        name,
        extras,
      );
    }

    final song = audioService.currentSong.value;

    if (song == null) {
      return false;
    }

    final liked =
    await LibraryService.instance.toggleLike(song);

    // Refresh the notification icon from ♡ to ♥ or vice versa.
    _broadcastPlaybackState();

    return liked;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> disposeHandler() async {
    audioService.currentSong.removeListener(
      _onCurrentSongChanged,
    );

    await _playerStateSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferedPositionSubscription?.cancel();
  }
}