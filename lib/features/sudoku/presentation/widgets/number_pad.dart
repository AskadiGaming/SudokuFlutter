import 'package:flutter/material.dart';

class SudokuNumberPad extends StatelessWidget {
  const SudokuNumberPad({
    required this.activeValue,
    required this.remainingCounts,
    required this.onValueSelected,
    this.enabled = true,
    super.key,
  });

  final int activeValue;
  final Map<int, int> remainingCounts;
  final ValueChanged<int> onValueSelected;
  final bool enabled;

  static const double _slotHeight = 76;
  static const double _slotSpacing = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double buttonWidth = (constraints.maxWidth - 32) / 9;
        final double slotWidth = buttonWidth.clamp(34, 60);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const Key('number-button-row'),
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(17, (int index) {
              if (index.isOdd) {
                return const SizedBox(width: _slotSpacing);
              }

              final int slotIndex = index ~/ 2;
              final int value = slotIndex + 1;
              final int remainingCount = remainingCounts[value] ?? 9;
              final bool isSelected = activeValue == value;
              final bool isDepleted = remainingCount == 0;

              return SizedBox(
                key: Key('number-button-slot-$value'),
                width: slotWidth,
                height: _slotHeight,
                child:
                    isDepleted
                        ? SizedBox(
                          key: Key('number-button-gap-$value'),
                          width: slotWidth,
                          height: _slotHeight,
                        )
                        : _NumberPadButton(
                          value: value,
                          remainingCount: remainingCount,
                          isSelected: isSelected,
                          enabled: enabled,
                          onPressed: () => onValueSelected(value),
                        ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _NumberPadButton extends StatelessWidget {
  const _NumberPadButton({
    required this.value,
    required this.remainingCount,
    required this.isSelected,
    required this.enabled,
    required this.onPressed,
  });

  final int value;
  final int remainingCount;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color backgroundColor =
        isSelected
            ? colorScheme.primary
            : enabled
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest;
    final Color foregroundColor =
        isSelected
            ? colorScheme.onPrimary
            : enabled
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.38);
    final Color borderColor =
        isSelected
            ? colorScheme.primary
            : enabled
            ? colorScheme.outline
            : colorScheme.outline.withValues(alpha: 0.4);

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('number-button-$value'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            key: Key(
              'number-button-$value-${isSelected ? 'selected' : 'idle'}',
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$value',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$remainingCount',
                    key: Key('number-button-count-$value'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foregroundColor.withValues(
                        alpha: isSelected ? 0.9 : 0.72,
                      ),
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
