import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal() {
    _listenForCompletion();
    _listenForPositionToSave(); // Added position listener
    _restoreLastSong();
  }

  final AudioPlayer player = AudioPlayer();

  static const String baseUrl =
      'https://jiosaavn-api-main-taupe.vercel.app';

  static const String _lastSongKey = 'ryvo_last_played_song';

  final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);

  /// Songs that should play after the current song.
  final ValueNotifier<List<Song>> queue =
      ValueNotifier<List<Song>>(<Song>[]);

  bool _loadingNext = false;
  bool _completionHandled = false;
  bool _restoringLastSong = false;
  DateTime? _lastSaveTime;

  // ============================================================
  // LAST PLAYED SONG PERSISTENCE
  // ============================================================

  Future<void> _saveLastSong(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _lastSongKey,
        jsonEncode({
          'id': song.id,
          'title': song.title,
          'artist': song.artist,
          'thumbnail': song.thumbnail,
        }),
      );

      debugPrint(
        'RYVO: Last song saved -> ${song.title}',
      );
    } catch (e) {
      debugPrint(
        'RYVO: Failed to save last song -> $e',
      );
    }
  }

  // Throttled position saving to prevent excessive SharedPreferences writes
  void _listenForPositionToSave() {
    player.positionStream.listen((position) async {
      if (currentSong.value == null) return;

      final now = DateTime.now();
      // Throttle writes to every 5 seconds
      if (_lastSaveTime == null || now.difference(_lastSaveTime!).inSeconds >= 5) {
        _lastSaveTime = now;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('ryvo_last_position', position.inMilliseconds);
          await prefs.setBool('ryvo_was_playing', player.playing);
        } catch (e) {
          debugPrint('RYVO: Failed to save position -> $e');
        }
      }
    });
  }

  Future<void> _restoreLastSong() async {
    if (_restoringLastSong) {
      return;
    }

    _restoringLastSong = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = prefs.getString(_lastSongKey);
      if (saved == null || saved.trim().isEmpty) {
        return;
      }

      final data = jsonDecode(saved);
      if (data is! Map) {
        return;
      }

      final id = data['id']?.toString().trim() ?? '';
      if (id.isEmpty) {
        return;
      }

      final song = Song(
        id: id,
        title: data['title']?.toString() ?? 'Unknown Song',
        artist: data['artist']?.toString() ?? 'Unknown Artist',
        thumbnail: data['thumbnail']?.toString() ?? '',
      );

      // Instantly assign to make the Mini Player visible on startup
      currentSong.value = song;
      
      final savedPos = prefs.getInt('ryvo_last_position') ?? 0;
      final wasPlaying = prefs.getBool('ryvo_was_playing') ?? false;

      debugPrint('RYVO: Restored last song UI -> ${song.title}');

      // Silently re-resolve the audio URL in the background
      final response = await http.get(Uri.parse('$baseUrl/api/songs/${song.id}'));

      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body);
      if (json['success'] != true) return;

      final List songs = json['data'] ?? [];
      if (songs.isEmpty) return;

      final songData = songs.first;
      final List urls = songData['downloadUrl'] ?? [];
      if (urls.isEmpty) return;

      String audioUrl = '';

      for (final item in urls) {
        if (item is Map && item['quality'] == '320kbps') {
          audioUrl = item['url']?.toString() ?? '';
          break;
        }
      }

      if (audioUrl.isEmpty) {
        final last = urls.last;
        if (last is Map) {
          audioUrl = last['url']?.toString() ?? '';
        }
      }

      if (audioUrl.isEmpty) return;

      Uri? artUri;
      if (song.thumbnail.trim().isNotEmpty) {
        final parsed = Uri.tryParse(song.thumbnail);
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

      // Restore the AudioSource and seek to position, but explicitly DO NOT PLAY.
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          tag: mediaItem,
        ),
        initialPosition: Duration(milliseconds: savedPos),
      );

      debugPrint(
        'RYVO: Fully restored audio source at ${savedPos}ms (Was playing: $wasPlaying). Kept paused.',
      );
    } catch (e) {
      debugPrint(
        'RYVO: Failed to fully restore last song audio -> $e',
      );
    } finally {
      _restoringLastSong = false;
    }
  }

  Future<void> clearLastSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_lastSongKey);
      await prefs.remove('ryvo_last_position');
      await prefs.remove('ryvo_was_playing');

      currentSong.value = null;

      debugPrint(
        'RYVO: Last song cleared',
      );
    } catch (e) {
      debugPrint(
        'RYVO: Failed to clear last song -> $e',
      );
    }
  }

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
        title: title.trim().isEmpty ? 'Unknown Song' : title,
        artist: artist.trim().isEmpty ? 'Unknown Artist' : artist,
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

  Future<void> _playSong(Song song) async {
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

    final json = jsonDecode(response.body);

    if (json['success'] != true) {
      throw Exception(
        'API returned success=false',
      );
    }

    final List songs = json['data'] ?? [];

    if (songs.isEmpty) {
      throw Exception(
        'Song not found',
      );
    }

    final songData = songs.first;

    final List urls = songData['downloadUrl'] ?? [];

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
        audioUrl = item['url']?.toString() ?? '';
        break;
      }
    }

    // Fallback to last available URL.
    if (audioUrl.isEmpty) {
      final last = urls.last;

      if (last is Map) {
        audioUrl = last['url']?.toString() ?? '';
      }
    }

    if (audioUrl.isEmpty) {
      throw Exception(
        'Valid audio URL not found',
      );
    }

    // Update current song immediately.
    currentSong.value = song;

    // IMPORTANT:
    // Save the song so the mini-player can restore it
    // after the app is completely closed and reopened.
    await _saveLastSong(song);

    await LibraryService.instance.addRecentlyPlayed(song);

    Uri? artUri;

    if (song.thumbnail.trim().isNotEmpty) {
      final parsed = Uri.tryParse(song.thumbnail);

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

  void setPlaybackQueue(
    List<Song> songs, {
    int currentIndex = 0,
  }) {
    if (songs.isEmpty) {
      queue.value = <Song>[];
      return;
    }

    final safeIndex = currentIndex.clamp(
      0,
      songs.length - 1,
    );

    final remaining = songs
        .skip(safeIndex + 1)
        .toList();

    queue.value = List<Song>.from(remaining);

    debugPrint(
      'RYVO: Playback queue set '
      '(${queue.value.length} songs)',
    );
  }

  void addToQueue(Song song) {
    final updated = List<Song>.from(queue.value);

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

    final updated = List<Song>.from(queue.value);

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

  void removeFromQueue(Song song) {
    final updated = List<Song>.from(queue.value);

    updated.removeWhere(
      (item) => item.id == song.id,
    );

    queue.value = updated;
  }

  void clearQueueItems() {
    queue.value = <Song>[];
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
      final nextSong = queue.value.first;

      final remaining = List<Song>.from(queue.value);

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
    // If the app was reopened but the URL fetch failed or hasn't finished,
    // audioSource will be null. Fall back to reloading the song entirely.
    if (player.audioSource == null &&
        currentSong.value != null) {
      await _playSong(currentSong.value!);
      return;
    }

    // Because _restoreLastSong set the initialPosition successfully,
    // this will perfectly resume from where the user left off.
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  // ============================================================
  // STREAMS
  // ============================================================

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

  AudioPlayer get audioPlayer =>
      player;

  // ============================================================
  // SHARED PLAYER
  // ============================================================

  /// Do NOT dispose the shared player when
  /// PlayerScreen is closed.
  Future<void> dispose() async {}
}