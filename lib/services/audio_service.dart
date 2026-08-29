import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/library_service.dart';
import 'package:music_app/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  AudioService._internal() {
    _listenForCompletion();
    _listenForPositionToSave();
    _restoreLastSong();
  }

  final AudioPlayer player = AudioPlayer();

  static const String baseUrl =
      'https://jiosaavn-api-main-taupe.vercel.app';

  static const String _lastSongKey = 'ryvo_last_played_song';

  final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);

  final ValueNotifier<List<Song>> queue =
      ValueNotifier<List<Song>>(<Song>[]);
      
  final ValueNotifier<List<Song>> history =
      ValueNotifier<List<Song>>(<Song>[]);

  bool _loadingNext = false;
  bool _completionHandled = false;
  bool _restoringLastSong = false;
  DateTime? _lastSaveTime;

  // ============================================================
  // PERSISTENCE (SONG + QUEUE)
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

      debugPrint('RYVO: Last song saved -> ${song.title}');
    } catch (e) {
      debugPrint('RYVO: Failed to save last song -> $e');
    }
  }
  
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qData = queue.value.map((s) => jsonEncode({'id': s.id, 'title': s.title, 'artist': s.artist, 'thumbnail': s.thumbnail})).toList();
      final hData = history.value.map((s) => jsonEncode({'id': s.id, 'title': s.title, 'artist': s.artist, 'thumbnail': s.thumbnail})).toList();
      await prefs.setStringList('ryvo_queue', qData);
      await prefs.setStringList('ryvo_history', hData);
    } catch(e) {
       debugPrint('RYVO: Failed to save queue -> $e');
    }
  }

  void _listenForPositionToSave() {
    player.positionStream.listen((position) async {
      if (currentSong.value == null) return;

      final now = DateTime.now();
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
    if (_restoringLastSong) return;

    _restoringLastSong = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore Queue and History
      final qList = prefs.getStringList('ryvo_queue') ?? [];
      final hList = prefs.getStringList('ryvo_history') ?? [];
      
      Song mapToSong(String jsonStr) {
        final m = jsonDecode(jsonStr);
        return Song(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? 'Unknown',
          artist: m['artist']?.toString() ?? 'Unknown',
          thumbnail: m['thumbnail']?.toString() ?? '',
        );
      }
      
      queue.value = qList.map(mapToSong).where((s) => s.id.isNotEmpty).toList();
      history.value = hList.map(mapToSong).where((s) => s.id.isNotEmpty).toList();

      final saved = prefs.getString(_lastSongKey);
      if (saved == null || saved.trim().isEmpty) return;

      final data = jsonDecode(saved);
      if (data is! Map) return;

      final id = data['id']?.toString().trim() ?? '';
      if (id.isEmpty) return;

      final song = Song(
        id: id,
        title: data['title']?.toString() ?? 'Unknown Song',
        artist: data['artist']?.toString() ?? 'Unknown Artist',
        thumbnail: data['thumbnail']?.toString() ?? '',
      );

      currentSong.value = song;
      
      final savedPos = prefs.getInt('ryvo_last_position') ?? 0;
      final wasPlaying = prefs.getBool('ryvo_was_playing') ?? false;

      debugPrint('RYVO: Restored last song UI -> ${song.title} | Queue: ${queue.value.length}');

      String audioUrl = '';
      bool isOffline = false;

      // OFFLINE RESTORE CHECK
      final localPath = DownloadService.instance.getLocalPath(song.id);
      if (localPath != null && File(localPath).existsSync()) {
        audioUrl = localPath;
        isOffline = true;
      } else {
        final response = await http.get(Uri.parse('$baseUrl/api/songs/${song.id}'));
        if (response.statusCode != 200) return;
        final json = jsonDecode(response.body);
        if (json['success'] != true) return;
        final List songs = json['data'] ?? [];
        if (songs.isEmpty) return;
        final songData = songs.first;
        final List urls = songData['downloadUrl'] ?? [];
        if (urls.isEmpty) return;

        for (final item in urls) {
          if (item is Map && item['quality'] == '320kbps') {
            audioUrl = item['url']?.toString() ?? '';
            break;
          }
        }
        if (audioUrl.isEmpty) {
          final last = urls.last;
          if (last is Map) audioUrl = last['url']?.toString() ?? '';
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

      await player.setAudioSource(
        isOffline 
            ? AudioSource.uri(Uri.file(audioUrl), tag: mediaItem)
            : AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem),
        initialPosition: Duration(milliseconds: savedPos),
      );

      debugPrint('RYVO: Fully restored audio source at ${savedPos}ms. Kept paused.');
    } catch (e) {
      debugPrint('RYVO: Failed to fully restore last song audio -> $e');
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
      await prefs.remove('ryvo_queue');
      await prefs.remove('ryvo_history');

      currentSong.value = null;
      queue.value = [];
      history.value = [];

      debugPrint('RYVO: Last song & queue cleared');
    } catch (e) {
      debugPrint('RYVO: Failed to clear last song -> $e');
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

        if (_completionHandled) return;

        _completionHandled = true;

        debugPrint('RYVO: CURRENT SONG COMPLETED');

        await _playNextAutomatically();
      },
    );
  }

  Future<void> _playNextAutomatically() async {
    if (_loadingNext) return;

    if (queue.value.isEmpty) {
      debugPrint('RYVO: Queue empty - nothing to play next');
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
      debugPrint('========== AUDIO ERROR ==========');
      debugPrint('$e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> _playSong(Song song) async {
    String audioUrl = '';
    bool isOffline = false;

    // OFFLINE CHECK INTERCEPTOR
    final localPath = DownloadService.instance.getLocalPath(song.id);
    if (localPath != null && File(localPath).existsSync()) {
      audioUrl = localPath;
      isOffline = true;
      debugPrint('RYVO: Playing OFFLINE FILE -> ${song.title}');
    } else {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs/${song.id}'),
      );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);

      if (json['success'] != true) {
        throw Exception('API returned success=false');
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

      if (audioUrl.isEmpty) {
        throw Exception('Valid audio URL not found');
      }
      debugPrint('RYVO: Playing ONLINE STREAM -> ${song.title}');
    }

    currentSong.value = song;

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
      isOffline 
          ? AudioSource.uri(Uri.file(audioUrl), tag: mediaItem)
          : AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem),
    );

    await player.play();
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
      history.value = <Song>[];
      _saveQueue();
      return;
    }

    final safeIndex = currentIndex.clamp(0, songs.length - 1);
    
    history.value = songs.take(safeIndex).toList();
    queue.value = songs.skip(safeIndex + 1).toList();
    _saveQueue();

    debugPrint('RYVO: Playback queue set (${queue.value.length} up next)');
  }

  void addToQueue(Song song) {
    final updated = List<Song>.from(queue.value);

    final exists = updated.any((item) => item.id == song.id);

    if (exists) {
      debugPrint('Already in queue: ${song.title}');
      return;
    }

    updated.add(song);
    queue.value = updated;
    _saveQueue();
    debugPrint('Added to queue: ${song.title}');
  }

  void addToQueueNext(Song song) {
    if (currentSong.value?.id == song.id) return;

    final updated = List<Song>.from(queue.value);
    updated.removeWhere((item) => item.id == song.id);
    updated.insert(0, song);

    queue.value = updated;
    _saveQueue();
    debugPrint('Play next: ${song.title}');
  }

  void removeFromQueue(Song song) {
    final updated = List<Song>.from(queue.value);
    updated.removeWhere((item) => item.id == song.id);
    queue.value = updated;
    _saveQueue();
  }

  void clearQueueItems() {
    queue.value = <Song>[];
    history.value = <Song>[];
    _saveQueue();
  }

  // ============================================================
  // NEXT & PREVIOUS
  // ============================================================

  Future<void> skipToNext() async {
    if (_loadingNext) return;

    if (queue.value.isEmpty) {
      debugPrint('RYVO: No next song');
      return;
    }

    _loadingNext = true;

    try {
      final nextSong = queue.value.first;
      final remaining = List<Song>.from(queue.value)..removeAt(0);
      
      if (currentSong.value != null) {
        final newHistory = List<Song>.from(history.value)..add(currentSong.value!);
        history.value = newHistory;
      }

      queue.value = remaining;
      _saveQueue();

      debugPrint('RYVO: Auto-next -> ${nextSong.title}');

      await _playSong(nextSong);
    } catch (e, stackTrace) {
      debugPrint('RYVO: Queue playback error: $e');
      debugPrint('$stackTrace');
    } finally {
      _loadingNext = false;
    }
  }
  
  Future<void> skipToPrevious() async {
    if (history.value.isEmpty) {
      await player.seek(Duration.zero);
      return;
    }
    
    _loadingNext = true;
    try {
      final prevSong = history.value.last;
      final newHistory = List<Song>.from(history.value)..removeLast();
      
      if (currentSong.value != null) {
        final newQueue = List<Song>.from(queue.value);
        newQueue.insert(0, currentSong.value!);
        queue.value = newQueue;
      }
      
      history.value = newHistory;
      _saveQueue();
      
      debugPrint('RYVO: Auto-prev -> ${prevSong.title}');
      await _playSong(prevSong);
    } catch (e) {
      debugPrint('RYVO: Queue prev error: $e');
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
    if (player.audioSource == null && currentSong.value != null) {
      await _playSong(currentSong.value!);
      return;
    }
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

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Duration get currentPosition => player.position;
  Duration? get totalDuration => player.duration;
  AudioPlayer get audioPlayer => player;

  Future<void> dispose() async {}
}