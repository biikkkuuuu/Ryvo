import 'dart:math';

import 'package:music_app/models/song.dart';
import 'package:music_app/services/jiosaavn_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicRepository {
  final JioSaavnService _service = JioSaavnService();

  static const int _songsPerSection = 8;
  static const int _historyLimit = 160;
  static const int _apiPageLimit = 20;
  static const int _pagesPerQuery = 3;

  final Random _random = Random();

  Future<List<Song>> search(String query) async {
    final results = await _service.searchSongs(
      query,
      page: 0,
      limit: _apiPageLimit,
    );

    return _convertToSongs(results);
  }

  // ============================================================
  // HOME SECTIONS
  // ============================================================

  Future<Map<String, List<Song>>> getHomeSections() async {
    final sectionQueries = <String, List<String>>{
      "Trending": [
        "trending songs",
        "viral songs",
        "latest hit songs",
        "new trending songs",
        "top songs",
      ],
      "Hindi Hits": [
        "latest hindi songs",
        "new bollywood songs",
        "hindi hit songs",
        "latest hindi hits",
        "new hindi songs",
      ],
      "Romantic": [
        "latest romantic songs",
        "new romantic songs",
        "romantic hindi hits",
        "romantic songs",
        "love songs",
      ],
      "Punjabi": [
        "latest punjabi songs",
        "new punjabi songs",
        "punjabi hits",
        "punjabi trending songs",
        "new punjabi hits",
      ],
      "English": [
        "latest english songs",
        "new english hits",
        "english trending songs",
        "popular english songs",
        "new english songs",
      ],
      "Chill": [
        "latest chill songs",
        "new chill music",
        "chill hits",
        "relaxing songs",
        "chill playlist",
      ],
    };

    final entries = sectionQueries.entries.toList();

    final results = await Future.wait(
      entries.map(
            (entry) async {
          final candidates = await _fetchCandidates(
            entry.value,
          );

          final selected = await _selectFreshSongs(
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

    // Same song ko ek Home load ke andar
    // multiple sections me repeat hone se rokna.
    final globallyUsedIds = <String>{};

    for (final result in results) {
      final filtered = <Song>[];

      for (final song in result.value) {
        if (song.id.isEmpty) continue;

        if (globallyUsedIds.contains(song.id)) {
          continue;
        }

        filtered.add(song);
        globallyUsedIds.add(song.id);

        if (filtered.length >= _songsPerSection) {
          break;
        }
      }

      sections[result.key] = filtered;
    }

    return sections;
  }

  // ============================================================
  // FETCH MULTIPLE QUERIES + MULTIPLE PAGES
  // ============================================================

  Future<List<Song>> _fetchCandidates(
      List<String> queries,
      ) async {
    final shuffledQueries =
    List<String>.from(queries)..shuffle(_random);

    final requests = <Future<List>>[];

    for (final query in shuffledQueries) {
      for (int page = 0; page < _pagesPerQuery; page++) {
        requests.add(
          _service.searchSongs(
            query,
            page: page,
            limit: _apiPageLimit,
          ),
        );
      }
    }

    final results = await Future.wait(
      requests.map(
            (request) async {
          try {
            return await request;
          } catch (_) {
            return [];
          }
        },
      ),
    );

    final candidates = <Song>[];
    final usedIds = <String>{};
    final usedTitles = <String>{};

    for (final raw in results) {
      final songs = _convertToSongs(raw);

      for (final song in songs) {
        final id = song.id.trim();

        if (id.isEmpty) {
          continue;
        }

        final title = _normaliseTitle(song.title);

        if (usedIds.contains(id)) {
          continue;
        }

        if (title.isNotEmpty &&
            usedTitles.contains(title)) {
          continue;
        }

        usedIds.add(id);

        if (title.isNotEmpty) {
          usedTitles.add(title);
        }

        candidates.add(song);
      }
    }

    candidates.shuffle(_random);

    return candidates;
  }

  // ============================================================
  // SELECT FRESH SONGS
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
    List<Song>.from(candidates)..shuffle(_random);

    // Pehle wo songs jo recently nahi aaye.
    final fresh = shuffled
        .where(
          (song) => !historySet.contains(song.id),
    )
        .toList();

    final selected = <Song>[];
    final artists = <String, int>{};

    // ==========================================================
    // PASS 1
    // Fresh + artist diversity
    // ==========================================================

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

    // ==========================================================
    // PASS 2
    // Fresh songs se remaining slots fill
    // ==========================================================

    if (selected.length < _songsPerSection) {
      for (final song in fresh) {
        if (selected.length >= _songsPerSection) {
          break;
        }

        if (_containsSong(selected, song)) {
          continue;
        }

        selected.add(song);

        final artist = _artistKey(song.artist);

        artists[artist] =
            (artists[artist] ?? 0) + 1;
      }
    }

    // ==========================================================
    // PASS 3
    // Agar fresh candidates kam hain,
    // purane candidates se fill karo.
    // ==========================================================

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

    // ==========================================================
    // HISTORY UPDATE
    // ==========================================================

    final newHistory = <String>[
      ...selected.map((song) => song.id),
      ...history,
    ];

    final cleanedHistory = <String>[];
    final historySeen = <String>{};

    for (final id in newHistory) {
      if (!historySeen.add(id)) {
        continue;
      }

      cleanedHistory.add(id);

      if (cleanedHistory.length >= _historyLimit) {
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

  String _artistKey(String artist) {
    final value =
    artist.trim().toLowerCase();

    if (value.isEmpty ||
        value == 'unknown' ||
        value == 'unknown artist') {
      return 'unknown';
    }

    return value;
  }

  String _normaliseTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
  }

  String _key(String value) {
    return value
        .toLowerCase()
        .replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
  }

  // ============================================================
  // API → SONG
  // ============================================================

  List<Song> _convertToSongs(dynamic results) {
    if (results is! List) {
      return [];
    }

    return results.map<Song>((item) {
      String id = '';
      String title = '';
      String artist = 'Unknown';
      String image = '';

      if (item is Map) {
        id = item['id']?.toString() ?? '';

        title = item['name']?.toString() ?? '';

        final artists = item['artists'];

        if (artists is Map) {
          final primary =
          artists['primary'];

          if (primary is List &&
              primary.isNotEmpty &&
              primary.first is Map) {
            artist =
                primary.first['name']?.toString() ??
                    'Unknown';
          }
        }

        final images = item['image'];

        if (images is List &&
            images.isNotEmpty) {
          final last = images.last;

          if (last is Map) {
            image =
                last['url']?.toString() ?? '';
          }
        }
      }

      return Song(
        id: id,
        title: title,
        artist: artist,
        thumbnail: image,
      );
    }).toList();
  }
}