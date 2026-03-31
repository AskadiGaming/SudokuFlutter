enum GoatDirection { leftToRight, rightToLeft }

class FlyingGoat {
  const FlyingGoat({
    required this.id,
    required this.direction,
    required this.sizePx,
    required this.startY,
    required this.speedPxPerSecond,
    required this.spawnTime,
    required this.x,
  });

  final int id;
  final GoatDirection direction;
  final double sizePx;
  final double startY;
  final double speedPxPerSecond;
  final DateTime spawnTime;
  final double x;

  FlyingGoat copyWith({double? x}) {
    return FlyingGoat(
      id: id,
      direction: direction,
      sizePx: sizePx,
      startY: startY,
      speedPxPerSecond: speedPxPerSecond,
      spawnTime: spawnTime,
      x: x ?? this.x,
    );
  }
}
