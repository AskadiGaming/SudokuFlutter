import 'package:flutter/foundation.dart';

import 'ad_service.dart';
import 'analytics_service.dart';

enum HintAdResult { granted, unavailable, failed }

class ShowAdForHintUseCase {
  ShowAdForHintUseCase({
    required this.adService,
    required this.analyticsService,
    this.loadTimeout = const Duration(seconds: 8),
  });

  final AdService adService;
  final AnalyticsService analyticsService;
  final Duration loadTimeout;

  bool get supportsCurrentPlatform => adService.supportsCurrentPlatform;

  Future<HintAdResult> execute() async {
    debugPrint(
      '[hint.ad] request started: '
      'supportsCurrentPlatform=${adService.supportsCurrentPlatform}, '
      'loadTimeoutMs=${loadTimeout.inMilliseconds}',
    );
    analyticsService.logEvent('ad_for_hint_requested');

    if (!adService.supportsCurrentPlatform) {
      debugPrint('[hint.ad] unavailable: unsupported platform');
      analyticsService.logEvent(
        'ad_for_hint_unavailable',
        parameters: <String, Object?>{'reason': 'unsupported_platform'},
      );
      return HintAdResult.unavailable;
    }

    try {
      debugPrint('[hint.ad] initializing ad service');
      await adService.initialize();
      debugPrint('[hint.ad] ad service initialize() returned');
    } catch (_) {
      debugPrint('[hint.ad] initialization failed');
      analyticsService.logEvent(
        'ad_for_hint_failed',
        parameters: <String, Object?>{'reason': 'initialize'},
      );
      return HintAdResult.failed;
    }

    final AdShowResult result = await adService.showInterstitialAndWait(
      loadTimeout: loadTimeout,
    );
    debugPrint('[hint.ad] showInterstitialAndWait result=$result');
    switch (result) {
      case AdShowResult.shown:
        debugPrint('[hint.ad] hint granted');
        analyticsService.logEvent('ad_for_hint_granted');
        return HintAdResult.granted;
      case AdShowResult.skipped:
        debugPrint('[hint.ad] unavailable: ad not ready or timeout');
        analyticsService.logEvent(
          'ad_for_hint_unavailable',
          parameters: <String, Object?>{'reason': 'not_ready_or_timeout'},
        );
        return HintAdResult.unavailable;
      case AdShowResult.failed:
        debugPrint('[hint.ad] failed while showing ad');
        analyticsService.logEvent('ad_for_hint_failed');
        return HintAdResult.failed;
    }
  }
}
