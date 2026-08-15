import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/models/song.dart';

class LibraryService {
  LibraryService._internal();

  static final LibraryService instance = LibraryService._internal();

  SharedPreferences? _prefs;

  static const String _likedKey = 'ryvo_liked_songs';
  static const String _recentKey = 'ryvo_recently_played';

  // ============================================================
  // PLAYLIST STORAGE
  // ============================================================

  static const String _playlistNamesKey = 'ryvo_playlist_names';
  static const String _playlistPrefix = 'ryvo_playlist_';

  // ============================================================
  // INITIALISE
  // ============================================================

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============================================================
  // SONG SERIALIZATION
  // ============================================================

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

  // ============================================================
  // READ SONGS
  // ============================================================

  List<Song> _readSongs(String key) {
    final raw = _prefs?.getStringList(key) ?? [];
    final songs = <Song>[];

    for (final item in raw) {
      try {
        final value = jsonDecode(item);

        if (value is Map<String, dynamic>) {
          final song = _mapToSong(value);

          if (song.id.isNotEmpty) {
            songs.add(song);
          }
        }
      } catch (_) {}
    }

    return songs;
  }

  // ============================================================
  // SAVE SONGS
  // ============================================================

  Future<void> _saveSongs(
      String key,
      List<Song> songs,
      ) async {
    await init();

    await _prefs!.setStringList(
      key,
      songs
          .map(
            (song) => jsonEncode(
          _songToMap(song),
        ),
      )
          .toList(),
    );
  }

  // ============================================================
  // RECENTLY PLAYED
  // ============================================================

  Future<void> addRecentlyPlayed(
      Song song,
      ) async {
    if (song.id.isEmpty) {
      return;
    }

    await init();

    final songs = _readSongs(_recentKey);

    songs.removeWhere(
          (item) => item.id == song.id,
    );

    songs.insert(
      0,
      song,
    );

    if (songs.length > 20) {
      songs.removeRange(
        20,
        songs.length,
      );
    }

    await _saveSongs(
      _recentKey,
      songs,
    );
  }

  Future<List<Song>> getRecentlyPlayed() async {
    await init();

    return _readSongs(
      _recentKey,
    );
  }

  Future<void> clearRecentlyPlayed() async {
    await init();

    await _prefs!.remove(
      _recentKey,
    );
  }

  // ============================================================
  // LIKED SONGS
  // ============================================================

  bool isLiked(
      String songId,
      ) {
    if (songId.isEmpty) {
      return false;
    }

    return _readSongs(
      _likedKey,
    ).any(
          (song) => song.id == songId,
    );
  }

  Future<List<Song>> getLikedSongs() async {
    await init();

    return _readSongs(
      _likedKey,
    );
  }

  Future<bool> toggleLike(
      Song song,
      ) async {
    if (song.id.isEmpty) {
      return false;
    }

    await init();

    final songs = _readSongs(
      _likedKey,
    );

    final index = songs.indexWhere(
          (item) => item.id == song.id,
    );

    if (index != -1) {
      songs.removeAt(index);

      await _saveSongs(
        _likedKey,
        songs,
      );

      return false;
    }

    songs.insert(
      0,
      song,
    );

    await _saveSongs(
      _likedKey,
      songs,
    );

    return true;
  }

  Future<void> removeLiked(
      String songId,
      ) async {
    await init();

    final songs = _readSongs(
      _likedKey,
    )..removeWhere(
          (song) => song.id == songId,
    );

    await _saveSongs(
      _likedKey,
      songs,
    );
  }

  Future<void> clearLikedSongs() async {
    await init();

    await _prefs!.remove(
      _likedKey,
    );
  }

  // ============================================================
  // PLAYLIST HELPERS
  // ============================================================

  String _playlistKey(
      String name,
      ) {
    return '$_playlistPrefix${name.trim()}';
  }

  // ============================================================
  // GET PLAYLIST NAMES
  // ============================================================

  Future<List<String>> getPlaylistNames() async {
    await init();

    final names =
        _prefs!.getStringList(
          _playlistNamesKey,
        ) ??
            <String>[];

    return List<String>.from(
      names,
    );
  }

  // ============================================================
  // CREATE PLAYLIST
  // ============================================================

  Future<bool> createPlaylist(
      String name,
      ) async {
    await init();

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final exists = names.any(
          (item) =>
      item.toLowerCase() ==
          cleanName.toLowerCase(),
    );

    if (exists) {
      return false;
    }

    names.add(
      cleanName,
    );

    await _prefs!.setStringList(
      _playlistNamesKey,
      names,
    );

    await _prefs!.setStringList(
      _playlistKey(cleanName),
      <String>[],
    );

    return true;
  }

  // ============================================================
  // GET PLAYLIST
  // ============================================================

  Future<List<Song>> getPlaylist(
      String name,
      ) async {
    await init();

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return <Song>[];
    }

    return _readSongs(
      _playlistKey(cleanName),
    );
  }

  // ============================================================
  // DELETE PLAYLIST
  // ============================================================

  Future<bool> deletePlaylist(
      String name,
      ) async {
    await init();

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final index = names.indexWhere(
          (item) =>
      item.toLowerCase() ==
          cleanName.toLowerCase(),
    );

    if (index == -1) {
      return false;
    }

    final actualName = names[index];

    names.removeAt(
      index,
    );

    await _prefs!.setStringList(
      _playlistNamesKey,
      names,
    );

    await _prefs!.remove(
      _playlistKey(actualName),
    );

    return true;
  }

  // ============================================================
  // RENAME PLAYLIST
  // ============================================================

  Future<bool> renamePlaylist(
      String oldName,
      String newName,
      ) async {
    await init();

    final oldClean = oldName.trim();
    final newClean = newName.trim();

    if (oldClean.isEmpty ||
        newClean.isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final oldIndex = names.indexWhere(
          (item) =>
      item.toLowerCase() ==
          oldClean.toLowerCase(),
    );

    if (oldIndex == -1) {
      return false;
    }

    final duplicate = names.any(
          (item) =>
      item.toLowerCase() ==
          newClean.toLowerCase() &&
          item.toLowerCase() !=
              oldClean.toLowerCase(),
    );

    if (duplicate) {
      return false;
    }

    final actualOldName =
    names[oldIndex];

    final songs = await getPlaylist(
      actualOldName,
    );

    names[oldIndex] = newClean;

    await _prefs!.setStringList(
      _playlistNamesKey,
      names,
    );

    await _prefs!.setStringList(
      _playlistKey(newClean),
      songs
          .map(
            (song) => jsonEncode(
          _songToMap(song),
        ),
      )
          .toList(),
    );

    await _prefs!.remove(
      _playlistKey(actualOldName),
    );

    return true;
  }

  // ============================================================
  // ADD SONG TO PLAYLIST
  // ============================================================

  Future<bool> addSongToPlaylist(
      String playlistName,
      Song song,
      ) async {
    await init();

    if (playlistName.trim().isEmpty ||
        song.id.isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final actualNameIndex =
    names.indexWhere(
          (item) =>
      item.toLowerCase() ==
          playlistName.trim().toLowerCase(),
    );

    if (actualNameIndex == -1) {
      return false;
    }

    final actualName =
    names[actualNameIndex];

    final songs = await getPlaylist(
      actualName,
    );

    final exists = songs.any(
          (item) => item.id == song.id,
    );

    if (exists) {
      return false;
    }

    songs.add(
      song,
    );

    await _saveSongs(
      _playlistKey(actualName),
      songs,
    );

    return true;
  }

  // ============================================================
  // REMOVE SONG FROM PLAYLIST
  // ============================================================

  Future<bool> removeSongFromPlaylist(
      String playlistName,
      String songId,
      ) async {
    await init();

    if (playlistName.trim().isEmpty ||
        songId.trim().isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final actualNameIndex =
    names.indexWhere(
          (item) =>
      item.toLowerCase() ==
          playlistName.trim().toLowerCase(),
    );

    if (actualNameIndex == -1) {
      return false;
    }

    final actualName =
    names[actualNameIndex];

    final songs = await getPlaylist(
      actualName,
    );

    final oldLength = songs.length;

    songs.removeWhere(
          (song) => song.id == songId,
    );

    if (songs.length == oldLength) {
      return false;
    }

    await _saveSongs(
      _playlistKey(actualName),
      songs,
    );

    return true;
  }

  // ============================================================
  // CLEAR PLAYLIST
  // ============================================================

  Future<bool> clearPlaylist(
      String playlistName,
      ) async {
    await init();

    final cleanName =
    playlistName.trim();

    if (cleanName.isEmpty) {
      return false;
    }

    final names = await getPlaylistNames();

    final exists = names.any(
          (item) =>
      item.toLowerCase() ==
          cleanName.toLowerCase(),
    );

    if (!exists) {
      return false;
    }

    final actualName = names.firstWhere(
          (item) =>
      item.toLowerCase() ==
          cleanName.toLowerCase(),
    );

    await _prefs!.setStringList(
      _playlistKey(actualName),
      <String>[],
    );

    return true;
  }
}