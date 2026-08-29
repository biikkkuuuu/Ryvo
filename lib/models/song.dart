class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final String downloadUrl;
  final String? localPath;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    this.downloadUrl = '',
    this.localPath,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    String artist = "Unknown";

    if (json["artists"] != null &&
        json["artists"]["primary"] != null &&
        json["artists"]["primary"] is List &&
        json["artists"]["primary"].isNotEmpty) {
      artist = json["artists"]["primary"][0]["name"] ?? "Unknown";
    } else if (json["artist"] != null) {
      artist = json["artist"].toString();
    }

    String image = "";

    if (json["image"] != null &&
        json["image"] is List &&
        json["image"].isNotEmpty) {
      image = json["image"].last["url"] ?? "";
    } else if (json["thumbnail"] != null) {
      image = json["thumbnail"].toString();
    }

    return Song(
      id: json["id"] ?? "",
      title: json["name"] ?? json["title"] ?? "",
      artist: artist,
      thumbnail: image,
      downloadUrl: json["downloadUrl"] ?? "",
      localPath: json["localPath"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": title,
      "title": title,
      "artist": artist,
      "thumbnail": thumbnail,
      "downloadUrl": downloadUrl,
      "localPath": localPath,
    };
  }
}