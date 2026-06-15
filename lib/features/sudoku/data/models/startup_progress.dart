class SudokuSeedProgress {
  const SudokuSeedProgress({
    required this.progress,
    required this.message,
    required this.showSplash,
  });

  const SudokuSeedProgress.idle()
    : progress = 0,
      message = '',
      showSplash = false;

  final double progress;
  final String message;
  final bool showSplash;
}
