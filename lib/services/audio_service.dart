import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  // Same Wi-Fi IP
  static const String baseUrl = "http://10.57.39.212:3000";

  Future<void> playSong(String songId) async {
    try {
      print("========== RYVO ==========");
      print("Song ID : $songId");

      final response = await http.get(
        Uri.parse("$baseUrl/api/songs/$songId"),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "API Error : ${response.statusCode}",
        );
      }

      final json = jsonDecode(response.body);

      if (json["success"] != true) {
        throw Exception("API returned success=false");
      }

      final List songs = json["data"];

      if (songs.isEmpty) {
        throw Exception("Song not found");
      }

      final song = songs.first;

      final List urls = song["downloadUrl"];

      if (urls.isEmpty) {
        throw Exception("Download URL missing");
      }

      String audioUrl = "";

      for (final item in urls) {
        if (item["quality"] == "320kbps") {
          audioUrl = item["url"];
          break;
        }
      }

      if (audioUrl.isEmpty) {
        audioUrl = urls.last["url"];
      }

      print(audioUrl);

      await player.setUrl(audioUrl);

      await player.play();

      print("Playing...");
      print("==========================");
    } catch (e, s) {
      print("========== ERROR ==========");
      print(e);
      print(s);
      print("===========================");
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  // ===== Streams =====

  Stream<Duration> get positionStream => player.positionStream;

  Stream<Duration?> get durationStream => player.durationStream;

  Duration get currentPosition => player.position;

  Duration? get totalDuration => player.duration;

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  // ===================

  Future<void> dispose() async {
    await player.dispose();
  }

  AudioPlayer get audioPlayer => player;
}