import 'ad_timing_mode.dart';

class AdPolicy {
  const AdPolicy({
    required this.timingMode,
    this.minRoundsBetweenAds = 1,
    this.cooldown = Duration.zero,
  }) : assert(minRoundsBetweenAds > 0);

  final AdTimingMode timingMode;
  final int minRoundsBetweenAds;
  final Duration cooldown;

  bool shouldShowAd({
    required DateTime now,
    required int roundsSinceLastAd,
    required DateTime? lastAdShownAt,
  }) {
    if (timingMode == AdTimingMode.off) {
      return false;
    }
    if (roundsSinceLastAd < minRoundsBetweenAds) {
      return false;
    }
    if (lastAdShownAt == null) {
      return true;
    }
    return now.difference(lastAdShownAt) >= cooldown;
  }
}
