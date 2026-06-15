List<String> parseSudokuLines(String content) {
  final List<String> puzzles = <String>[];
  final List<String> lines = content.split(RegExp(r'\r?\n'));
  for (int i = 0; i < lines.length; i++) {
    final String candidate = lines[i].trim();
    if (candidate.isEmpty) {
      continue;
    }
    if (candidate.length != 81) {
      throw FormatException(
        'Sudoku line ${i + 1} must contain exactly 81 characters, got ${candidate.length}.',
      );
    }
    if (!RegExp(r'^[0-9]{81}$').hasMatch(candidate)) {
      throw FormatException(
        'Sudoku line ${i + 1} may only contain digits 0-9.',
      );
    }
    puzzles.add(candidate);
  }
  return puzzles;
}
