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
    return Song(
      id: json['videoId'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': id,
      'title': title,
      'artist': artist,
      'thumbnail': thumbnail,
    };
  }
}