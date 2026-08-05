import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';

class YouTubeMusicService {
  late final YTMusic _ytMusic;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _ytMusic = await YTMusic.create();
    _initialized = true;
  }

  Future<List<dynamic>> searchSongs(String query) async {
    await init();

    try {
      final results = await _ytMusic.search(query);
      return results;
    } catch (e) {
      throw Exception("Search failed: $e");
    }
  }

  void dispose() {
    if (_initialized) {
      _ytMusic.close();
    }
  }
}