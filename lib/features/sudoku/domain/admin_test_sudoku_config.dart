class AdminTestSudokuConfig {
  const AdminTestSudokuConfig({required this.enabled, this.sudokuString});

  final bool enabled;
  final String? sudokuString;

  String? get normalizedSudokuString {
    final String? rawValue = sudokuString;
    if (rawValue == null) {
      return null;
    }

    final String trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool get hasValidOverride {
    if (!enabled) {
      return false;
    }
    return isValidSudokuOverride(normalizedSudokuString);
  }

  static bool isValidSudokuOverride(String? value) {
    if (value == null) {
      return false;
    }
    return RegExp(r'^[0-9]{81}$').hasMatch(value);
  }
}
