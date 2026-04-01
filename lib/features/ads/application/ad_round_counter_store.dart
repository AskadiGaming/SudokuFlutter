abstract class AdRoundCounterStore {
  Future<int> readRoundsSinceLastAd();

  Future<void> writeRoundsSinceLastAd(int value);

  Future<void> resetRoundsSinceLastAd();
}
