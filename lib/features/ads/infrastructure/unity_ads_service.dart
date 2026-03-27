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
      return;
    }
    _initAttempted = true;

    final Completer<void> completer = Completer<void>();
    await UnityAds.init(
      gameId: _gameId!,
      testMode: _config.testMode,
      onComplete: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onFailed: (UnityAdsInitializationError _, String message) {
        if (!completer.isCompleted) {
          completer.completeError(StateError(message));
        }
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('Unity Ads init timeout'),
    );
  }

  @override
  Future<AdShowResult> showInterstitialAndWait({
    required Duration timeout,
  }) async {
    if (!_isConfiguredForCurrentPlatform()) {
      return AdShowResult.skipped;
    }

    final String placementId = _interstitialPlacementId!;
    final bool loaded = await _loadAd(
      placementId: placementId,
      timeout: timeout,
    );
    if (!loaded) {
      return AdShowResult.skipped;
    }
    return _showAd(placementId: placementId, timeout: timeout);
  }

  Future<bool> _loadAd({
    required String placementId,
    required Duration timeout,
  }) async {
    final Completer<bool> completer = Completer<bool>();
    await UnityAds.load(
      placementId: placementId,
      onComplete: (_) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onFailed: (_, __, ___) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    return completer.future.timeout(timeout, onTimeout: () => false);
  }

  Future<AdShowResult> _showAd({
    required String placementId,
    required Duration timeout,
  }) async {
    final Completer<AdShowResult> completer = Completer<AdShowResult>();
    await UnityAds.showVideoAd(
      placementId: placementId,
      onComplete: (_) {
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.shown);
        }
      },
      onSkipped: (_) {
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.shown);
        }
      },
      onFailed: (_, __, ___) {
        if (!completer.isCompleted) {
          completer.complete(AdShowResult.failed);
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () => AdShowResult.failed,
    );
  }

  bool _isConfiguredForCurrentPlatform() {
    return _isMobilePlatform &&
        _gameId != null &&
        _interstitialPlacementId != null;
  }

  String? get _gameId => _config.gameIdForPlatform(defaultTargetPlatform);

  String? get _interstitialPlacementId =>
      _config.interstitialPlacementIdForPlatform(defaultTargetPlatform);
}
