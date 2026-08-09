import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/models/song.dart';

class LibraryService {
  LibraryService._internal();

  static final LibraryService instance = LibraryService._internal();

  SharedPreferences? _prefs;

  static const String _likedKey = 'ryvo_liked_songs';
  static const String _recentKey = 'ryvo_recently_played';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Map<String, dynamic> _songToMap(Song song) => {
    'id': song.id,
    'title': song.title,
    'artist': song.artist,
    'thumbnail': song.thumbnail,
  };

  Song _mapToSong(Map<String, dynamic> map) => Song(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    artist: map['artist']?.toString() ?? '',
    thumbnail: map['thumbnail']?.toString() ?? '',
  );

  List<Song> _readSongs(String key) {
    final raw = _prefs?.getStringList(key) ?? [];
    final songs = <Song>[];

    for (final item in raw) {
      try {
        final value = jsonDecode(item);
        if (value is Map<String, dynamic>) {
          final song = _mapToSong(value);
          if (song.id.isNotEmpty) songs.add(song);
        }
      } catch (_) {}
    }

    return songs;
  }

  Future<void> _saveSongs(String key, List<Song> songs) async {
    await init();

    await _prefs!.setStringList(
      key,
      songs.map((song) => jsonEncode(_songToMap(song))).toList(),
    );
  }

  Future<void> addRecentlyPlayed(Song song) async {
    if (song.id.isEmpty) return;

    await init();

    final songs = _readSongs(_recentKey);
    songs.removeWhere((item) => item.id == song.id);
    songs.insert(0, song);

    if (songs.length > 20) {
      songs.removeRange(20, songs.length);
    }

    await _saveSongs(_recentKey, songs);
  }

  Future<List<Song>> getRecentlyPlayed() async {
    await init();
    return _readSongs(_recentKey);
  }

  Future<void> clearRecentlyPlayed() async {
    await init();
    await _prefs!.remove(_recentKey);
  }

  bool isLiked(String songId) {
    if (songId.isEmpty) return false;
    return _readSongs(_likedKey).any((song) => song.id == songId);
  }

  Future<List<Song>> getLikedSongs() async {
    await init();
    return _readSongs(_likedKey);
  }

  Future<bool> toggleLike(Song song) async {
    if (song.id.isEmpty) return false;

    await init();

    final songs = _readSongs(_likedKey);
    final index = songs.indexWhere((item) => item.id == song.id);

    if (index != -1) {
      songs.removeAt(index);
      await _saveSongs(_likedKey, songs);
      return false;
    }

    songs.insert(0, song);
    await _saveSongs(_likedKey, songs);
    return true;
  }

  Future<void> removeLiked(String songId) async {
    await init();

    final songs = _readSongs(_likedKey)
      ..removeWhere((song) => song.id == songId);

    await _saveSongs(_likedKey, songs);
  }

  Future<void> clearLikedSongs() async {
    await init();
    await _prefs!.remove(_likedKey);
  }
}
