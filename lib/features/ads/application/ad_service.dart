enum AdShowResult { shown, skipped, failed }

abstract class AdService {
  bool get supportsCurrentPlatform;

  Future<void> initialize();

  Future<AdShowResult> showInterstitialAndWait({required Duration timeout});
}
