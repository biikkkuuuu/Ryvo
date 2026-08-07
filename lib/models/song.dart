class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    String artist = "Unknown";

    if (json["artists"] != null &&
        json["artists"]["primary"] != null &&
        json["artists"]["primary"] is List &&
        json["artists"]["primary"].isNotEmpty) {
      artist = json["artists"]["primary"][0]["name"] ?? "Unknown";
    }

    String image = "";

    if (json["image"] != null &&
        json["image"] is List &&
        json["image"].isNotEmpty) {
      image = json["image"].last["url"] ?? "";
    }

    return Song(
      id: json["id"] ?? "",
      title: json["name"] ?? "",
      artist: artist,
      thumbnail: image,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": title,
      "artist": artist,
      "thumbnail": thumbnail,
    };
  }
}