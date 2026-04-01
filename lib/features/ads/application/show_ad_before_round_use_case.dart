import '../domain/ad_policy.dart';
import 'ad_round_counter_store.dart';
import 'ad_service.dart';
import 'analytics_service.dart';

class ShowAdBeforeRoundUseCase {
  ShowAdBeforeRoundUseCase({
    required this.adService,
    required this.analyticsService,
    required this.roundCounterStore,
    required this.policy,
    this.timeout = const Duration(seconds: 8),
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final AdService adService;
  final AnalyticsService analyticsService;
  final AdRoundCounterStore roundCounterStore;
  final AdPolicy policy;
  final Duration timeout;
  final DateTime Function() _nowProvider;

  int? _roundsSinceLastAd;
  DateTime? _lastAdShownAt;

  Future<AdShowResult> execute() async {
    final int roundsSinceLastAdBefore = await _loadRoundsSinceLastAd();
    analyticsService.logEvent(
      'ad_before_round_requested',
      parameters: <String, Object?>{
        'rounds_since_last_ad_before': roundsSinceLastAdBefore,
        'target_interval': policy.minRoundsBetweenAds,
      },
    );

    if (!adService.supportsCurrentPlatform) {
      final int roundsSinceLastAdAfter = await _incrementAndPersistCounter();
      analyticsService.logEvent(
        'ad_before_round_skipped',
        parameters: <String, Object?>{
          'reason': 'unsupported_platform',
          'rounds_since_last_ad_before': roundsSinceLastAdBefore,
          'rounds_since_last_ad_after': roundsSinceLastAdAfter,
          'target_interval': policy.minRoundsBetweenAds,
        },
      );
      return AdShowResult.skipped;
    }

    final DateTime now = _nowProvider();
    if (!policy.shouldShowAd(
      now: now,
      roundsSinceLastAd: roundsSinceLastAdBefore,
      lastAdShownAt: _lastAdShownAt,
    )) {
      final int roundsSinceLastAdAfter = await _incrementAndPersistCounter();
      analyticsService.logEvent(
        'ad_before_round_skipped',
        parameters: <String, Object?>{
          'reason': 'policy',
          'rounds_since_last_ad_before': roundsSinceLastAdBefore,
          'rounds_since_last_ad_after': roundsSinceLastAdAfter,
          'target_interval': policy.minRoundsBetweenAds,
        },
      );
      return AdShowResult.skipped;
    }

    try {
      await adService.initialize();
    } catch (_) {
      final int roundsSinceLastAdAfter = await _incrementAndPersistCounter();
      analyticsService.logEvent(
        'ad_before_round_failed',
        parameters: <String, Object?>{
          'reason': 'initialize',
          'rounds_since_last_ad_before': roundsSinceLastAdBefore,
          'rounds_since_last_ad_after': roundsSinceLastAdAfter,
          'target_interval': policy.minRoundsBetweenAds,
        },
      );
      return AdShowResult.failed;
    }

    final AdShowResult result = await adService.showInterstitialAndWait(
      timeout: timeout,
    );

    switch (result) {
      case AdShowResult.shown:
        _lastAdShownAt = _nowProvider();
        await _setAndPersistCounter(0);
        analyticsService.logEvent(
          'ad_before_round_shown',
          parameters: <String, Object?>{
            'rounds_since_last_ad_before': roundsSinceLastAdBefore,
            'rounds_since_last_ad_after': 0,
            'target_interval': policy.minRoundsBetweenAds,
          },
        );
        break;
      case AdShowResult.skipped:
        final int roundsSinceLastAdAfter = await _incrementAndPersistCounter();
        analyticsService.logEvent(
          'ad_before_round_skipped',
          parameters: <String, Object?>{
            'reason': 'not_ready_or_timeout',
            'rounds_since_last_ad_before': roundsSinceLastAdBefore,
            'rounds_since_last_ad_after': roundsSinceLastAdAfter,
            'target_interval': policy.minRoundsBetweenAds,
          },
        );
        break;
      case AdShowResult.failed:
        final int roundsSinceLastAdAfter = await _incrementAndPersistCounter();
        analyticsService.logEvent(
          'ad_before_round_failed',
          parameters: <String, Object?>{
            'rounds_since_last_ad_before': roundsSinceLastAdBefore,
            'rounds_since_last_ad_after': roundsSinceLastAdAfter,
            'target_interval': policy.minRoundsBetweenAds,
          },
        );
        break;
    }

    return result;
  }

  Future<int> _loadRoundsSinceLastAd() async {
    final int? cachedValue = _roundsSinceLastAd;
    if (cachedValue != null) {
      return cachedValue;
    }

    final int persistedValue = await roundCounterStore.readRoundsSinceLastAd();
    _roundsSinceLastAd = persistedValue;
    return persistedValue;
  }

  Future<int> _incrementAndPersistCounter() async {
    final int currentValue = await _loadRoundsSinceLastAd();
    final int nextValue = currentValue + 1;
    await _setAndPersistCounter(nextValue);
    return nextValue;
  }

  Future<void> _setAndPersistCounter(int value) async {
    _roundsSinceLastAd = value;
    await roundCounterStore.writeRoundsSinceLastAd(value);
  }
}
