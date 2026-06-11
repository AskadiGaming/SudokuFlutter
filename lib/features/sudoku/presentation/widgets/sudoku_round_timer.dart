import 'package:flutter/material.dart';

class SudokuCornerInfoText extends StatelessWidget {
  const SudokuCornerInfoText({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double baseFontSize = theme.textTheme.titleLarge?.fontSize ?? 22;

    return IgnorePointer(
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: baseFontSize * 0.5,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class SudokuRoundTimer extends StatelessWidget {
  const SudokuRoundTimer({required this.elapsed, super.key});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return SudokuCornerInfoText(text: _formatElapsed(elapsed));
  }

  String _formatElapsed(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
