import 'package:shared_preferences/shared_preferences.dart';

import '../application/ad_round_counter_store.dart';

class SharedPrefsAdRoundCounterStore implements AdRoundCounterStore {
  static const String roundsSinceLastAdKey = 'ads.rounds_since_last_ad';
  static const int _fallbackInitialValue = 1;

  SharedPreferences? _prefs;

  @override
  Future<int> readRoundsSinceLastAd() async {
    final SharedPreferences prefs = await _getPrefs();
    final int? persistedValue = prefs.getInt(roundsSinceLastAdKey);
    final int sanitizedValue = _sanitizeRoundCounter(persistedValue);

    if (persistedValue != sanitizedValue) {
      await prefs.setInt(roundsSinceLastAdKey, sanitizedValue);
    }

    return sanitizedValue;
  }

  @override
  Future<void> writeRoundsSinceLastAd(int value) async {
    final SharedPreferences prefs = await _getPrefs();
    final int sanitizedValue = _sanitizeRoundCounter(value);
    await prefs.setInt(roundsSinceLastAdKey, sanitizedValue);
  }

  @override
  Future<void> resetRoundsSinceLastAd() => writeRoundsSinceLastAd(0);

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  int _sanitizeRoundCounter(int? value) {
    if (value == null || value < 0) {
      return _fallbackInitialValue;
    }
    return value;
  }
}
