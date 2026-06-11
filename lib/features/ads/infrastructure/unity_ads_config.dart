import 'package:flutter/foundation.dart';

import 'unity_ads_local_config.dart';

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
    const String androidGameIdDebugFromEnv = String.fromEnvironment(
      'UNITY_ADS_ANDROID_GAME_ID_DEBUG',
    );
    const String androidInterstitialPlacementIdDebugFromEnv =
        String.fromEnvironment(
          'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG',
        );
    const String iosGameIdDebugFromEnv = String.fromEnvironment(
      'UNITY_ADS_IOS_GAME_ID_DEBUG',
    );
    const String iosInterstitialPlacementIdDebugFromEnv =
        String.fromEnvironment('UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG');
    const String androidGameIdReleaseFromEnv = String.fromEnvironment(
      'UNITY_ADS_ANDROID_GAME_ID_RELEASE',
    );
    const String androidInterstitialPlacementIdReleaseFromEnv =
        String.fromEnvironment(
          'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE',
        );
    const String iosGameIdReleaseFromEnv = String.fromEnvironment(
      'UNITY_ADS_IOS_GAME_ID_RELEASE',
    );
    const String iosInterstitialPlacementIdReleaseFromEnv =
        String.fromEnvironment(
          'UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE',
        );

    return UnityAdsConfig(
      androidGameIdDebug: _resolveFallback(
        environmentValue: androidGameIdDebugFromEnv,
        localValue: UNITY_ADS_LOCAL_ANDROID_GAME_ID_DEBUG,
      ),
      androidGameIdRelease: _resolveFallback(
        environmentValue: androidGameIdReleaseFromEnv,
        localValue: UNITY_ADS_LOCAL_ANDROID_GAME_ID_RELEASE,
      ),
      androidInterstitialPlacementIdDebug: _resolveFallback(
        environmentValue: androidInterstitialPlacementIdDebugFromEnv,
        localValue: UNITY_ADS_LOCAL_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG,
      ),
      androidInterstitialPlacementIdRelease: _resolveFallback(
        environmentValue: androidInterstitialPlacementIdReleaseFromEnv,
        localValue: UNITY_ADS_LOCAL_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE,
      ),
      iosGameIdDebug: _resolveFallback(
        environmentValue: iosGameIdDebugFromEnv,
        localValue: UNITY_ADS_LOCAL_IOS_GAME_ID_DEBUG,
      ),
      iosGameIdRelease: _resolveFallback(
        environmentValue: iosGameIdReleaseFromEnv,
        localValue: UNITY_ADS_LOCAL_IOS_GAME_ID_RELEASE,
      ),
      iosInterstitialPlacementIdDebug: _resolveFallback(
        environmentValue: iosInterstitialPlacementIdDebugFromEnv,
        localValue: UNITY_ADS_LOCAL_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG,
      ),
      iosInterstitialPlacementIdRelease: _resolveFallback(
        environmentValue: iosInterstitialPlacementIdReleaseFromEnv,
        localValue: UNITY_ADS_LOCAL_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE,
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

  static String _resolveFallback({
    required String environmentValue,
    required String localValue,
  }) {
    if (environmentValue.trim().isNotEmpty) {
      return environmentValue;
    }
    if (localValue.trim().isNotEmpty) {
      return localValue;
    }
    return environmentValue;
  }
}
