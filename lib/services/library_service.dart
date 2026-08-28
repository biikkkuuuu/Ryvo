import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/models/song.dart';

class LibraryService {
  LibraryService._internal();
  static final LibraryService instance = LibraryService._internal();
  SharedPreferences? _prefs;

  static const String _likedKeyBase = 'ryvo_liked_songs';
  static const String _recentKeyBase = 'ryvo_recently_played';
  static const String _searchHistoryKeyBase = 'ryvo_search_history';
  static const String _playlistNamesKeyBase = 'ryvo_playlist_names';
  static const String _playlistPrefixBase = 'ryvo_playlist_';

  String get _userPrefix {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return 'ryvo_user_${uid == null || uid.isEmpty ? 'guest' : uid}';
  }

  String get _likedKey => '${_userPrefix}_$_likedKeyBase';
  String get _recentKey => '${_userPrefix}_$_recentKeyBase';
  String get _searchHistoryKey => '${_userPrefix}_$_searchHistoryKeyBase';
  String get _playlistNamesKey => '${_userPrefix}_$_playlistNamesKeyBase';
  String get _playlistPrefix => '${_userPrefix}_$_playlistPrefixBase';

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
    await _prefs!.setStringList(key, songs.map((song) => jsonEncode(_songToMap(song))).toList());
  }

  // --- Search History ---
  Future<void> addSearchQuery(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    await init();
    final history = _prefs!.getStringList(_searchHistoryKey) ?? <String>[];
    history.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());
    history.insert(0, cleanQuery);
    if (history.length > 30) history.removeRange(30, history.length);
    await _prefs!.setStringList(_searchHistoryKey, history);
  }

  Future<List<String>> getSearchHistory() async {
    await init();
    return List<String>.from(_prefs!.getStringList(_searchHistoryKey) ?? <String>[]);
  }

  Future<void> removeSearchQuery(String query) async {
    await init();
    final cleanQuery = query.trim();
    final history = _prefs!.getStringList(_searchHistoryKey) ?? <String>[];
    history.removeWhere((item) => item.toLowerCase() == cleanQuery.toLowerCase());
    await _prefs!.setStringList(_searchHistoryKey, history);
  }

  Future<void> clearSearchHistory() async {
    await init();
    await _prefs!.remove(_searchHistoryKey);
  }

  // --- Recently Played ---
  Future<void> addRecentlyPlayed(Song song) async {
    if (song.id.isEmpty) return;
    await init();
    final songs = _readSongs(_recentKey);
    songs.removeWhere((item) => item.id == song.id);
    songs.insert(0, song);

    // FIX: Limit increased from 20 to 200 for substantial history retention
    if (songs.length > 200) {
      songs.removeRange(200, songs.length);
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

  // --- Liked Songs ---
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

  Future<void> addLiked(Song song) async {
    if (song.id.isEmpty) return;
    await init();
    final songs = _readSongs(_likedKey);
    if (!songs.any((s) => s.id == song.id)) {
      songs.insert(0, song);
      await _saveSongs(_likedKey, songs);
    }
  }

  Future<void> removeLiked(String songId) async {
    await init();
    final songs = _readSongs(_likedKey)..removeWhere((song) => song.id == songId);
    await _saveSongs(_likedKey, songs);
  }

  Future<void> clearLikedSongs() async {
    await init();
    await _prefs!.remove(_likedKey);
  }

  // --- Playlist Logic ---
  String _playlistKey(String name) => '$_playlistPrefix${name.trim()}';

  Future<List<String>> getPlaylistNames() async {
    await init();
    return List<String>.from(_prefs!.getStringList(_playlistNamesKey) ?? <String>[]);
  }

  Future<bool> createPlaylist(String name) async {
    await init();
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;
    final names = await getPlaylistNames();
    if (names.any((item) => item.toLowerCase() == cleanName.toLowerCase())) return false;
    names.add(cleanName);
    await _prefs!.setStringList(_playlistNamesKey, names);
    await _prefs!.setStringList(_playlistKey(cleanName), <String>[]);
    return true;
  }

  Future<List<Song>> getPlaylist(String name) async {
    await init();
    final cleanName = name.trim();
    if (cleanName.isEmpty) return <Song>[];
    return _readSongs(_playlistKey(cleanName));
  }
  
  Future<List<Song>> getPlaylistSongs(String name) async {
    return getPlaylist(name);
  }

  Future<bool> deletePlaylist(String name) async {
    await init();
    final cleanName = name.trim();
    if (cleanName.isEmpty) return false;
    final names = await getPlaylistNames();
    final index = names.indexWhere((item) => item.toLowerCase() == cleanName.toLowerCase());
    if (index == -1) return false;
    final actualName = names[index];
    names.removeAt(index);
    await _prefs!.setStringList(_playlistNamesKey, names);
    await _prefs!.remove(_playlistKey(actualName));
    return true;
  }

  Future<bool> renamePlaylist(String oldName, String newName) async {
    await init();
    final oldClean = oldName.trim();
    final newClean = newName.trim();
    if (oldClean.isEmpty || newClean.isEmpty) return false;
    final names = await getPlaylistNames();
    final oldIndex = names.indexWhere((item) => item.toLowerCase() == oldClean.toLowerCase());
    if (oldIndex == -1) return false;
    if (names.any((item) => item.toLowerCase() == newClean.toLowerCase() && item.toLowerCase() != oldClean.toLowerCase())) return false;
    
    final actualOldName = names[oldIndex];
    final songs = await getPlaylist(actualOldName);
    names[oldIndex] = newClean;
    
    await _prefs!.setStringList(_playlistNamesKey, names);
    await _prefs!.setStringList(_playlistKey(newClean), songs.map((song) => jsonEncode(_songToMap(song))).toList());
    await _prefs!.remove(_playlistKey(actualOldName));
    return true;
  }

  Future<bool> addSongToPlaylist(String playlistName, Song song) async {
    await init();
    if (playlistName.trim().isEmpty || song.id.isEmpty) return false;
    final names = await getPlaylistNames();
    final idx = names.indexWhere((item) => item.toLowerCase() == playlistName.trim().toLowerCase());
    if (idx == -1) return false;
    final actualName = names[idx];
    final songs = await getPlaylist(actualName);
    if (songs.any((item) => item.id == song.id)) return false;
    songs.add(song);
    await _saveSongs(_playlistKey(actualName), songs);
    return true;
  }

  Future<bool> removeSongFromPlaylist(String playlistName, String songId) async {
    await init();
    if (playlistName.trim().isEmpty || songId.trim().isEmpty) return false;
    final names = await getPlaylistNames();
    final idx = names.indexWhere((item) => item.toLowerCase() == playlistName.trim().toLowerCase());
    if (idx == -1) return false;
    final actualName = names[idx];
    final songs = await getPlaylist(actualName);
    final oldLength = songs.length;
    songs.removeWhere((song) => song.id == songId);
    if (songs.length == oldLength) return false;
    await _saveSongs(_playlistKey(actualName), songs);
    return true;
  }

  Future<bool> clearPlaylist(String playlistName) async {
    await init();
    final cleanName = playlistName.trim();
    if (cleanName.isEmpty) return false;
    final names = await getPlaylistNames();
    final idx = names.indexWhere((item) => item.toLowerCase() == cleanName.toLowerCase());
    if (idx == -1) return false;
    final actualName = names[idx];
    await _prefs!.setStringList(_playlistKey(actualName), <String>[]);
    return true;
  }
}