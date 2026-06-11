import 'package:flutter/material.dart';

class SudokuNumberPad extends StatelessWidget {
  const SudokuNumberPad({
    required this.activeValue,
    required this.onValueSelected,
    this.hiddenValues = const <int>{},
    this.enabled = true,
    super.key,
  });

  final int activeValue;
  final ValueChanged<int> onValueSelected;
  final Set<int> hiddenValues;
  final bool enabled;

  static const double _slotHeight = 42;
  static const double _slotSpacing = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double buttonWidth = (constraints.maxWidth - 18) / 10;
        final double slotWidth = buttonWidth.clamp(34, 60);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            key: const Key('number-button-row'),
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(19, (int index) {
              if (index.isOdd) {
                return const SizedBox(width: _slotSpacing);
              }

              final int slotIndex = index ~/ 2;
              final int value = _valueForButtonIndex(slotIndex);
              final bool isHidden = value != 0 && hiddenValues.contains(value);
              final bool isSelected = activeValue == value;

              return SizedBox(
                key: Key(
                  value == 0
                      ? 'number-button-slot-delete'
                      : 'number-button-slot-$value',
                ),
                width: slotWidth,
                height: _slotHeight,
                child:
                    isHidden
                        ? SizedBox(
                          key: Key('number-button-gap-$value'),
                          width: slotWidth,
                          height: _slotHeight,
                        )
                        : _NumberPadButton(
                          value: value,
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

  int _valueForButtonIndex(int index) => index == 9 ? 0 : index + 1;
}

class _NumberPadButton extends StatelessWidget {
  const _NumberPadButton({
    required this.value,
    required this.isSelected,
    required this.enabled,
    required this.onPressed,
  });

  final int value;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDelete = value == 0;
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
          key: Key(isDelete ? 'number-button-delete' : 'number-button-$value'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            key: Key(
              isDelete
                  ? 'number-button-delete-${isSelected ? 'selected' : 'idle'}'
                  : 'number-button-$value-${isSelected ? 'selected' : 'idle'}',
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child:
                  isDelete
                      ? Icon(
                        Icons.backspace_outlined,
                        key: const Key('number-button-delete-icon'),
                        color: foregroundColor,
                      )
                      : Text(
                        '$value',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
