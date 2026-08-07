import 'dart:convert';
import 'package:http/http.dart' as http;

class JioSaavnService {
  // USB + adb reverse use kar rahe hain
  static const String baseUrl = "http://10.57.39.212:3000";  Future<List> searchSongs(String query) async {
    final uri = Uri.parse(
      "$baseUrl/api/search/songs?query=${Uri.encodeComponent(query)}",
    );

    try {
      print("========== SEARCH ==========");
      print("REQUEST URL : $uri");

      final response = await http.get(uri);

      print("STATUS CODE : ${response.statusCode}");
      print("RESPONSE BODY : ${response.body}");
      print("============================");

      if (response.statusCode != 200) {
        throw Exception(
          "Search failed (${response.statusCode})",
        );
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      if (json["success"] != true) {
        throw Exception("API returned success=false");
      }

      final data = json["data"];

      if (data == null) {
        return [];
      }

      if (data is List) {
        return data;
      }

      if (data is Map && data["results"] is List) {
        return data["results"];
      }

      return [];
    } catch (e, stackTrace) {
      print("========== SEARCH ERROR ==========");
      print(e);
      print(stackTrace);
      print("==================================");
      rethrow;
    }
  }
}