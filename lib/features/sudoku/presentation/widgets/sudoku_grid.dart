import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/sudoku_grid_parser.dart';
import '../../domain/sudoku_modifier_type.dart';
import '../modifiers/models/flying_goat.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    required this.gridData,
    required this.activeValue,
    required this.activeModifier,
    required this.gridShakeOffset,
    required this.quarterTurns,
    required this.rotationController,
    required this.rotation90Controller,
    required this.textRotationController,
    required this.textRotationDirections,
    required this.flyingGoats,
    required this.goatAssetPath,
    required this.onCellTapped,
    required this.onViewportChanged,
    super.key,
  });

  final SudokuGridData gridData;
  final int activeValue;
  final SudokuModifierType? activeModifier;
  final Offset gridShakeOffset;
  final int quarterTurns;
  final AnimationController rotationController;
  final AnimationController rotation90Controller;
  final AnimationController textRotationController;
  final Map<int, int> textRotationDirections;
  final List<FlyingGoat> flyingGoats;
  final String goatAssetPath;
  final void Function(int row, int col) onCellTapped;
  final ValueChanged<Size> onViewportChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isShaking = activeModifier == SudokuModifierType.shaking;
    final bool isRotating360 = activeModifier == SudokuModifierType.rotation360;
    final bool isRotating90 = activeModifier == SudokuModifierType.rotation90;
    final bool isTextRotating =
        activeModifier == SudokuModifierType.textRotation;
    final bool showGoatOverlay =
        activeModifier == SudokuModifierType.goat || flyingGoats.isNotEmpty;

    Widget buildGridContent() {
      final double rotation90Angle = rotation90Controller.value * (pi / 2);
      final Widget grid = GridView.builder(
        key: Key('sudoku-grid-orientation-$quarterTurns'),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 81,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
        ),
        itemBuilder: (BuildContext context, int index) {
          final int row = index ~/ 9;
          final int col = index % 9;
          final int value = gridData.currentGrid[row][col];
          final int direction = textRotationDirections[index] ?? 1;
          final bool isFixed = gridData.isFixed[row][col];
          final bool isHighlighted = value != 0 && value == activeValue;

          final Color baseColor =
              isFixed
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface;
          final Color backgroundColor =
              isHighlighted ? theme.colorScheme.secondaryContainer : baseColor;

          return InkWell(
            onTap: () => onCellTapped(row, col),
            child: Container(
              key: Key('sudoku-cell-$row-$col'),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: _buildCellBorder(context, row, col),
              ),
              child:
                  value == 0
                      ? const SizedBox.shrink()
                      : Transform.rotate(
                        angle:
                            (isRotating90 ? -rotation90Angle : 0) +
                            (isTextRotating
                                ? direction *
                                    textRotationController.value *
                                    (2 * pi)
                                : 0),
                        child: Text(
                          '$value',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight:
                                isFixed ? FontWeight.bold : FontWeight.w500,
                            color:
                                isFixed
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
            ),
          );
        },
      );

      return Transform.translate(
        offset: isShaking ? gridShakeOffset : Offset.zero,
        child: grid,
      );
    }

    Widget gridLayer() {
      if (!isRotating360 && !isRotating90 && !isTextRotating) {
        return buildGridContent();
      }

      return AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          rotationController,
          rotation90Controller,
          textRotationController,
        ]),
        builder: (BuildContext context, Widget? child) {
          final double angle =
              isRotating360
                  ? rotationController.value * (2 * pi)
                  : rotation90Controller.value * (pi / 2);
          return Transform.rotate(
            angle: angle,
            alignment: Alignment.center,
            transformHitTests: true,
            child: buildGridContent(),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        onViewportChanged(Size(constraints.maxWidth, constraints.maxHeight));
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            gridLayer(),
            if (showGoatOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Stack(
                    key: const Key('goat-overlay'),
                    children:
                        flyingGoats.map((FlyingGoat goat) {
                          final bool flipHorizontally =
                              goat.direction == GoatDirection.rightToLeft;
                          return Positioned(
                            left: goat.x,
                            top: goat.startY,
                            child: SizedBox(
                              key: Key(
                                'goat-${goat.id}-${goat.direction.name}',
                              ),
                              width: goat.sizePx,
                              height: goat.sizePx,
                              child: Transform(
                                alignment: Alignment.center,
                                transform:
                                    flipHorizontally
                                        ? Matrix4.diagonal3Values(-1, 1, 1)
                                        : Matrix4.identity(),
                                child: Image.asset(
                                  goatAssetPath,
                                  key: Key('goat-image-${goat.id}'),
                                  fit: BoxFit.contain,
                                  errorBuilder: (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    debugPrint(
                                      'Failed to load $goatAssetPath: $error',
                                    );
                                    return const ColoredBox(
                                      color: Color(0x44FF7043),
                                      child: Center(
                                        child: Icon(
                                          Icons.pets,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Border _buildCellBorder(BuildContext context, int row, int col) {
    final Color color = Theme.of(context).dividerColor;
    final bool thickTop = row % 3 == 0;
    final bool thickLeft = col % 3 == 0;
    final bool thickBottom = row == 8;
    final bool thickRight = col == 8;

    return Border(
      top: BorderSide(width: thickTop ? 2 : 0.5, color: color),
      left: BorderSide(width: thickLeft ? 2 : 0.5, color: color),
      right: BorderSide(width: thickRight ? 2 : 0.5, color: color),
      bottom: BorderSide(width: thickBottom ? 2 : 0.5, color: color),
    );
  }
}
