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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int columnCount = 7;
        const int rowCount = 6;
        const double spacing = 8;
        final double usableWidth =
            constraints.maxWidth - ((columnCount - 1) * spacing);
        final double usableHeight =
            constraints.maxHeight - ((rowCount - 1) * spacing);
        final double cellWidth = usableWidth / columnCount;
        final double cellHeight = usableHeight / rowCount;
        final double childAspectRatio =
            cellHeight <= 0 ? 1 : cellWidth / cellHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (BuildContext context, int index) {
            final ChallengeDayEntry entry = entries[index];
            if (!entry.isInCurrentMonth) {
              return const SizedBox.shrink();
            }

            final bool isSelected = _isSameDate(entry.date, selectedDate);
            final Color backgroundColor = switch (entry.status) {
              ChallengeDayStatus.notStarted => theme
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              ChallengeDayStatus.inProgress => const Color(0xFF8FD3FF),
              ChallengeDayStatus.completed => const Color(0xFF7BC96F),
            };
            final Color textColor =
                entry.status == ChallengeDayStatus.notStarted
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimary;

            return InkWell(
              key: Key(
                'challenge-day-${entry.date.year}-${entry.date.month}-${entry.date.day}',
              ),
              borderRadius: BorderRadius.circular(18),
              onTap: () => onDateSelected(entry.date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      isSelected
                          ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                          : null,
                ),
                child: Center(
                  child: Text(
                    '${entry.date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          },
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
