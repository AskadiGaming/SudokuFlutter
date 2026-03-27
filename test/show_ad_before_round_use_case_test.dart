import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/ads/application/ad_service.dart';
import 'package:hello_world_app/features/ads/application/analytics_service.dart';
import 'package:hello_world_app/features/ads/application/show_ad_before_round_use_case.dart';
import 'package:hello_world_app/features/ads/domain/ad_policy.dart';
import 'package:hello_world_app/features/ads/domain/ad_timing_mode.dart';

void main() {
  test('returns skipped when platform is unsupported', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: false,
    );
    final _FakeAnalyticsService analytics = _FakeAnalyticsService();
    final ShowAdBeforeRoundUseCase useCase = ShowAdBeforeRoundUseCase(
      adService: adService,
      analyticsService: analytics,
      policy: const AdPolicy(timingMode: AdTimingMode.beforeRoundStart),
    );

    final AdShowResult result = await useCase.execute();

    expect(result, AdShowResult.skipped);
    expect(adService.initializeCalls, 0);
    expect(adService.showCalls, 0);
  });

  test('returns shown when ad is displayed', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: true,
      showResult: AdShowResult.shown,
    );
    final ShowAdBeforeRoundUseCase useCase = ShowAdBeforeRoundUseCase(
      adService: adService,
      analyticsService: _FakeAnalyticsService(),
      policy: const AdPolicy(timingMode: AdTimingMode.beforeRoundStart),
    );

    final AdShowResult result = await useCase.execute();

    expect(result, AdShowResult.shown);
    expect(adService.initializeCalls, 1);
    expect(adService.showCalls, 1);
  });

  test('returns failed when initialization throws', () async {
    final _FakeAdService adService = _FakeAdService(
      supportsCurrentPlatform: true,
      throwOnInitialize: true,
    );
    final ShowAdBeforeRoundUseCase useCase = ShowAdBeforeRoundUseCase(
      adService: adService,
      analyticsService: _FakeAnalyticsService(),
      policy: const AdPolicy(timingMode: AdTimingMode.beforeRoundStart),
    );

    final AdShowResult result = await useCase.execute();

    expect(result, AdShowResult.failed);
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
    required Duration timeout,
  }) async {
    showCalls += 1;
    return showResult;
  }
}

class _FakeAnalyticsService implements AnalyticsService {
  final List<String> events = <String>[];

  @override
  void logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) {
    events.add(eventName);
  }
}
