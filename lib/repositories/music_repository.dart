import 'package:music_app/models/song.dart';
import 'package:music_app/services/youtube_music_service.dart';

class MusicRepository {
  final YouTubeMusicService _service = YouTubeMusicService();

  Future<List<Song>> search(String query) async {
    await _service.init();

    final List<dynamic> results = await _service.searchSongs(query);

    final List<Song> songs = [];

    for (final item in results) {
      if (item is Map<String, dynamic>) {
        songs.add(
          Song(
            id: item["videoId"] ?? "",
            title: item["title"] ?? "",
            artist: item["artists"] != null &&
                item["artists"] is List &&
                item["artists"].isNotEmpty
                ? item["artists"][0]["name"]
                : "Unknown",
            thumbnail: item["thumbnails"] != null &&
                item["thumbnails"] is List &&
                item["thumbnails"].isNotEmpty
                ? item["thumbnails"].last["url"]
                : "",
          ),
        );
      }
    }

    return songs;
  }
}