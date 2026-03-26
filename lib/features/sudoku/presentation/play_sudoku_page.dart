import 'package:flutter/material.dart';

import '../data/local_sudoku_puzzle_repository.dart';
import '../data/sudoku_puzzle_repository.dart';
import '../domain/sudoku_difficulty.dart';
import '../domain/sudoku_grid_parser.dart';

class PlaySudokuPage extends StatefulWidget {
  const PlaySudokuPage({required this.difficulty, this.repository, super.key});

  final SudokuDifficulty difficulty;
  final SudokuPuzzleRepository? repository;

  @override
  State<PlaySudokuPage> createState() => _PlaySudokuPageState();
}

class _PlaySudokuPageState extends State<PlaySudokuPage> {
  late final SudokuPuzzleRepository _repository =
      widget.repository ?? LocalSudokuPuzzleRepository();

  SudokuGridData? _gridData;
  Object? _loadingError;
  int _activeValue = 1;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    try {
      final String puzzle = await _repository.loadPuzzle(widget.difficulty);
      final SudokuGridData parsed = parsePuzzle(puzzle);
      if (!mounted) {
        return;
      }
      setState(() {
        _gridData = parsed;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingError = error;
      });
    }
  }

  void _setActiveValue(int value) {
    setState(() {
      _activeValue = value;
    });
  }

  void _writeActiveNumberToCell(int row, int col) {
    final SudokuGridData? gridData = _gridData;
    if (gridData == null || gridData.isFixed[row][col]) {
      return;
    }

    setState(() {
      gridData.currentGrid[row][col] = _activeValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loadingError != null) {
      return Center(
        child: Text(
          'Fehler beim Laden: $_loadingError',
          textAlign: TextAlign.center,
        ),
      );
    }

    final SudokuGridData? gridData = _gridData;
    if (gridData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildGrid(context, gridData),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildNumberButtons(),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, SudokuGridData gridData) {
    final ThemeData theme = Theme.of(context);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 81,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),
      itemBuilder: (BuildContext context, int index) {
        final int row = index ~/ 9;
        final int col = index % 9;
        final int value = gridData.currentGrid[row][col];
        final bool isFixed = gridData.isFixed[row][col];
        final bool isHighlighted = value != 0 && value == _activeValue;

        final Color baseColor =
            isFixed
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surface;
        final Color backgroundColor =
            isHighlighted ? theme.colorScheme.secondaryContainer : baseColor;

        return InkWell(
          onTap: () => _writeActiveNumberToCell(row, col),
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
                    : Text(
                      '$value',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
                        color:
                            isFixed
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
          ),
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

  Widget _buildNumberButtons() {
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
              (int index) => _activeValue == _valueForButtonIndex(index),
            ),
            onPressed:
                (int index) => _setActiveValue(_valueForButtonIndex(index)),
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
