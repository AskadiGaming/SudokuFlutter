import 'dart:math';

import 'package:flutter/widgets.dart';

double splitProgressForControllerValue(double controllerValue) {
  final double clampedValue = controllerValue.clamp(0.0, 1.0);
  return sin(pi * clampedValue);
}

Offset splitOffsetForIndex({
  required int index,
  required double splitProgress,
  required double maxOffsetPx,
}) {
  if (splitProgress <= 0 || maxOffsetPx <= 0) {
    return Offset.zero;
  }

  final int row = index ~/ 9;
  final int col = index % 9;
  final double dx = (col - 4).toDouble();
  final double dy = (row - 4).toDouble();
  final double length = sqrt((dx * dx) + (dy * dy));
  if (length == 0) {
    return Offset.zero;
  }

  final double maxDistance = sqrt(32);
  final double distanceScale = length / maxDistance;
  final double magnitude = splitProgress * maxOffsetPx * distanceScale;
  return Offset((dx / length) * magnitude, (dy / length) * magnitude);
}
