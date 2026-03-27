abstract class AnalyticsService {
  void logEvent(String eventName, {Map<String, Object?> parameters = const {}});
}
