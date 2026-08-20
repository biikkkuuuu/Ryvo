import 'dart:convert';

import 'package:http/http.dart' as http;

class JioSaavnService {
  static const String baseUrl =
      'https://jiosaavn-api-main-taupe.vercel.app';

  // ============================================================
  // COMMON GET
  // ============================================================

  Future<dynamic> _get(
      String path,
      Map<String, String> params,
      ) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: params,
    );

    print('RYVO API: $uri');

    final response = await http
        .get(uri)
        .timeout(
      const Duration(seconds: 15),
    );

    print(
      'RYVO API STATUS: ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid API response',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'API returned success=false',
      );
    }

    return decoded['data'];
  }

  // ============================================================
  // SONG SEARCH
  // ============================================================

  Future<List<dynamic>> searchSongs(
      String query, {
        int page = 0,
        int limit = 20,
      }) async {
    final data = await _get(
      '/api/search/songs',
      {
        'query': query,
        'page': '$page',
        'limit': '$limit',
      },
    );

    return _extractResults(data);
  }

  // ============================================================
  // ARTIST SEARCH
  // ============================================================

  Future<List<dynamic>> searchArtists(
      String query, {
        int page = 0,
        int limit = 10,
      }) async {
    final data = await _get(
      '/api/search/artists',
      {
        'query': query,
        'page': '$page',
        'limit': '$limit',
      },
    );

    return _extractResults(data);
  }

  // ============================================================
  // PLAYLIST SEARCH
  // ============================================================

  Future<List<dynamic>> searchPlaylists(
      String query, {
        int page = 0,
        int limit = 10,
      }) async {
    final data = await _get(
      '/api/search/playlists',
      {
        'query': query,
        'page': '$page',
        'limit': '$limit',
      },
    );

    return _extractResults(data);
  }

  // ============================================================
  // ALBUM SEARCH
  // ============================================================

  Future<List<dynamic>> searchAlbums(
      String query, {
        int page = 0,
        int limit = 10,
      }) async {
    final data = await _get(
      '/api/search/albums',
      {
        'query': query,
        'page': '$page',
        'limit': '$limit',
      },
    );

    return _extractResults(data);
  }

  // ============================================================
  // GLOBAL SEARCH
  // ============================================================

  Future<dynamic> globalSearch(
      String query,
      ) async {
    return _get(
      '/api/search',
      {
        'query': query,
      },
    );
  }

  // ============================================================
  // ARTIST DETAILS
  // ============================================================

  Future<dynamic> getArtist(
      String artistId, {
        int page = 0,
        int songCount = 30,
        int albumCount = 20,
        String sortBy = 'popularity',
        String sortOrder = 'desc',
      }) async {
    final id = artistId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Artist ID is empty',
      );
    }

    return _get(
      '/api/artists/$id',
      {
        'page': '$page',
        'songCount': '$songCount',
        'albumCount': '$albumCount',
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );
  }

  // ============================================================
  // ARTIST SONGS
  // ============================================================

  Future<dynamic> getArtistSongs(
      String artistId, {
        int page = 0,
        String sortBy = 'popularity',
        String sortOrder = 'desc',
      }) async {
    final id = artistId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Artist ID is empty',
      );
    }

    return _get(
      '/api/artists/$id/songs',
      {
        'page': '$page',
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );
  }

  // ============================================================
  // ARTIST ALBUMS
  // ============================================================

  Future<dynamic> getArtistAlbums(
      String artistId, {
        int page = 0,
        String sortBy = 'popularity',
        String sortOrder = 'desc',
      }) async {
    final id = artistId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Artist ID is empty',
      );
    }

    return _get(
      '/api/artists/$id/albums',
      {
        'page': '$page',
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );
  }

  // ============================================================
  // PLAYLIST DETAILS
  // ============================================================

  Future<dynamic> getPlaylist(
      String playlistId, {
        int page = 0,
        int limit = 50,
      }) async {
    final id = playlistId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Playlist ID is empty',
      );
    }

    return _get(
      '/api/playlists',
      {
        'id': id,
        'page': '$page',
        'limit': '$limit',
      },
    );
  }

  // ============================================================
  // ALBUM DETAILS
  // ============================================================
  // Backend route is GET /api/albums?id=<albumId>.
  // The response contains `songs`, each with its own artwork.

  Future<dynamic> getAlbum(
      String albumId,
      ) async {
    final id = albumId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Album ID is empty',
      );
    }

    return _get(
      '/api/albums',
      {
        'id': id,
      },
    );
  }

  // ============================================================
  // HOME - NEWLY RELEASED
  // ============================================================

  Future<List<dynamic>> getHomeNewReleases() async {
    final data = await _get(
      '/api/search/songs',
      {
        'query': 'newly released songs',
        'page': '0',
        'limit': '20',
      },
    );

    return _extractResults(data);
  }

  // ============================================================
  // HOME - TOP PLAYLISTS
  // ============================================================

  Future<List<dynamic>> getTopPlaylists() async {
    final data = await _get(
      '/api/home/top-playlists',
      {},
    );

    if (data is List) {
      return List<dynamic>.from(data);
    }

    return [];
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<dynamic> _extractResults(
      dynamic data,
      ) {
    if (data is Map) {
      final results = data['results'];

      if (results is List) {
        return List<dynamic>.from(results);
      }
    }

    if (data is List) {
      return List<dynamic>.from(data);
    }

    return [];
  }

  // ============================================================
  // HOME - LIVE HOME MODULES
  // ============================================================

  Future<dynamic> getHome() async {
    return _get(
      '/api/home',
      {},
    );
  }
}
