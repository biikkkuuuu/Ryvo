import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';

class AudioService {
  static final AudioService _instance =
  AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal() {
    _listenForCompletion();
  }

  final AudioPlayer player = AudioPlayer();

  static const String baseUrl =
      'https://jiosaavn-api-main-taupe.vercel.app';

  final ValueNotifier<Song?> currentSong =
  ValueNotifier<Song?>(null);

  /// Songs that should play after the current song.
  final ValueNotifier<List<Song>> queue =
  ValueNotifier<List<Song>>(<Song>[]);

  bool _loadingNext = false;
  bool _completionHandled = false;

  // ============================================================
  // BACKGROUND AUTO NEXT
  // ============================================================

  void _listenForCompletion() {
    player.processingStateStream.listen(
          (state) async {
        if (state != ProcessingState.completed) {
          _completionHandled = false;
          return;
        }

        if (_completionHandled) {
          return;
        }

        _completionHandled = true;

        debugPrint(
          'RYVO: CURRENT SONG COMPLETED',
        );

        await _playNextAutomatically();
      },
    );
  }

  Future<void> _playNextAutomatically() async {
    if (_loadingNext) {
      return;
    }

    if (queue.value.isEmpty) {
      debugPrint(
        'RYVO: Queue empty - nothing to play next',
      );
      return;
    }

    await skipToNext();
  }

  // ============================================================
  // PLAY SONG
  // ============================================================

  Future<void> playSong(
      String songId, {
        String title = 'RYVO',
        String artist = 'Unknown Artist',
        String image = '',
        bool clearQueue = false,
      }) async {
    try {
      debugPrint('========== RYVO ==========');
      debugPrint('Song ID: $songId');

      if (clearQueue) {
        clearQueueItems();
      }

      final song = Song(
        id: songId,
        title: title.trim().isEmpty
            ? 'Unknown Song'
            : title,
        artist: artist.trim().isEmpty
            ? 'Unknown Artist'
            : artist,
        thumbnail: image,
      );

      await _playSong(song);
    } catch (e, stackTrace) {
      debugPrint(
        '========== AUDIO ERROR ==========',
      );
      debugPrint('$e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> _playSong(
      Song song,
      ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/songs/${song.id}',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API Error: ${response.statusCode}',
      );
    }

    final json = jsonDecode(
      response.body,
    );

    if (json['success'] != true) {
      throw Exception(
        'API returned success=false',
      );
    }

    final List songs =
        json['data'] ?? [];

    if (songs.isEmpty) {
      throw Exception(
        'Song not found',
      );
    }

    final songData = songs.first;

    final List urls =
        songData['downloadUrl'] ?? [];

    if (urls.isEmpty) {
      throw Exception(
        'Download URL missing',
      );
    }

    String audioUrl = '';

    // Prefer highest available quality.
    for (final item in urls) {
      if (item is Map &&
          item['quality'] == '320kbps') {
        audioUrl =
            item['url']?.toString() ?? '';
        break;
      }
    }

    // Fallback to last available URL.
    if (audioUrl.isEmpty) {
      final last = urls.last;

      if (last is Map) {
        audioUrl =
            last['url']?.toString() ?? '';
      }
    }

    if (audioUrl.isEmpty) {
      throw Exception(
        'Valid audio URL not found',
      );
    }

    currentSong.value = song;

    await LibraryService.instance
        .addRecentlyPlayed(song);

    Uri? artUri;

    if (song.thumbnail.trim().isNotEmpty) {
      final parsed =
      Uri.tryParse(song.thumbnail);

      if (parsed != null &&
          parsed.hasScheme) {
        artUri = parsed;
      }
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: artUri,
    );

    _completionHandled = false;

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl),
        tag: mediaItem,
      ),
    );

    await player.play();

    debugPrint(
      'RYVO: Playing ${song.title}',
    );
  }

  // ============================================================
  // PLAYBACK QUEUE
  // ============================================================

  /// Replaces the queue with songs that should follow
  /// the currently playing song.
  ///
  /// This is used when opening a playlist/search result.
  void setPlaybackQueue(
      List<Song> songs, {
        int currentIndex = 0,
      }) {
    if (songs.isEmpty) {
      queue.value = <Song>[];
      return;
    }

    final safeIndex =
    currentIndex.clamp(
      0,
      songs.length - 1,
    );

    final remaining =
    songs
        .skip(safeIndex + 1)
        .toList();

    queue.value =
    List<Song>.from(remaining);

    debugPrint(
      'RYVO: Playback queue set '
          '(${queue.value.length} songs)',
    );
  }

  void addToQueue(
      Song song,
      ) {
    final updated =
    List<Song>.from(queue.value);

    final exists = updated.any(
          (item) => item.id == song.id,
    );

    if (exists) {
      debugPrint(
        'Already in queue: ${song.title}',
      );
      return;
    }

    updated.add(song);

    queue.value = updated;

    debugPrint(
      'Added to queue: ${song.title}',
    );
  }

  void addToQueueNext(
      Song song,
      ) {
    if (currentSong.value?.id == song.id) {
      return;
    }

    final updated =
    List<Song>.from(queue.value);

    updated.removeWhere(
          (item) => item.id == song.id,
    );

    updated.insert(
      0,
      song,
    );

    queue.value = updated;

    debugPrint(
      'Play next: ${song.title}',
    );
  }

  void removeFromQueue(
      Song song,
      ) {
    final updated =
    List<Song>.from(queue.value);

    updated.removeWhere(
          (item) => item.id == song.id,
    );

    queue.value = updated;
  }

  void clearQueueItems() {
    queue.value =
    <Song>[];
  }

  // ============================================================
  // NEXT SONG
  // ============================================================

  Future<void> skipToNext() async {
    if (_loadingNext) {
      return;
    }

    if (queue.value.isEmpty) {
      debugPrint(
        'RYVO: No next song',
      );
      return;
    }

    _loadingNext = true;

    try {
      final nextSong =
          queue.value.first;

      final remaining =
      List<Song>.from(queue.value);

      remaining.removeAt(0);

      queue.value = remaining;

      debugPrint(
        'RYVO: Auto-next -> ${nextSong.title}',
      );

      await _playSong(nextSong);
    } catch (e, stackTrace) {
      debugPrint(
        'RYVO: Queue playback error: $e',
      );
      debugPrint('$stackTrace');
    } finally {
      _loadingNext = false;
    }
  }

  // ============================================================
  // BASIC CONTROLS
  // ============================================================

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(
      Duration position,
      ) async {
    await player.seek(position);
  }

  // ============================================================
  // STREAMS
  // ============================================================

  Stream<Duration> get positionStream =>
      player.positionStream;

  Stream<Duration?> get durationStream =>
      player.durationStream;

  Stream<PlayerState>
  get playerStateStream =>
      player.playerStateStream;

  Duration get currentPosition =>
      player.position;

  Duration? get totalDuration =>
      player.duration;

  AudioPlayer get audioPlayer =>
      player;

  // ============================================================
  // SHARED PLAYER
  // ============================================================

  /// Do NOT dispose the shared player when
  /// PlayerScreen is closed.
  Future<void> dispose() async {}
}