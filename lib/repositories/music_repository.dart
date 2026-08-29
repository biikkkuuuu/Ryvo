import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:music_app/models/song.dart';
import 'package:music_app/services/jiosaavn_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchArtistResult {
  final String id;
  final String name;
  final String role;
  final String image;

  const SearchArtistResult({
    required this.id,
    required this.name,
    required this.role,
    required this.image,
  });
}

class ArtistSongsPage {
  final List<Song> songs;
  final int? total;

  const ArtistSongsPage({required this.songs, required this.total});
}

class SearchPlaylistResult {
  final String id;
  final String name;
  final String subtitle;
  final String image;
  final int? songCount;

  const SearchPlaylistResult({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.image,
    required this.songCount,
  });
}

class SearchAlbumResult {
  final String id;
  final String name;
  final String artist;
  final String image;
  final int? songCount;

  const SearchAlbumResult({
    required this.id,
    required this.name,
    required this.artist,
    required this.image,
    required this.songCount,
  });
}

class SearchResult {
  final List<Song> songs;
  final List<SearchAlbumResult> albums;
  final List<SearchPlaylistResult> playlists;
  final List<SearchArtistResult> artists;

  const SearchResult({
    required this.songs,
    required this.albums,
    required this.playlists,
    required this.artists,
  });

  bool get isEmpty {
    return songs.isEmpty &&
        albums.isEmpty &&
        playlists.isEmpty &&
        artists.isEmpty;
  }
}

class MusicRepository {
  final JioSaavnService _service = JioSaavnService();

  static const int _songsPerSection = 8;
  static const int _historyLimit = 160;
  static const int _apiPageLimit = 20;
  static const int _pagesPerQuery = 3;

  final Random _random = Random();

  Future<List<Song>> search(String query, {int pages = 1}) async {
    final value = query.trim();
    if (value.isEmpty) return [];

    final safePages = pages.clamp(1, 5);

    try {
      final artists = await artistSuggestions(value);
      final normalizedQuery = _normaliseArtistName(value);
      final exactArtist = artists.where(
        (artist) => _normaliseArtistName(artist.name) == normalizedQuery,
      );

      final artist = exactArtist.isNotEmpty ? exactArtist.first : null;
      if (artist != null && artist.id.trim().isNotEmpty) {
        final requests = <Future<ArtistSongsPage>>[];
        for (int page = 0; page < safePages; page++) {
          requests.add(getArtistSongsPage(artist.id, page: page));
        }

        final pagesResult = await Future.wait(requests);
        final songs = <Song>[];
        final ids = <String>{};
        final titles = <String>{};

        for (final result in pagesResult) {
          for (final song in result.songs) {
            if (song.id.trim().isEmpty || !ids.add(song.id)) continue;

            final title = _normaliseTitle(song.title);
            if (title.isNotEmpty && !titles.add(title)) continue;

            songs.add(song);
          }
        }

        return songs;
      }
    } catch (_) {}

    final requests = <Future<List<dynamic>>>[];

    for (int page = 0; page < safePages; page++) {
      requests.add(
        _service.searchSongs(value, page: page, limit: _apiPageLimit),
      );
    }

    final responses = await Future.wait(
      requests.map((request) async {
        try {
          return await request;
        } catch (_) {
          return <dynamic>[];
        }
      }),
    );

    final songs = <Song>[];
    final ids = <String>{};
    final titles = <String>{};

    for (final response in responses) {
      for (final song in _convertToSongs(response)) {
        if (song.id.trim().isEmpty) continue;
        final title = _normaliseTitle(song.title);
        if (!ids.add(song.id)) continue;
        if (title.isNotEmpty && !titles.add(title)) continue;
        songs.add(song);
      }
    }

    return songs;
  }

  Future<List<Song>> songSuggestions(String query) async {
    final value = query.trim();
    if (value.isEmpty) return [];

    try {
      final raw = await _service.searchSongs(value, page: 0, limit: 8);
      final songs = _convertToSongs(raw);

      final output = <Song>[];
      final ids = <String>{};
      final titles = <String>{};

      for (final song in songs) {
        if (song.id.isEmpty) continue;
        if (!ids.add(song.id)) continue;
        final title = _normaliseTitle(song.title);
        if (title.isNotEmpty && !titles.add(title)) continue;

        output.add(song);
        if (output.length >= 6) break;
      }

      return output;
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> getSongRecommendations(Song currentSong, {List<String> excludeIds = const []}) async {
    final artistName = currentSong.artist.trim();
    
    if (artistName.isEmpty || artistName.toLowerCase() == 'unknown' || artistName.toLowerCase() == 'unknown artist') {
      final fallback = await songSuggestions(currentSong.title);
      return fallback.where((s) => s.id != currentSong.id && !excludeIds.contains(s.id)).toList();
    }

    try {
      final artists = await artistSuggestions(artistName);
      final normalizedQuery = _normaliseArtistName(artistName);
      
      final exactArtist = artists.where(
        (artist) => _normaliseArtistName(artist.name) == normalizedQuery,
      ).firstOrNull ?? (artists.isNotEmpty ? artists.first : null);

      List<Song> candidates = [];

      if (exactArtist != null) {
        final artistSongs = await getArtistSongsPage(exactArtist.id, page: 0);
        candidates = artistSongs.songs;
      } else {
        candidates = await search(artistName, pages: 1);
      }

      final filtered = <Song>[];
      final uniqueIds = <String>{currentSong.id, ...excludeIds};

      for (final song in candidates) {
        if (uniqueIds.add(song.id)) {
          filtered.add(song);
        }
      }

      if (filtered.length < 5) {
        final extra = await songSuggestions(currentSong.title);
        for (final song in extra) {
            if (uniqueIds.add(song.id)) {
              filtered.add(song);
            }
        }
      }

      filtered.shuffle(_random);
      return filtered.take(15).toList();
    } catch (e) {
      debugPrint('RYVO RECOMMENDATION ERROR: $e');
      return [];
    }
  }

  Future<List<SearchArtistResult>> artistSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final raw = await _service.searchArtists(query.trim(), page: 0, limit: 5);
      return raw.map(_convertArtist).whereType<SearchArtistResult>().take(5).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchPlaylistResult>> playlistSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final raw = await _service.searchPlaylists(query.trim(), page: 0, limit: 5);
      return raw.map(_convertPlaylist).whereType<SearchPlaylistResult>().take(5).toList();
    } catch (_) {
      return [];
    }
  }

  Future<SearchResult> globalSearch(String query) async {
    final data = await _service.globalSearch(query.trim());

    if (data is! Map) {
      return const SearchResult(songs: [], albums: [], playlists: [], artists: []);
    }

    return SearchResult(
      songs: _songsFromGlobal(data),
      albums: _albumsFromGlobal(data),
      playlists: _playlistsFromGlobal(data),
      artists: _artistsFromGlobal(data),
    );
  }

  Future<ArtistSongsPage> getArtistSongsPage(String artistId, {required int page}) async {
    final id = artistId.trim();
    if (id.isEmpty) return const ArtistSongsPage(songs: [], total: null);

    final data = await _service.getArtistSongs(
      id, page: page, sortBy: 'popularity', sortOrder: 'desc',
    );

    if (data is! Map) return const ArtistSongsPage(songs: [], total: null);

    final rawSongs = data['songs'];
    final total = int.tryParse(data['total']?.toString() ?? '');
    final uniqueIds = <String>{};
    final songs = <Song>[];
    if (rawSongs is List) {
      for (final song in _convertToSongs(rawSongs)) {
        if (song.id.isNotEmpty && uniqueIds.add(song.id)) songs.add(song);
      }
    }
    return ArtistSongsPage(songs: songs, total: total);
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final data = await _service.getPlaylist(playlistId, page: 0, limit: 50);
    if (data is! Map) return [];

    final candidates = <dynamic>[];
    final directResults = data['results'];
    if (directResults is List) candidates.addAll(directResults);

    final songs = data['songs'];
    if (songs is List) candidates.addAll(songs);

    final result = data['results'];
    if (result is Map) {
      final nested = result['results'];
      if (nested is List) candidates.addAll(nested);
    }

    return _convertToSongs(candidates);
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      final albumData = await _service.getAlbum(albumId.trim());
      if (albumData is Map) {
        final rawSongs = albumData['songs'] ?? albumData['list'];
        if (rawSongs is List) {
          return _convertToSongs(rawSongs.whereType<Map>().toList());
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getRadioStations(List<String> songIds) async {
    try {
      return await _service.getRadioStations(songIds);
    } catch (e) {
      debugPrint('RYVO RADIO ERROR: $e');
      return [];
    }
  }

  Future<Map<String, List<Song>>> getHomeSections() async {
    try {
      final bundle = await getHomeBundle();
      final raw = bundle['sections'];
      if (raw is Map) {
        return raw.map<String, List<Song>>((key, value) {
          if (value is List<Song>) return MapEntry(key.toString(), value);
          return MapEntry(key.toString(), <Song>[]);
        });
      }
      return {};
    } catch (e) {
      debugPrint('RYVO HOME SECTIONS ERROR: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getHomeBundle() async {
    try {
      final homeData = await _service.getHome();
      if (homeData is! Map) throw Exception('Invalid Home response');

      final newlyReleased = await _resolveHomeModuleSongs(homeData['newReleases'], sectionName: 'Newly Released');
      final trending = await _resolveHomeModuleSongs(homeData['newTrending'], sectionName: 'Trending');
      final charts = await _resolveHomeModuleSongs(homeData['charts'], sectionName: 'Charts');
      final personalized = await _getPersonalizedSongs();

      List<SearchPlaylistResult> parsePlaylists(dynamic value) {
        if (value is! List) return [];
        return value.map(_convertPlaylist).whereType<SearchPlaylistResult>().toList();
      }

      List<SearchAlbumResult> parseAlbums(dynamic value) {
        if (value is! List) return [];
        return value.map(_convertAlbum).whereType<SearchAlbumResult>().toList();
      }

      List<Map<String, String>> parseSimple(dynamic value) {
        if (value is! List) return [];
        return value.whereType<Map>().map((item) {
              final moreInfo = item['more_info'];
              final info = moreInfo is Map ? moreInfo : const {};
              return <String, String>{
                'id': item['id']?.toString() ?? '',
                'title': item['title']?.toString() ?? item['name']?.toString() ?? '',
                'subtitle': item['subtitle']?.toString() ?? '',
                'type': item['type']?.toString() ?? '',
                'image': item['image']?.toString() ?? '',
                'permaUrl': item['perma_url']?.toString() ?? '',
                'squareImage': info['square_image']?.toString() ?? '',
                'season': info['season_number']?.toString() ?? '',
                'badge': info['badge']?.toString() ?? '',
              };
            }).where((item) => item['title']!.trim().isNotEmpty).toList();
      }

      return <String, dynamic>{
        'sections': <String, List<Song>>{
          if (personalized.isNotEmpty) 'Made For You': personalized,
          'Newly Released': newlyReleased,
          'Trending': trending,
          'Charts': charts,
        },
        'playlists': parsePlaylists(homeData['topPlaylists']),
        'discover': parseSimple(homeData['browseDiscover']),
        'albums': parseAlbums(homeData['newAlbums']),
        'shows': parseSimple(homeData['topShows']),
      };
    } catch (e) {
      debugPrint('RYVO HOME BUNDLE ERROR: $e');
      rethrow;
    }
  }
  
  Future<List<Song>> _getPersonalizedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final genres = prefs.getStringList('ryvo_preferred_genres') ?? <String>[];
      final artistIds = prefs.getStringList('ryvo_preferred_artist_ids') ?? <String>[];

      if (genres.isEmpty && artistIds.isEmpty) return <Song>[];

      final candidates = <Song>[];
      final ids = <String>{};

      for (final artistId in artistIds.take(5)) {
        try {
          if (artistId.trim().isEmpty) continue;
          for (int page = 0; page < 3; page++) {
            final result = await getArtistSongsPage(artistId, page: page);
            if (result.songs.isEmpty) break;
            for (final song in result.songs) {
              final id = song.id.trim();
              if (id.isNotEmpty && ids.add(id)) candidates.add(song);
            }
          }
        } catch (e) {
          debugPrint('RYVO PERSONALIZED ARTIST ERROR: $e');
        }
      }

      for (final genre in genres.take(4)) {
        try {
          final result = await search(genre, pages: 1);
          for (final song in result) {
            final id = song.id.trim();
            if (id.isNotEmpty && ids.add(id)) candidates.add(song);
          }
        } catch (e) {
          debugPrint('RYVO PERSONALIZED GENRE ERROR: $e');
        }
      }

      if (candidates.isEmpty) return <Song>[];

      final finalSongs = await _selectFreshSongs(sectionName: 'Made For You', candidates: candidates);
      return finalSongs;
    } catch (e) {
      debugPrint('RYVO PERSONALIZED ERROR: $e');
      return <Song>[];
    }
  }

  Future<List<Song>> _resolveHomeModuleSongs(dynamic value, {required String sectionName}) async {
    if (value is! List) return [];

    final output = <Song>[];
    final ids = <String>{};
    final processedAlbums = <String>{};

    void addSongs(List<Song> songs) {
      for (final song in songs) {
        final id = song.id.trim();
        if (id.isEmpty || !ids.add(id)) continue;
        output.add(song);
        if (output.length >= _songsPerSection) break;
      }
    }

    for (final item in value.whereType<Map>()) {
      final type = item['type']?.toString().trim().toLowerCase() ?? '';

      if (type == 'song') {
        addSongs(_convertToSongs([item]));
        if (output.length >= _songsPerSection) break;
        continue;
      }

      final albumId = item['id']?.toString().trim() ?? '';
      if (albumId.isNotEmpty && (type == 'album' || type == 'compilation' || type.isEmpty)) {
        if (!processedAlbums.add(albumId)) continue;
        try {
          final albumData = await _service.getAlbum(albumId);
          dynamic rawSongs;
          if (albumData is Map) {
            rawSongs = albumData['songs'];
            if (rawSongs is! List) rawSongs = albumData['list'];
          }
          if (rawSongs is List) {
            addSongs(_convertToSongs(rawSongs.whereType<Map>().toList()));
          }
        } catch (e) {
          debugPrint('RYVO HOME $sectionName album fetch failed [$albumId]: $e');
        }
      }

      if (output.length >= _songsPerSection) break;
    }

    return _uniqueSongs(output).take(_songsPerSection).toList();
  }

  Future<List<Song>> _selectFreshSongs({required String sectionName, required List<Song> candidates}) async {
    if (candidates.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'ryvo_home_history_${_key(sectionName)}';
    final history = prefs.getStringList(historyKey) ?? [];
    final historySet = history.toSet();

    final shuffled = List<Song>.from(candidates)..shuffle(_random);
    final fresh = shuffled.where((song) => !historySet.contains(song.id)).toList();

    final selected = <Song>[];
    final artists = <String, int>{};

    for (final song in fresh) {
      if (selected.length >= _songsPerSection) break;
      final artist = _artistKey(song.artist);
      final count = artists[artist] ?? 0;
      if (count >= 2) continue;
      selected.add(song);
      artists[artist] = count + 1;
    }

    if (selected.length < _songsPerSection) {
      for (final song in fresh) {
        if (selected.length >= _songsPerSection) break;
        if (_containsSong(selected, song)) continue;
        selected.add(song);
      }
    }

    if (selected.length < _songsPerSection) {
      for (final song in shuffled) {
        if (selected.length >= _songsPerSection) break;
        if (_containsSong(selected, song)) continue;
        selected.add(song);
      }
    }

    final newHistory = <String>[...selected.map((song) => song.id), ...history];
    final cleanedHistory = <String>[];
    final seen = <String>{};

    for (final id in newHistory) {
      if (!seen.add(id)) continue;
      cleanedHistory.add(id);
      if (cleanedHistory.length >= _historyLimit) break;
    }

    await prefs.setStringList(historyKey, cleanedHistory);
    return selected;
  }

  List<Song> _songsFromGlobal(Map data) {
    final raw = _findResults(data, ['songs', 'song']);
    return _convertToSongs(raw).take(20).toList();
  }

  List<SearchAlbumResult> _albumsFromGlobal(Map data) {
    final raw = _findResults(data, ['albums', 'album']);
    return raw.map(_convertAlbum).whereType<SearchAlbumResult>().take(10).toList();
  }

  List<SearchPlaylistResult> _playlistsFromGlobal(Map data) {
    final raw = _findResults(data, ['playlists', 'playlist']);
    return raw.map(_convertPlaylist).whereType<SearchPlaylistResult>().take(10).toList();
  }

  List<SearchArtistResult> _artistsFromGlobal(Map data) {
    final raw = _findResults(data, ['artists', 'artist']);
    return raw.map(_convertArtist).whereType<SearchArtistResult>().take(10).toList();
  }

  List<dynamic> _findResults(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is List) return List<dynamic>.from(value);
      if (value is Map) {
        final results = value['results'];
        if (results is List) return List<dynamic>.from(results);
      }
    }
    final nestedData = data['data'];
    if (nestedData is Map) return _findResults(nestedData, keys);
    return [];
  }

  List<Song> _convertToSongs(dynamic results) {
    if (results is! List) return [];

    return results.map<Song?>((item) {
      if (item is! Map) return null;

      final id = item['id']?.toString() ?? '';
      final title = item['name']?.toString() ?? item['title']?.toString() ?? '';

      String artist = 'Unknown';
      String image = '';
      String downloadUrl = '';

      final artists = item['artists'];
      if (artists is Map) {
        final primary = artists['primary'];
        if (primary is List && primary.isNotEmpty) {
          final first = primary.first;
          if (first is Map) artist = first['name']?.toString() ?? 'Unknown';
        }
      }
      if (artist == 'Unknown') artist = item['subtitle']?.toString() ?? 'Unknown';

      final images = item['image'];
      if (images is List && images.isNotEmpty) {
        final last = images.last;
        if (last is Map) {
          image = last['url']?.toString() ?? '';
        } else if (last is String) {
          image = last;
        }
      } else if (images is String) {
        image = images;
      }

      // EXTRACT DOWNLOAD URL
      final urls = item['downloadUrl'];
      if (urls is List && urls.isNotEmpty) {
        for (final u in urls) {
          if (u is Map && u['quality'] == '320kbps') {
            downloadUrl = u['url']?.toString() ?? '';
            break;
          }
        }
        if (downloadUrl.isEmpty) {
          final last = urls.last;
          if (last is Map) downloadUrl = last['url']?.toString() ?? '';
        }
      }

      return Song(id: id, title: title, artist: artist, thumbnail: image, downloadUrl: downloadUrl);
    }).whereType<Song>().toList();
  }

  SearchArtistResult? _convertArtist(dynamic item) {
    if (item is! Map) return null;
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? item['title']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    return SearchArtistResult(id: id, name: name, role: item['role']?.toString() ?? 'Artist', image: _extractImage(item));
  }

  SearchPlaylistResult? _convertPlaylist(dynamic item) {
    if (item is! Map) return null;
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? item['title']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    int? count;
    final rawCount = item['songCount'] ?? item['song_count'] ?? item['numsongs'];
    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount != null) {
      count = int.tryParse(rawCount.toString());
    }
    return SearchPlaylistResult(id: id, name: name, subtitle: item['subtitle']?.toString() ?? item['description']?.toString() ?? 'Playlist', image: _extractImage(item), songCount: count);
  }

  SearchAlbumResult? _convertAlbum(dynamic item) {
    if (item is! Map) return null;
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? item['title']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    int? count;
    final rawCount = item['songCount'] ?? item['song_count'] ?? item['numsongs'];
    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount != null) {
      count = int.tryParse(rawCount.toString());
    }
    return SearchAlbumResult(id: id, name: name, artist: item['subtitle']?.toString() ?? item['artist']?.toString() ?? 'Album', image: _extractImage(item), songCount: count);
  }

  String _extractImage(Map item) {
    final image = item['image'];
    if (image is String) return image;
    if (image is List && image.isNotEmpty) {
      final last = image.last;
      if (last is String) return last;
      if (last is Map) return last['url']?.toString() ?? '';
    }
    final images = item['images'];
    if (images is List && images.isNotEmpty) {
      final last = images.last;
      if (last is String) return last;
      if (last is Map) return last['url']?.toString() ?? '';
    }
    return '';
  }

  List<Song> _uniqueSongs(List<Song> songs) {
    final map = <String, Song>{};
    for (final song in songs) {
      final id = song.id.trim();
      if (id.isEmpty) continue;
      map[id] = song;
    }
    return map.values.toList();
  }

  bool _containsSong(List<Song> songs, Song target) => songs.any((song) => song.id == target.id);
  String _normaliseArtistName(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  String _artistKey(String artist) {
    final value = artist.trim().toLowerCase();
    if (value.isEmpty || value == 'unknown' || value == 'unknown artist') return 'unknown';
    return value;
  }
  String _normaliseTitle(String title) => title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  String _key(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}