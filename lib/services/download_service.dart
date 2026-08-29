import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app/models/song.dart';
import 'package:http/http.dart' as http;

class DownloadService {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final Dio _dio = Dio();
  
  // Maps songId -> progress percentage (0.0 to 1.0)
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});
  
  // LIVE Reactive List - UI automatically updates when this changes!
  final ValueNotifier<List<Song>> downloadedSongsNotifier = ValueNotifier([]);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('ryvo_downloads') ?? [];
      final loaded = saved.map((e) => Song.fromJson(jsonDecode(e))).toList();
      
      // Cleanup missing or corrupted files automatically
      bool needsSave = false;
      loaded.removeWhere((song) {
        if (song.localPath == null || !File(song.localPath!).existsSync()) {
          needsSave = true;
          return true;
        }
        return false;
      });
      
      downloadedSongsNotifier.value = loaded;
      if (needsSave) await _save();
      
      debugPrint('RYVO DOWNLOADS: Loaded ${loaded.length} offline songs.');
    } catch (e) {
      debugPrint('RYVO DOWNLOADS INIT ERROR: $e');
    }
  }

  bool isDownloaded(String id) => downloadedSongsNotifier.value.any((s) => s.id == id);
  
  String? getLocalPath(String id) {
    try {
      return downloadedSongsNotifier.value.firstWhere((s) => s.id == id).localPath;
    } catch (e) {
      return null;
    }
  }

  List<Song> get downloadedSongs => List.unmodifiable(downloadedSongsNotifier.value);

  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id) || downloadProgress.value.containsKey(song.id)) return;

    downloadProgress.value = {...downloadProgress.value, song.id: 0.0};

    try {
      String finalUrl = song.downloadUrl;

      // Robust URL Extraction (Failsafe)
      if (finalUrl.isEmpty) {
        final response = await http.get(Uri.parse('https://jiosaavn-api-main-taupe.vercel.app/api/songs/${song.id}'));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['success'] == true && json['data'] != null && json['data'] is List && json['data'].isNotEmpty) {
            final urls = json['data'][0]['downloadUrl'];
            if (urls != null && urls is List && urls.isNotEmpty) {
              for (final u in urls) {
                if (u['quality'] == '320kbps') {
                  finalUrl = u['url'].toString();
                  break;
                }
              }
              if (finalUrl.isEmpty) finalUrl = urls.last['url'].toString();
            }
          }
        }
      }

      if (finalUrl.isEmpty) throw Exception('No download URL found on backend.');

      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${song.id}.mp3';

      await _dio.download(
        finalUrl,
        savePath,
        onReceiveProgress: (rcv, total) {
          if (total != -1) {
            downloadProgress.value = {...downloadProgress.value, song.id: rcv / total};
          }
        },
      );

      final downloadedSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
        downloadUrl: finalUrl,
        localPath: savePath,
      );

      // LIVE UPDATE: Triggers the UI instantly!
      final newList = List<Song>.from(downloadedSongsNotifier.value);
      newList.insert(0, downloadedSong);
      downloadedSongsNotifier.value = newList;

      await _save();
      debugPrint('RYVO DOWNLOADS: Successfully saved ${song.title}');
    } catch (e) {
      debugPrint('RYVO DOWNLOAD FAILED: $e');
    } finally {
      // Remove from progress tracker
      final newProg = Map<String, double>.from(downloadProgress.value);
      newProg.remove(song.id);
      downloadProgress.value = newProg;
    }
  }

  Future<void> deleteDownload(String id) async {
    final path = getLocalPath(id);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    
    // LIVE UPDATE: Removes from UI instantly
    final newList = List<Song>.from(downloadedSongsNotifier.value);
    newList.removeWhere((s) => s.id == id);
    downloadedSongsNotifier.value = newList;

    await _save();
    debugPrint('RYVO DOWNLOADS: Deleted song $id');
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = downloadedSongsNotifier.value.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList('ryvo_downloads', data);
  }
}