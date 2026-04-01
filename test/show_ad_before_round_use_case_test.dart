import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/ads/application/ad_round_counter_store.dart';
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
      roundCounterStore: _FakeAdRoundCounterStore(initialValue: 1),
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
      roundCounterStore: _FakeAdRoundCounterStore(initialValue: 1),
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
      roundCounterStore: _FakeAdRoundCounterStore(initialValue: 1),
      policy: const AdPolicy(timingMode: AdTimingMode.beforeRoundStart),
    );

    final AdShowResult result = await useCase.execute();

    expect(result, AdShowResult.failed);
    expect(adService.initializeCalls, 1);
    expect(adService.showCalls, 0);
  });

  test(
    'rounds 1-9 are skipped by policy and round 10 attempts to show ad',
    () async {
      final _FakeAdRoundCounterStore store = _FakeAdRoundCounterStore(
        initialValue: 1,
      );
      final _FakeAdService adService = _FakeAdService(
        supportsCurrentPlatform: true,
        showResult: AdShowResult.shown,
      );
      final ShowAdBeforeRoundUseCase useCase = ShowAdBeforeRoundUseCase(
        adService: adService,
        analyticsService: _FakeAnalyticsService(),
        roundCounterStore: store,
        policy: const AdPolicy(
          timingMode: AdTimingMode.beforeRoundStart,
          minRoundsBetweenAds: 10,
        ),
      );

      for (int round = 1; round <= 9; round += 1) {
        final AdShowResult result = await useCase.execute();
        expect(result, AdShowResult.skipped);
      }

      final AdShowResult tenthRound = await useCase.execute();

      expect(tenthRound, AdShowResult.shown);
      expect(adService.initializeCalls, 1);
      expect(adService.showCalls, 1);
      expect(store.value, 0);
    },
  );

  test('failed and skipped ad results increment persisted counter', () async {
    final _FakeAdRoundCounterStore skippedStore = _FakeAdRoundCounterStore(
      initialValue: 10,
    );
    final ShowAdBeforeRoundUseCase skippedUseCase = ShowAdBeforeRoundUseCase(
      adService: _FakeAdService(
        supportsCurrentPlatform: true,
        showResult: AdShowResult.skipped,
      ),
      analyticsService: _FakeAnalyticsService(),
      roundCounterStore: skippedStore,
      policy: const AdPolicy(
        timingMode: AdTimingMode.beforeRoundStart,
        minRoundsBetweenAds: 10,
      ),
    );
    expect(await skippedUseCase.execute(), AdShowResult.skipped);
    expect(skippedStore.value, 11);

    final _FakeAdRoundCounterStore failedStore = _FakeAdRoundCounterStore(
      initialValue: 10,
    );
    final ShowAdBeforeRoundUseCase failedUseCase = ShowAdBeforeRoundUseCase(
      adService: _FakeAdService(
        supportsCurrentPlatform: true,
        showResult: AdShowResult.failed,
      ),
      analyticsService: _FakeAnalyticsService(),
      roundCounterStore: failedStore,
      policy: const AdPolicy(
        timingMode: AdTimingMode.beforeRoundStart,
        minRoundsBetweenAds: 10,
      ),
    );
    expect(await failedUseCase.execute(), AdShowResult.failed);
    expect(failedStore.value, 11);
  });

  test(
    'counter persistence survives app restart and shows on round 10',
    () async {
      final _FakeAdRoundCounterStore store = _FakeAdRoundCounterStore(
        initialValue: 1,
      );
      final _FakeAdService firstSessionAdService = _FakeAdService(
        supportsCurrentPlatform: true,
        showResult: AdShowResult.shown,
      );

      final ShowAdBeforeRoundUseCase firstSession = ShowAdBeforeRoundUseCase(
        adService: firstSessionAdService,
        analyticsService: _FakeAnalyticsService(),
        roundCounterStore: store,
        policy: const AdPolicy(
          timingMode: AdTimingMode.beforeRoundStart,
          minRoundsBetweenAds: 10,
        ),
      );

      for (int round = 1; round <= 9; round += 1) {
        expect(await firstSession.execute(), AdShowResult.skipped);
      }

      expect(store.value, 10);
      expect(firstSessionAdService.showCalls, 0);

      final _FakeAdService secondSessionAdService = _FakeAdService(
        supportsCurrentPlatform: true,
        showResult: AdShowResult.shown,
      );
      final ShowAdBeforeRoundUseCase secondSession = ShowAdBeforeRoundUseCase(
        adService: secondSessionAdService,
        analyticsService: _FakeAnalyticsService(),
        roundCounterStore: store,
        policy: const AdPolicy(
          timingMode: AdTimingMode.beforeRoundStart,
          minRoundsBetweenAds: 10,
        ),
      );

      final AdShowResult resultAfterRestart = await secondSession.execute();

      expect(resultAfterRestart, AdShowResult.shown);
      expect(secondSessionAdService.showCalls, 1);
      expect(store.value, 0);
    },
  );
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
  final List<Map<String, Object?>> parameters = <Map<String, Object?>>[];

  @override
  void logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) {
    events.add(eventName);
    this.parameters.add(parameters);
  }
}

class _FakeAdRoundCounterStore implements AdRoundCounterStore {
  _FakeAdRoundCounterStore({required this.initialValue}) : value = initialValue;

  final int initialValue;
  int value;
  int reads = 0;
  int writes = 0;

  @override
  Future<int> readRoundsSinceLastAd() async {
    reads += 1;
    return value;
  }

  @override
  Future<void> resetRoundsSinceLastAd() async {
    await writeRoundsSinceLastAd(0);
  }

  @override
  Future<void> writeRoundsSinceLastAd(int persistedValue) async {
    writes += 1;
    value = persistedValue;
  }
}
