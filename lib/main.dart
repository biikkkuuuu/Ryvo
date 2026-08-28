import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:music_app/app/app.dart';
import 'package:music_app/firebase_options.dart';
import 'package:music_app/services/audio_service.dart' as ryvo;
import 'package:music_app/services/ryvo_audio_handler.dart';

// Import our new Force Update files
import 'package:music_app/services/update_service.dart';
import 'package:music_app/features/update/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // FORCE UPDATE CHECK (Remote Config)
  // ============================================================
  
  final updateService = UpdateService();
  await updateService.initialize();

  // ============================================================
  // RYVO AUDIO SERVICE
  // ============================================================

  final ryvoAudioService = ryvo.AudioService();

  await audio_service.AudioService.init(
    builder: () => RyvoAudioHandler(
      audioService: ryvoAudioService,
    ),
    config: const audio_service.AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_app.channel.audio',
      androidNotificationChannelName: 'RYVO Music Playback',
      androidNotificationChannelDescription: 'Controls for RYVO music playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // ============================================================
  // APP LAUNCH GATEKEEPER
  // ============================================================

  if (updateService.isUpdateRequired) {
    // HARD BLOCK: Bypass Riverpod and RyvoApp completely.
    // Shows only the Update Required Screen.
    runApp(
      MaterialApp(
        title: 'RYVO Update',
        debugShowCheckedModeBanner: false,
        home: UpdateRequiredScreen(
          currentVersion: updateService.currentVersion,
          latestVersion: updateService.latestVersion,
          updateUrl: updateService.updateUrl,
        ),
      ),
    );
  } else {
    // Normal App Flow
    runApp(
      const ProviderScope(
        child: RyvoApp(),
      ),
    );
  }
}