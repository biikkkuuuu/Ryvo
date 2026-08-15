import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_app/app/app.dart';
import 'package:music_app/firebase_options.dart';
import 'package:music_app/services/audio_service.dart' as ryvo;
import 'package:music_app/services/ryvo_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // RYVO AUDIO SERVICE
  // ============================================================

  final ryvoAudioService = ryvo.AudioService();

  await audio_service.AudioService.init(
    builder: () => RyvoAudioHandler(
      audioService: ryvoAudioService,
    ),
    config: audio_service.AudioServiceConfig(
      androidNotificationChannelId:
      'com.example.music_app.channel.audio',
      androidNotificationChannelName:
      'RYVO Music Playback',
      androidNotificationChannelDescription:
      'Controls for RYVO music playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // ============================================================
  // APP
  // ============================================================

  runApp(
    const ProviderScope(
      child: RyvoApp(),
    ),
  );
}