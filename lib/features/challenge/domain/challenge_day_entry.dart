import 'challenge_day_status.dart';

class ChallengeDayEntry {
  const ChallengeDayEntry({
    required this.date,
    required this.isInCurrentMonth,
    required this.status,
  });

  final DateTime date;
  final bool isInCurrentMonth;
  final ChallengeDayStatus status;
}
