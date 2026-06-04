import 'package:flutter/material.dart';

import '../../domain/challenge_day_entry.dart';
import '../../domain/challenge_day_status.dart';

class ChallengeCalendar extends StatelessWidget {
  const ChallengeCalendar({
    required this.entries,
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  final List<ChallengeDayEntry> entries;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ChallengeDayEntry entry = entries[index];
        final bool isSelected = _isSameDate(entry.date, selectedDate);
        final Color? statusColor = switch (entry.status) {
          ChallengeDayStatus.notStarted => null,
          ChallengeDayStatus.inProgress => const Color(0xFF8FD3FF),
          ChallengeDayStatus.completed => const Color(0xFFF1C75B),
        };
        final Color textColor =
            entry.isInCurrentMonth
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.4);

        return InkWell(
          key: Key(
            'challenge-day-${entry.date.year}-${entry.date.month}-${entry.date.day}',
          ),
          borderRadius: BorderRadius.circular(18),
          onTap: () => onDateSelected(entry.date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: entry.isInCurrentMonth ? 0.5 : 0.2,
              ),
              borderRadius: BorderRadius.circular(18),
              border:
                  isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
            ),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight:
                        entry.isInCurrentMonth
                            ? FontWeight.w700
                            : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDate(DateTime left, DateTime? right) {
    return right != null &&
        left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
