import 'package:flutter/material.dart';

class SudokuNumberPad extends StatelessWidget {
  const SudokuNumberPad({
    required this.activeValue,
    required this.onValueSelected,
    super.key,
  });

  final int activeValue;
  final ValueChanged<int> onValueSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double buttonWidth = (constraints.maxWidth - 18) / 10;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            key: const Key('number-toggle-buttons'),
            borderRadius: BorderRadius.circular(8),
            constraints: BoxConstraints.tightFor(
              width: buttonWidth.clamp(34, 60),
              height: 42,
            ),
            isSelected: List<bool>.generate(
              10,
              (int index) => activeValue == _valueForButtonIndex(index),
            ),
            onPressed:
                (int index) => onValueSelected(_valueForButtonIndex(index)),
            children: List<Widget>.generate(
              10,
              (int index) => _buildButtonLabel(index),
            ),
          ),
        );
      },
    );
  }

  int _valueForButtonIndex(int index) => index == 9 ? 0 : index + 1;

  Widget _buildButtonLabel(int index) {
    if (index == 9) {
      return const Center(
        child: Icon(Icons.backspace_outlined, key: Key('number-button-delete')),
      );
    }

    return Center(
      child: Text('${index + 1}', key: Key('number-button-${index + 1}')),
    );
  }
}
