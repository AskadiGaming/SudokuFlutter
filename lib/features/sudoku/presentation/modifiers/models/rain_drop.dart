class RainDrop {
  const RainDrop({
    required this.id,
    required this.x,
    required this.y,
    required this.lengthPx,
    required this.speedPxPerSecond,
    required this.opacity,
    required this.thicknessPx,
  });

  final int id;
  final double x;
  final double y;
  final double lengthPx;
  final double speedPxPerSecond;
  final double opacity;
  final double thicknessPx;

  RainDrop copyWith({double? x, double? y}) {
    return RainDrop(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      lengthPx: lengthPx,
      speedPxPerSecond: speedPxPerSecond,
      opacity: opacity,
      thicknessPx: thicknessPx,
    );
  }
}
