import 'package:flutter/foundation.dart';

import '../application/analytics_service.dart';

class DebugAnalyticsService implements AnalyticsService {
  @override
  void logEvent(
    String eventName, {
    Map<String, Object?> parameters = const {},
  }) {
    debugPrint('[ads.analytics] $eventName $parameters');
  }
}
