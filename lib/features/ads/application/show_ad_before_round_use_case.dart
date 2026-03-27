import '../domain/ad_policy.dart';
import 'ad_service.dart';
import 'analytics_service.dart';

class ShowAdBeforeRoundUseCase {
  ShowAdBeforeRoundUseCase({
    required this.adService,
    required this.analyticsService,
    required this.policy,
    this.timeout = const Duration(seconds: 8),
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  final AdService adService;
  final AnalyticsService analyticsService;
  final AdPolicy policy;
  final Duration timeout;
  final DateTime Function() _nowProvider;

  int _roundsSinceLastAd = 1;
  DateTime? _lastAdShownAt;

  Future<AdShowResult> execute() async {
    analyticsService.logEvent('ad_before_round_requested');

    if (!adService.supportsCurrentPlatform) {
      analyticsService.logEvent(
        'ad_before_round_skipped',
        parameters: <String, Object?>{'reason': 'unsupported_platform'},
      );
      _roundsSinceLastAd += 1;
      return AdShowResult.skipped;
    }

    final DateTime now = _nowProvider();
    if (!policy.shouldShowAd(
      now: now,
      roundsSinceLastAd: _roundsSinceLastAd,
      lastAdShownAt: _lastAdShownAt,
    )) {
      analyticsService.logEvent(
        'ad_before_round_skipped',
        parameters: <String, Object?>{'reason': 'policy'},
      );
      _roundsSinceLastAd += 1;
      return AdShowResult.skipped;
    }

    try {
      await adService.initialize();
    } catch (_) {
      analyticsService.logEvent(
        'ad_before_round_failed',
        parameters: <String, Object?>{'reason': 'initialize'},
      );
      _roundsSinceLastAd += 1;
      return AdShowResult.failed;
    }

    final AdShowResult result = await adService.showInterstitialAndWait(
      timeout: timeout,
    );

    switch (result) {
      case AdShowResult.shown:
        analyticsService.logEvent('ad_before_round_shown');
        _lastAdShownAt = _nowProvider();
        _roundsSinceLastAd = 0;
        break;
      case AdShowResult.skipped:
        analyticsService.logEvent(
          'ad_before_round_skipped',
          parameters: <String, Object?>{'reason': 'not_ready_or_timeout'},
        );
        _roundsSinceLastAd += 1;
        break;
      case AdShowResult.failed:
        analyticsService.logEvent('ad_before_round_failed');
        _roundsSinceLastAd += 1;
        break;
    }

    return result;
  }
}
