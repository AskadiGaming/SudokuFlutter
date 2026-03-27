import 'package:flutter/foundation.dart';

class UnityAdsConfig {
  const UnityAdsConfig({
    required this.androidGameIdDebug,
    required this.androidGameIdRelease,
    required this.androidInterstitialPlacementIdDebug,
    required this.androidInterstitialPlacementIdRelease,
    required this.iosGameIdDebug,
    required this.iosGameIdRelease,
    required this.iosInterstitialPlacementIdDebug,
    required this.iosInterstitialPlacementIdRelease,
    required this.testMode,
  });

  factory UnityAdsConfig.fromEnvironment() {
    const bool forcedTestMode = bool.fromEnvironment(
      'UNITY_ADS_TEST_MODE',
      defaultValue: false,
    );
    return UnityAdsConfig(
      androidGameIdDebug: const String.fromEnvironment(
        'UNITY_ADS_ANDROID_GAME_ID_DEBUG',
      ),
      androidGameIdRelease: const String.fromEnvironment(
        'UNITY_ADS_ANDROID_GAME_ID_RELEASE',
      ),
      androidInterstitialPlacementIdDebug: const String.fromEnvironment(
        'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG',
      ),
      androidInterstitialPlacementIdRelease: const String.fromEnvironment(
        'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE',
      ),
      iosGameIdDebug: const String.fromEnvironment(
        'UNITY_ADS_IOS_GAME_ID_DEBUG',
      ),
      iosGameIdRelease: const String.fromEnvironment(
        'UNITY_ADS_IOS_GAME_ID_RELEASE',
      ),
      iosInterstitialPlacementIdDebug: const String.fromEnvironment(
        'UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG',
      ),
      iosInterstitialPlacementIdRelease: const String.fromEnvironment(
        'UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE',
      ),
      testMode: kDebugMode || forcedTestMode,
    );
  }

  final String androidGameIdDebug;
  final String androidGameIdRelease;
  final String androidInterstitialPlacementIdDebug;
  final String androidInterstitialPlacementIdRelease;
  final String iosGameIdDebug;
  final String iosGameIdRelease;
  final String iosInterstitialPlacementIdDebug;
  final String iosInterstitialPlacementIdRelease;
  final bool testMode;

  String? gameIdForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return _resolveByBuildMode(androidGameIdDebug, androidGameIdRelease);
      case TargetPlatform.iOS:
        return _resolveByBuildMode(iosGameIdDebug, iosGameIdRelease);
      default:
        return null;
    }
  }

  String? interstitialPlacementIdForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return _resolveByBuildMode(
          androidInterstitialPlacementIdDebug,
          androidInterstitialPlacementIdRelease,
        );
      case TargetPlatform.iOS:
        return _resolveByBuildMode(
          iosInterstitialPlacementIdDebug,
          iosInterstitialPlacementIdRelease,
        );
      default:
        return null;
    }
  }

  String? _resolveByBuildMode(String debugValue, String releaseValue) {
    final String raw = kReleaseMode ? releaseValue : debugValue;
    if (raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }
}
