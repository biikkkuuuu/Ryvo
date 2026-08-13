import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LyricsResult {
  final String plainLyrics;
  final String? syncedLyrics;

  const LyricsResult({required this.plainLyrics, this.syncedLyrics});
}

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';

  Future<LyricsResult?> getLyrics({
    required String title,
    required String artist,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/get',
      ).replace(queryParameters: {'track_name': title, 'artist_name': artist});

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'RYVO Music App', 'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return null;
      }

      final plainLyrics = data['plainLyrics']?.toString().trim() ?? '';

      final syncedLyrics = data['syncedLyrics']?.toString().trim();

      if (plainLyrics.isEmpty &&
          (syncedLyrics == null || syncedLyrics.isEmpty)) {
        return null;
      }

      return LyricsResult(plainLyrics: plainLyrics, syncedLyrics: syncedLyrics);
    } catch (e) {
      debugPrint('Lyrics Error: $e');
      return null;
    }
  }
}
