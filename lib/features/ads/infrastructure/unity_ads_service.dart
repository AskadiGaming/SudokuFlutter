import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../application/ad_service.dart';
import 'unity_ads_config.dart';

class UnityAdsService implements AdService {
  UnityAdsService({required UnityAdsConfig config}) : _config = config;

  final UnityAdsConfig _config;

  bool _initAttempted = false;

  @override
  bool get supportsCurrentPlatform => _isMobilePlatform;

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() async {
    if (_initAttempted || !_isConfiguredForCurrentPlatform()) {
      final String configIssue = _configurationIssueDescription();
      debugPrint(
        '[unity.ads] initialize skipped: '
        'initAttempted=$_initAttempted, '
        'isConfigured=${_isConfiguredForCurrentPlatform()}, '
        'platform=$defaultTargetPlatform, '
        'isMobile=$_isMobilePlatform, '
        'hasGameId=${_gameId != null}, '
        'hasInterstitialPlacementId=${_interstitialPlacementId != null}, '
        'issue=$configIssue',
      );
      return;
    }
    _initAttempted = true;
    debugPrint(
      '[unity.ads] initialize start: '
      'platform=$defaultTargetPlatform, '
      'testMode=${_config.testMode}, '
      'gameId=$_gameId',
    );

    final Completer<void> completer = Completer<void>();
    await UnityAds.init(
      gameId: _gameId!,
      testMode: _config.testMode,
      onComplete: () {
        debugPrint('[unity.ads] initialize complete');
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onFailed: (UnityAdsInitializationError error, String message) {
        debugPrint(
          '[unity.ads] initialize failed: error=$error, message=$message',
        );
        if (!completer.isCompleted) {
          completer.completeError(StateError(message));
        }
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('[unity.ads] initialize timeout after 5000ms');
        throw TimeoutException('Unity Ads init timeout');
      },
    );
  }

  @override
  Future<AdShowResult> showInterstitialAndWait({
    required Duration loadTimeout,
  }) async {
    if (!_isConfiguredForCurrentPlatform()) {
      final String configIssue = _configurationIssueDescription();
      debugPrint(
        '[unity.ads] show skipped: '
        'platform=$defaultTargetPlatform, '
        'isMobile=$_isMobilePlatform, '
        'hasGameId=${_gameId != null}, '
        'hasInterstitialPlacementId=${_interstitialPlacementId != null}, '
        'issue=$configIssue',
      );
      return AdShowResult.skipped;
    }

    final String placementId = _interstitialPlacementId!;
    debugPrint(
      '[unity.ads] load start: placementId=$placementId, '
      'timeoutMs=${loadTimeout.inMilliseconds}',
    );
    final bool loaded = await _loadAd(
      placementId: placementId,
      timeout: loadTimeout,
    );
    if (!loaded) {
      debugPrint(
        '[unity.ads] load returned false for placementId=$placementId',
      );
      return AdShowResult.skipped;
    }
    debugPrint('[unity.ads] load succeeded for placementId=$placementId');
    debugPrint(
      '[unity.ads] show start: placementId=$placementId, '
      'waiting for Unity completion callback without fixed timeout',
    );
    return _showAd(placementId: placementId);
  }

  Future<bool> _loadAd({
    required String placementId,
    required Duration timeout,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    await UnityAds.load(
      placementId: placementId,
      onComplete: (_) {
        debugPrint('[unity.ads] load complete: placementId=$placementId');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onFailed: (error, message, placement) {
        debugPrint(
          '[unity.ads] load failed: placementId=$placementId, '
          'placement=$placement, error=$error, message=$message',
        );
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint(
          '[unity.ads] load timeout: placementId=$placementId, '
          'timeoutMs=${timeout.inMilliseconds}',
        );
        return false;
      },
    );
  }

  Future<AdShowResult> _showAd({required String placementId}) async {
    final Completer<AdShowResult> completer = Completer<AdShowResult>();
    await UnityAds.showVideoAd(
      placementId: placementId,
      onComplete: (placement) {
        debugPrint('[unity.ads] show complete: placement=$placement');
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.shown);
        }
      },
      onSkipped: (placement) {
        debugPrint('[unity.ads] show skipped by SDK: placement=$placement');
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.shown);
        }
      },
      onFailed: (error, message, placement) {
        debugPrint(
          '[unity.ads] show failed: placement=$placement, '
          'error=$error, message=$message',
        );
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.failed);
        }
      },
    );

    return completer.future;
  }

  bool _isConfiguredForCurrentPlatform() {
    return _isMobilePlatform &&
        _gameId != null &&
        _interstitialPlacementId != null;
  }

  String? get _gameId => _config.gameIdForPlatform(defaultTargetPlatform);

  String? get _interstitialPlacementId =>
      _config.interstitialPlacementIdForPlatform(defaultTargetPlatform);

  String _configurationIssueDescription() {
    if (!_isMobilePlatform) {
      return 'unsupported platform';
    }

    final List<String> missingKeys = <String>[
      ..._missingGameIdDefineKeys(),
      ..._missingInterstitialDefineKeys(),
    ];
    if (missingKeys.isEmpty) {
      return 'already initialized or configuration unavailable for unknown reason';
    }
    return 'missing config values for: ${missingKeys.join(', ')} '
        '(set via dart-define or local debug config)';
  }

  List<String> _missingGameIdDefineKeys() {
    if (_gameId != null) {
      return const <String>[];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return <String>[
          kReleaseMode
              ? 'UNITY_ADS_ANDROID_GAME_ID_RELEASE'
              : 'UNITY_ADS_ANDROID_GAME_ID_DEBUG',
        ];
      case TargetPlatform.iOS:
        return <String>[
          kReleaseMode
              ? 'UNITY_ADS_IOS_GAME_ID_RELEASE'
              : 'UNITY_ADS_IOS_GAME_ID_DEBUG',
        ];
      default:
        return const <String>[];
    }
  }

  List<String> _missingInterstitialDefineKeys() {
    if (_interstitialPlacementId != null) {
      return const <String>[];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return <String>[
          kReleaseMode
              ? 'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_RELEASE'
              : 'UNITY_ADS_ANDROID_INTERSTITIAL_PLACEMENT_ID_DEBUG',
        ];
      case TargetPlatform.iOS:
        return <String>[
          kReleaseMode
              ? 'UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_RELEASE'
              : 'UNITY_ADS_IOS_INTERSTITIAL_PLACEMENT_ID_DEBUG',
        ];
      default:
        return const <String>[];
    }
  }
}
