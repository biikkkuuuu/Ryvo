import 'package:music_app/models/song.dart';
import 'package:music_app/services/jiosaavn_service.dart';

class MusicRepository {
  final JioSaavnService _service = JioSaavnService();

  Future<List<Song>> search(String query) async {
    final results = await _service.searchSongs(query);

    return results.map((item) {
      String artist = "Unknown";

      if (item["artists"] != null &&
          item["artists"]["primary"] != null &&
          item["artists"]["primary"] is List &&
          item["artists"]["primary"].isNotEmpty) {
        artist = item["artists"]["primary"][0]["name"] ?? "Unknown";
      }

      String image = "";

      if (item["image"] != null &&
          item["image"] is List &&
          item["image"].isNotEmpty) {
        image = item["image"].last["url"] ?? "";
      }

      return Song(
        id: item["id"] ?? "",
        title: item["name"] ?? "",
        artist: artist,
        thumbnail: image,
      );
    }).toList();
  }
}