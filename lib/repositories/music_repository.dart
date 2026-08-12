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

  // ============================================================
  // NORMAL SONG SEARCH
  // ============================================================

  Future<List<Song>> search(
      String query, {
        int pages = 1,
      }) async {
    final safePages = pages.clamp(1, 5);

    final requests = <Future<List<dynamic>>>[];

    for (int page = 0; page < safePages; page++) {
      requests.add(
        _service.searchSongs(
          query,
          page: page,
          limit: _apiPageLimit,
        ),
      );
    }

    final responses = await Future.wait(
      requests.map(
            (request) async {
          try {
            return await request;
          } catch (_) {
            return <dynamic>[];
          }
        },
      ),
    );

    final songs = <Song>[];
    final ids = <String>{};
    final titles = <String>{};

    for (final response in responses) {
      for (final song in _convertToSongs(response)) {
        if (song.id.trim().isEmpty) {
          continue;
        }

        final title = _normaliseTitle(song.title);

        if (!ids.add(song.id)) {
          continue;
        }

        if (title.isNotEmpty && !titles.add(title)) {
          continue;
        }

        songs.add(song);
      }
    }

    return songs;
  }

  // ============================================================
  // LIVE SONG SUGGESTIONS
  // ============================================================

  Future<List<Song>> songSuggestions(
      String query,
      ) async {
    final value = query.trim();

    if (value.isEmpty) {
      return [];
    }

    try {
      final raw = await _service.searchSongs(
        value,
        page: 0,
        limit: 8,
      );

      final songs = _convertToSongs(raw);

      final output = <Song>[];
      final ids = <String>{};
      final titles = <String>{};

      for (final song in songs) {
        if (song.id.isEmpty) {
          continue;
        }

        if (!ids.add(song.id)) {
          continue;
        }

        final title = _normaliseTitle(song.title);

        if (title.isNotEmpty && !titles.add(title)) {
          continue;
        }

        output.add(song);

        if (output.length >= 6) {
          break;
        }
      }

      return output;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // ARTIST SUGGESTIONS
  // ============================================================

  Future<List<SearchArtistResult>> artistSuggestions(
      String query,
      ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final raw = await _service.searchArtists(
        query.trim(),
        page: 0,
        limit: 5,
      );

      return raw
          .map(_convertArtist)
          .whereType<SearchArtistResult>()
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // PLAYLIST SUGGESTIONS
  // ============================================================

  Future<List<SearchPlaylistResult>> playlistSuggestions(
      String query,
      ) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final raw = await _service.searchPlaylists(
        query.trim(),
        page: 0,
        limit: 5,
      );

      return raw
          .map(_convertPlaylist)
          .whereType<SearchPlaylistResult>()
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // FULL GLOBAL SEARCH
  // ============================================================

  Future<SearchResult> globalSearch(
      String query,
      ) async {
    final data = await _service.globalSearch(query.trim());

    if (data is! Map) {
      return const SearchResult(
        songs: [],
        albums: [],
        playlists: [],
        artists: [],
      );
    }

    return SearchResult(
      songs: _songsFromGlobal(data),
      albums: _albumsFromGlobal(data),
      playlists: _playlistsFromGlobal(data),
      artists: _artistsFromGlobal(data),
    );
  }

  // ============================================================
  // ARTIST SONGS
  //
  // API RESPONSE:
  //
  // {
  //   "success": true,
  //   "data": {
  //     "total": 4621,
  //     "songs": [...]
  //   }
  // }
  //
  // IMPORTANT:
  // This method expects ARTIST ID, not artist name.
  //
  // Example:
  // artistId = "456857"
  //
  // Endpoint:
  // /api/artists/456857/songs
  // ============================================================

  Future<List<Song>> searchArtistSongs(
      String artistId, {
        int pages = 3,
      }) async {
    final id = artistId.trim();

    if (id.isEmpty) {
      return [];
    }

    final songs = <Song>[];
    final ids = <String>{};

    final safePages = pages.clamp(1, 5);

    for (int page = 0; page < safePages; page++) {
      try {
        final data = await _service.getArtistSongs(
          id,
          page: page,
          sortBy: 'popularity',
          sortOrder: 'desc',
        );

        dynamic rawResults;

        // --------------------------------------------------------
        // RESPONSE SUPPORT
        //
        // 1. { "results": [...] }
        //
        // 2. { "data": { "results": [...] } }
        //
        // 3. { "songs": [...] }
        //
        // 4. { "data": { "songs": [...] } }
        //
        // Current API uses #4.
        // --------------------------------------------------------

        if (data is Map) {
          // Direct:
          // { "results": [...] }
          rawResults = data['results'];

          if (rawResults is! List) {
            final nestedData = data['data'];

            if (nestedData is Map) {
              // Possible:
              // { "data": { "results": [...] } }
              rawResults = nestedData['results'];

              // CURRENT API:
              // { "data": { "songs": [...] } }
              if (rawResults is! List) {
                rawResults = nestedData['songs'];
              }
            }
          }

          // Possible:
          // { "songs": [...] }
          if (rawResults is! List) {
            final directSongs = data['songs'];

            if (directSongs is List) {
              rawResults = directSongs;
            }
          }
        } else {
          rawResults = data;
        }

        if (rawResults is! List) {
          debugPrint(
            'Artist songs: no results on page $page',
          );
          continue;
        }

        debugPrint(
          'Artist songs: page $page received '
              '${rawResults.length} songs',
        );

        final convertedSongs = _convertToSongs(
          rawResults,
        );

        for (final song in convertedSongs) {
          if (song.id.trim().isEmpty) {
            continue;
          }

          if (!ids.add(song.id)) {
            continue;
          }

          songs.add(song);
        }
      } catch (e) {
        debugPrint(
          'Artist songs page $page error: $e',
        );
      }
    }

    debugPrint(
      'Artist songs: total converted = ${songs.length}',
    );

    return songs;
  }

  // ============================================================
  // PLAYLIST SONGS
  // ============================================================

  Future<List<Song>> getPlaylistSongs(
      String playlistId,
      ) async {
    final data = await _service.getPlaylist(
      playlistId,
      page: 0,
      limit: 50,
    );

    if (data is! Map) {
      return [];
    }

    final candidates = <dynamic>[];

    final directResults = data['results'];

    if (directResults is List) {
      candidates.addAll(directResults);
    }

    final songs = data['songs'];

    if (songs is List) {
      candidates.addAll(songs);
    }

    final result = data['results'];

    if (result is Map) {
      final nested = result['results'];

      if (nested is List) {
        candidates.addAll(nested);
      }
    }

    return _convertToSongs(candidates);
  }

  // ============================================================
  // HOME
  // ============================================================

  Future<Map<String, List<Song>>> getHomeSections() async {
    final sectionQueries = <String, List<String>>{
      'Trending': [
        'trending songs',
        'viral songs',
        'latest hit songs',
        'new trending songs',
        'top songs',
      ],
      'Hindi Hits': [
        'latest hindi songs',
        'new bollywood songs',
        'hindi hit songs',
        'latest hindi hits',
        'new hindi songs',
      ],
      'Romantic': [
        'latest romantic songs',
        'new romantic songs',
        'romantic hindi hits',
        'romantic songs',
        'love songs',
      ],
      'Punjabi': [
        'latest punjabi songs',
        'new punjabi songs',
        'punjabi hits',
        'punjabi trending songs',
        'new punjabi hits',
      ],
      'English': [
        'latest english songs',
        'new english hits',
        'english trending songs',
        'popular english songs',
        'new english songs',
      ],
      'Chill': [
        'latest chill songs',
        'new chill music',
        'chill hits',
        'relaxing songs',
        'chill playlist',
      ],
    };

    final entries = sectionQueries.entries.toList();

    final results = await Future.wait(
      entries.map(
            (entry) async {
          final candidates =
          await _fetchCandidates(entry.value);

          final selected =
          await _selectFreshSongs(
            sectionName: entry.key,
            candidates: candidates,
          );

          return MapEntry(
            entry.key,
            selected,
          );
        },
      ),
    );

    final sections = <String, List<Song>>{};
    final globallyUsedIds = <String>{};

    for (final result in results) {
      final filtered = <Song>[];

      for (final song in result.value) {
        if (song.id.isEmpty) {
          continue;
        }

        if (!globallyUsedIds.add(song.id)) {
          continue;
        }

        filtered.add(song);

        if (filtered.length >= _songsPerSection) {
          break;
        }
      }

      sections[result.key] = filtered;
    }

    return sections;
  }

  // ============================================================
  // HOME CANDIDATES
  // ============================================================

  Future<List<Song>> _fetchCandidates(
      List<String> queries,
      ) async {
    final shuffledQueries =
    List<String>.from(queries)
      ..shuffle(_random);

    final requests = <Future<List<dynamic>>>[];

    for (final query in shuffledQueries) {
      for (
      int page = 0;
      page < _pagesPerQuery;
      page++
      ) {
        requests.add(
          _service.searchSongs(
            query,
            page: page,
            limit: _apiPageLimit,
          ),
        );
      }
    }

    final responses = await Future.wait(
      requests.map(
            (request) async {
          try {
            return await request;
          } catch (_) {
            return <dynamic>[];
          }
        },
      ),
    );

    final candidates = <Song>[];
    final ids = <String>{};
    final titles = <String>{};

    for (final raw in responses) {
      for (final song in _convertToSongs(raw)) {
        if (song.id.isEmpty) {
          continue;
        }

        final title = _normaliseTitle(song.title);

        if (!ids.add(song.id)) {
          continue;
        }

        if (title.isNotEmpty &&
            !titles.add(title)) {
          continue;
        }

        candidates.add(song);
      }
    }

    candidates.shuffle(_random);

    return candidates;
  }

  // ============================================================
  // HOME FRESH SELECTION
  // ============================================================

  Future<List<Song>> _selectFreshSongs({
    required String sectionName,
    required List<Song> candidates,
  }) async {
    if (candidates.isEmpty) {
      return [];
    }

    final prefs =
    await SharedPreferences.getInstance();

    final historyKey =
        'ryvo_home_history_${_key(sectionName)}';

    final history =
        prefs.getStringList(historyKey) ?? [];

    final historySet = history.toSet();

    final shuffled =
    List<Song>.from(candidates)
      ..shuffle(_random);

    final fresh = shuffled
        .where(
          (song) =>
      !historySet.contains(song.id),
    )
        .toList();

    final selected = <Song>[];
    final artists = <String, int>{};

    for (final song in fresh) {
      if (selected.length >= _songsPerSection) {
        break;
      }

      final artist = _artistKey(song.artist);
      final count = artists[artist] ?? 0;

      if (count >= 2) {
        continue;
      }

      selected.add(song);
      artists[artist] = count + 1;
    }

    if (selected.length < _songsPerSection) {
      for (final song in fresh) {
        if (selected.length >= _songsPerSection) {
          break;
        }

        if (_containsSong(selected, song)) {
          continue;
        }

        selected.add(song);
      }
    }

    if (selected.length < _songsPerSection) {
      for (final song in shuffled) {
        if (selected.length >= _songsPerSection) {
          break;
        }

        if (_containsSong(selected, song)) {
          continue;
        }

        selected.add(song);
      }
    }

    final newHistory = <String>[
      ...selected.map((song) => song.id),
      ...history,
    ];

    final cleanedHistory = <String>[];
    final seen = <String>{};

    for (final id in newHistory) {
      if (!seen.add(id)) {
        continue;
      }

      cleanedHistory.add(id);

      if (cleanedHistory.length >=
          _historyLimit) {
        break;
      }
    }

    await prefs.setStringList(
      historyKey,
      cleanedHistory,
    );

    return selected;
  }

  // ============================================================
  // GLOBAL SONG PARSER
  // ============================================================

  List<Song> _songsFromGlobal(
      Map data,
      ) {
    final raw = _findResults(
      data,
      [
        'songs',
        'song',
      ],
    );

    return _convertToSongs(raw)
        .take(20)
        .toList();
  }

  // ============================================================
  // GLOBAL ALBUM PARSER
  // ============================================================

  List<SearchAlbumResult> _albumsFromGlobal(
      Map data,
      ) {
    final raw = _findResults(
      data,
      [
        'albums',
        'album',
      ],
    );

    return raw
        .map(_convertAlbum)
        .whereType<SearchAlbumResult>()
        .take(10)
        .toList();
  }

  // ============================================================
  // GLOBAL PLAYLIST PARSER
  // ============================================================

  List<SearchPlaylistResult> _playlistsFromGlobal(
      Map data,
      ) {
    final raw = _findResults(
      data,
      [
        'playlists',
        'playlist',
      ],
    );

    return raw
        .map(_convertPlaylist)
        .whereType<SearchPlaylistResult>()
        .take(10)
        .toList();
  }

  // ============================================================
  // GLOBAL ARTIST PARSER
  // ============================================================

  List<SearchArtistResult> _artistsFromGlobal(
      Map data,
      ) {
    final raw = _findResults(
      data,
      [
        'artists',
        'artist',
      ],
    );

    return raw
        .map(_convertArtist)
        .whereType<SearchArtistResult>()
        .take(10)
        .toList();
  }

  // ============================================================
  // FLEXIBLE RESULTS FINDER
  // ============================================================

  List<dynamic> _findResults(
      Map data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value is List) {
        return List<dynamic>.from(value);
      }

      if (value is Map) {
        final results = value['results'];

        if (results is List) {
          return List<dynamic>.from(results);
        }
      }
    }

    final nestedData = data['data'];

    if (nestedData is Map) {
      return _findResults(
        nestedData,
        keys,
      );
    }

    return [];
  }

  // ============================================================
  // SONG CONVERSION
  // ============================================================

  List<Song> _convertToSongs(
      dynamic results,
      ) {
    if (results is! List) {
      return [];
    }

    return results
        .map<Song?>((item) {
      if (item is! Map) {
        return null;
      }

      final id =
          item['id']?.toString() ?? '';

      final title =
          item['name']?.toString() ??
              item['title']?.toString() ??
              '';

      String artist = 'Unknown';
      String image = '';

      final artists = item['artists'];

      if (artists is Map) {
        final primary =
        artists['primary'];

        if (primary is List &&
            primary.isNotEmpty) {
          final first = primary.first;

          if (first is Map) {
            artist =
                first['name']
                    ?.toString() ??
                    'Unknown';
          }
        }
      }

      if (artist == 'Unknown') {
        artist =
            item['subtitle']?.toString() ??
                'Unknown';
      }

      final images = item['image'];

      if (images is List &&
          images.isNotEmpty) {
        final last = images.last;

        if (last is Map) {
          image =
              last['url']?.toString() ??
                  '';
        } else if (last is String) {
          image = last;
        }
      } else if (images is String) {
        image = images;
      }

      return Song(
        id: id,
        title: title,
        artist: artist,
        thumbnail: image,
      );
    })
        .whereType<Song>()
        .toList();
  }

  // ============================================================
  // ARTIST CONVERSION
  // ============================================================

  SearchArtistResult? _convertArtist(
      dynamic item,
      ) {
    if (item is! Map) {
      return null;
    }

    final id =
        item['id']?.toString() ?? '';

    final name =
        item['name']?.toString() ??
            item['title']?.toString() ??
            '';

    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    return SearchArtistResult(
      id: id,
      name: name,
      role:
      item['role']?.toString() ??
          'Artist',
      image: _extractImage(item),
    );
  }

  // ============================================================
  // PLAYLIST CONVERSION
  // ============================================================

  SearchPlaylistResult? _convertPlaylist(
      dynamic item,
      ) {
    if (item is! Map) {
      return null;
    }

    final id =
        item['id']?.toString() ?? '';

    final name =
        item['name']?.toString() ??
            item['title']?.toString() ??
            '';

    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    int? count;

    final rawCount =
        item['songCount'] ??
            item['song_count'] ??
            item['numsongs'];

    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount != null) {
      count = int.tryParse(
        rawCount.toString(),
      );
    }

    return SearchPlaylistResult(
      id: id,
      name: name,
      subtitle:
      item['subtitle']?.toString() ??
          item['description']?.toString() ??
          'Playlist',
      image: _extractImage(item),
      songCount: count,
    );
  }

  // ============================================================
  // ALBUM CONVERSION
  // ============================================================

  SearchAlbumResult? _convertAlbum(
      dynamic item,
      ) {
    if (item is! Map) {
      return null;
    }

    final id =
        item['id']?.toString() ?? '';

    final name =
        item['name']?.toString() ??
            item['title']?.toString() ??
            '';

    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    int? count;

    final rawCount =
        item['songCount'] ??
            item['song_count'] ??
            item['numsongs'];

    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount != null) {
      count = int.tryParse(
        rawCount.toString(),
      );
    }

    return SearchAlbumResult(
      id: id,
      name: name,
      artist:
      item['subtitle']?.toString() ??
          item['artist']?.toString() ??
          'Album',
      image: _extractImage(item),
      songCount: count,
    );
  }

  // ============================================================
  // IMAGE EXTRACTION
  // ============================================================

  String _extractImage(
      Map item,
      ) {
    final image = item['image'];

    if (image is String) {
      return image;
    }

    if (image is List &&
        image.isNotEmpty) {
      final last = image.last;

      if (last is String) {
        return last;
      }

      if (last is Map) {
        return last['url']
            ?.toString() ??
            '';
      }
    }

    final images = item['images'];

    if (images is List &&
        images.isNotEmpty) {
      final last = images.last;

      if (last is String) {
        return last;
      }

      if (last is Map) {
        return last['url']
            ?.toString() ??
            '';
      }
    }

    return '';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _containsSong(
      List<Song> songs,
      Song target,
      ) {
    return songs.any(
          (song) => song.id == target.id,
    );
  }

  String _artistKey(
      String artist,
      ) {
    final value =
    artist.trim().toLowerCase();

    if (value.isEmpty ||
        value == 'unknown' ||
        value == 'unknown artist') {
      return 'unknown';
    }

    return value;
  }

  String _normaliseTitle(
      String title,
      ) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  String _key(
      String value,
      ) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
  }
}