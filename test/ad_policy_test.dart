import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/ads/domain/ad_policy.dart';
import 'package:hello_world_app/features/ads/domain/ad_timing_mode.dart';

void main() {
  test('returns false when ad timing is off', () {
    const AdPolicy policy = AdPolicy(timingMode: AdTimingMode.off);

    final bool shouldShow = policy.shouldShowAd(
      now: DateTime(2026, 1, 1, 12),
      roundsSinceLastAd: 10,
      lastAdShownAt: DateTime(2026, 1, 1, 11),
    );

    expect(shouldShow, isFalse);
  });

  test('returns false when minimum rounds are not reached', () {
    const AdPolicy policy = AdPolicy(
      timingMode: AdTimingMode.beforeRoundStart,
      minRoundsBetweenAds: 3,
    );

    final bool shouldShow = policy.shouldShowAd(
      now: DateTime(2026, 1, 1, 12),
      roundsSinceLastAd: 2,
      lastAdShownAt: DateTime(2026, 1, 1, 11),
    );

    expect(shouldShow, isFalse);
  });

  test('returns false when cooldown is active', () {
    const AdPolicy policy = AdPolicy(
      timingMode: AdTimingMode.beforeRoundStart,
      cooldown: Duration(minutes: 10),
    );

    final bool shouldShow = policy.shouldShowAd(
      now: DateTime(2026, 1, 1, 12, 5),
      roundsSinceLastAd: 10,
      lastAdShownAt: DateTime(2026, 1, 1, 12),
    );

    expect(shouldShow, isFalse);
  });

  test('returns true when all constraints are met', () {
    const AdPolicy policy = AdPolicy(
      timingMode: AdTimingMode.beforeRoundStart,
      minRoundsBetweenAds: 2,
      cooldown: Duration(minutes: 10),
    );

    final bool shouldShow = policy.shouldShowAd(
      now: DateTime(2026, 1, 1, 12, 15),
      roundsSinceLastAd: 2,
      lastAdShownAt: DateTime(2026, 1, 1, 12),
    );

    expect(shouldShow, isTrue);
  });
}
