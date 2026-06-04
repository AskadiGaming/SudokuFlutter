import 'challenge_day_entry.dart';

class ChallengeMonthData {
  const ChallengeMonthData({required this.month, required this.entries});

  final DateTime month;
  final List<ChallengeDayEntry> entries;
}
