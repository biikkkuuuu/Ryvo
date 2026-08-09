import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer player = AudioPlayer();

  static const String baseUrl = 'https://jiosaavn-api-main-taupe.vercel.app';

  final ValueNotifier<Song?> currentSong =
  ValueNotifier<Song?>(null);

  // Queue of songs waiting to play.
  final ValueNotifier<List<Song>> queue =
  ValueNotifier<List<Song>>(<Song>[]);

  bool _loadingNext = false;

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
      debugPrint('========== AUDIO ERROR ==========');
      debugPrint('$e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> _playSong(Song song) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/songs/${song.id}'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API Error: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        'API returned success=false',
      );
    }

    final List songs = json['data'] ?? [];

    if (songs.isEmpty) {
      throw Exception('Song not found');
    }

    final songData = songs.first;
    final List urls = songData['downloadUrl'] ?? [];

    if (urls.isEmpty) {
      throw Exception('Download URL missing');
    }

    String audioUrl = '';

    for (final item in urls) {
      if (item['quality'] == '320kbps') {
        audioUrl = item['url'] ?? '';
        break;
      }
    }

    if (audioUrl.isEmpty) {
      audioUrl = urls.last['url'] ?? '';
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
      final parsed = Uri.tryParse(
        song.thumbnail,
      );

      if (parsed != null && parsed.hasScheme) {
        artUri = parsed;
      }
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: artUri,
    );

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl),
        tag: mediaItem,
      ),
    );

    await player.play();

    debugPrint(
      'Playing: ${song.title}',
    );
  }

  // ============================================================
  // QUEUE
  // ============================================================

  void addToQueue(Song song) {
    final updated = List<Song>.from(
      queue.value,
    );

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

  void addToQueueNext(Song song) {
    if (currentSong.value?.id == song.id) {
      return;
    }

    final updated = List<Song>.from(
      queue.value,
    );

    updated.removeWhere(
          (item) => item.id == song.id,
    );

    updated.insert(0, song);

    queue.value = updated;

    debugPrint(
      'Play next: ${song.title}',
    );
  }

  void removeFromQueue(Song song) {
    final updated = List<Song>.from(
      queue.value,
    );

    updated.removeWhere(
          (item) => item.id == song.id,
    );

    queue.value = updated;
  }

  void clearQueueItems() {
    queue.value = <Song>[];
  }

  Future<void> skipToNext() async {
    if (_loadingNext) return;

    if (queue.value.isEmpty) {
      return;
    }

    _loadingNext = true;

    try {
      final nextSong = queue.value.first;

      final remaining = List<Song>.from(
        queue.value,
      );

      remaining.removeAt(0);
      queue.value = remaining;

      await _playSong(nextSong);
    } catch (e, stackTrace) {
      debugPrint(
        'Queue playback error: $e',
      );
      debugPrint('$stackTrace');
    } finally {
      _loadingNext = false;
    }
  }

  // ============================================================
  // BASIC CONTROLS
  // ============================================================

  Future<void> pause() => player.pause();

  Future<void> resume() => player.play();

  Future<void> stop() => player.stop();

  Stream<Duration> get positionStream =>
      player.positionStream;

  Stream<Duration?> get durationStream =>
      player.durationStream;

  Stream<PlayerState> get playerStateStream =>
      player.playerStateStream;

  Duration get currentPosition =>
      player.position;

  Duration? get totalDuration =>
      player.duration;

  Future<void> seek(
      Duration position,
      ) =>
      player.seek(position);

  AudioPlayer get audioPlayer => player;

  // Shared player must remain alive.
  Future<void> dispose() async {}
}
