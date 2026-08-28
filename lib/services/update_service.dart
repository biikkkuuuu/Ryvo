import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String currentVersion = '1.0.0';
  String minimumSupportedVersion = '1.0.0';
  String latestVersion = '1.0.0';
  String updateUrl = '';
  bool isUpdateRequired = false;

  Future<void> initialize() async {
    try {
      // 1. Get exact current app version from pubspec.yaml (e.g., "1.0.0")
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;

      // 2. Set Safe Defaults (Fallback if network fails)
      await _remoteConfig.setDefaults(const {
        'minimum_supported_version': '1.0.0',
        'latest_version': '1.0.0',
        'update_url': '',
      });

      // 3. Configure Remote Config (1 hour fetch interval for production)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1), 
      ));

      // 4. Fetch and Activate
      await _remoteConfig.fetchAndActivate();

      // 5. Read values
      minimumSupportedVersion = _remoteConfig.getString('minimum_supported_version');
      latestVersion = _remoteConfig.getString('latest_version');
      updateUrl = _remoteConfig.getString('update_url');

      // 6. Compare Semantic Versions
      isUpdateRequired = _isVersionOlder(currentVersion, minimumSupportedVersion);
      
    } catch (e) {
      log('Remote Config Fetch Failed. Using safe defaults. Error: $e');
      // On failure, defaults are used. isUpdateRequired remains false if defaults say so.
    }
  }

  /// Semantic version comparison logic (e.g., current: 1.0.0, minimum: 1.0.1 -> returns true)
  bool _isVersionOlder(String current, String minimum) {
    try {
      final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final mParts = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final m = i < mParts.length ? mParts[i] : 0;
        
        if (c < m) return true;  // Current is strictly older
        if (c > m) return false; // Current is newer
      }
      return false; // Exact same version
    } catch (e) {
      log('Version comparison error: $e');
      return false; 
    }
  }
}