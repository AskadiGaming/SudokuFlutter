import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/ads/application/ad_service.dart';
import 'package:hello_world_app/features/ads/application/analytics_service.dart';
import 'package:hello_world_app/features/ads/application/show_ad_for_hint_use_case.dart';

void main() {
  test('returns unavailable when platform is unsupported', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: false,
    );
    final ShowAdForHintUseCase useCase = ShowAdForHintUseCase(
      adService: adService,
      analyticsService: _FakeAnalyticsService(),
    );

    final HintAdResult result = await useCase.execute();

    expect(result, HintAdResult.unavailable);
    expect(adService.initializeCalls, 0);
    expect(adService.showCalls, 0);
  });

  test('returns granted when ad is shown', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: true,
      showResult: AdShowResult.shown,
    );
    final ShowAdForHintUseCase useCase = ShowAdForHintUseCase(
      adService: adService,
      analyticsService: _FakeAnalyticsService(),
    );

    final HintAdResult result = await useCase.execute();

    expect(result, HintAdResult.granted);
    expect(adService.initializeCalls, 1);
    expect(adService.showCalls, 1);
  });

  test('returns failed when initialization throws', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: true,
      throwOnInitialize: true,
    );
    final ShowAdForHintUseCase useCase = ShowAdForHintUseCase(
      adService: adService,
      analyticsService: _FakeAnalyticsService(),
    );

    final HintAdResult result = await useCase.execute();

    expect(result, HintAdResult.failed);
    expect(adService.initializeCalls, 1);
    expect(adService.showCalls, 0);
  });
}

class _FakeAdService implements AdService {
  _FakeAdService({
    required this.supportsCurrentPlatform,
    this.showResult = AdShowResult.skipped,
    this.throwOnInitialize = false,
  });

  @override
  final bool supportsCurrentPlatform;
  final AdShowResult showResult;
  final bool throwOnInitialize;

  int initializeCalls = 0;
  int showCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    if (throwOnInitialize) {
      throw StateError('init failed');
    }
  }

  @override
  Future<AdShowResult> showInterstitialAndWait({
    required Duration loadTimeout,
  }) async {
    showCalls += 1;
    return showResult;
  }
}

class _FakeAnalyticsService implements AnalyticsService {
  @override
  void logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) {}
}
