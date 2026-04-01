import 'package:flutter/material.dart';

import '../models/rain_drop.dart';

class RainOverlay extends StatelessWidget {
  const RainOverlay({
    required this.drops,
    required this.slantDxPerLength,
    super.key,
  });

  final List<RainDrop> drops;
  final double slantDxPerLength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        key: const Key('rain-overlay'),
        painter: _RainPainter(
          drops: drops,
          slantDxPerLength: slantDxPerLength,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.drops,
    required this.slantDxPerLength,
    required this.color,
  });

  final List<RainDrop> drops;
  final double slantDxPerLength;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (final RainDrop drop in drops) {
      paint
        ..color = color.withValues(alpha: drop.opacity)
        ..strokeWidth = drop.thicknessPx;

      final Offset start = Offset(drop.x, drop.y);
      final Offset end = Offset(
        drop.x + (drop.lengthPx * slantDxPerLength),
        drop.y + drop.lengthPx,
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return oldDelegate.drops != drops ||
        oldDelegate.slantDxPerLength != slantDxPerLength ||
        oldDelegate.color != color;
  }
}
