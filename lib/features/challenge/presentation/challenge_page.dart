import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../sudoku/domain/sudoku_difficulty.dart';
import '../../sudoku/domain/sudoku_round_config.dart';
import '../../sudoku/domain/sudoku_round_mode.dart';
import '../../sudoku/presentation/play_sudoku_page.dart';
import '../application/challenge_controller.dart';
import '../data/challenge_repository.dart';
import '../data/local_challenge_repository.dart';
import '../domain/challenge_day_entry.dart';
import '../domain/challenge_day_status.dart';
import 'widgets/challenge_calendar.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({this.repository, this.controller, super.key});

  final ChallengeRepository? repository;
  final ChallengeController? controller;

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  late final ChallengeRepository _repository =
      widget.repository ?? LocalChallengeRepository();
  late final ChallengeController _controller =
      widget.controller ?? ChallengeController(repository: _repository);
  late final bool _ownsController = widget.controller == null;
  bool _isStartingRound = false;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final DateTime visibleMonth =
              _controller.visibleMonth ?? DateTime.now();
          final DateFormat monthFormat = DateFormat.yMMMM(
            Localizations.localeOf(context).toLanguageTag(),
          );
          final Map<SudokuDifficulty, String> labels =
              <SudokuDifficulty, String>{
                SudokuDifficulty.easy: l10n.quickmatchDifficultyEasy,
                SudokuDifficulty.medium: l10n.quickmatchDifficultyMedium,
                SudokuDifficulty.hard: l10n.quickmatchDifficultyHard,
                SudokuDifficulty.extreme: l10n.quickmatchDifficultyExtreme,
              };

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      SudokuDifficulty.values.map((
                        SudokuDifficulty difficulty,
                      ) {
                        return ChoiceChip(
                          label: Text(labels[difficulty]!),
                          selected:
                              _controller.selectedDifficulty == difficulty,
                          onSelected: (bool selected) {
                            if (!selected) {
                              return;
                            }
                            _controller.selectDifficulty(difficulty);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _showProgress,
                  onChanged: (bool? value) {
                    setState(() {
                      _showProgress = value ?? false;
                    });
                  },
                  title: Text(l10n.challengeShowProgress),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed:
                          _controller.isLoading
                              ? null
                              : _controller.showPreviousMonth,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: l10n.challengeMonthPrevious,
                    ),
                    Expanded(
                      child: Text(
                        toBeginningOfSentenceCase(
                              monthFormat.format(visibleMonth),
                            ) ??
                            monthFormat.format(visibleMonth),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _controller.isLoading
                              ? null
                              : _controller.showNextMonth,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: l10n.challengeMonthNext,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildWeekdays(context),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(context)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      _canStartRound ? _startOrResumeSelectedRound : null,
                  child:
                      _isStartingRound
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(_ctaLabel(l10n)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekdays(BuildContext context) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat formatter = DateFormat.E(locale);
    final List<String> weekdayLabels = <String>[];
    for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      final DateTime date = DateTime(2026, 6, weekday);
      weekdayLabels.add(formatter.format(date));
    }

    return Row(
      children:
          weekdayLabels
              .map(
                (String label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.monthData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && _controller.monthData == null) {
      return Center(
        child: Text(
          '${AppLocalizations.of(context)!.challengeLoadingError}: ${_controller.error}',
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<ChallengeDayEntry> entries =
        _controller.monthData?.entries ?? const <ChallengeDayEntry>[];
    return ChallengeCalendar(
      entries: entries,
      selectedDate: _controller.selectedDate,
      showProgress: _showProgress,
      onDateSelected: (DateTime date) {
        _controller.selectDate(date);
      },
    );
  }

  bool get _canStartRound =>
      !_isStartingRound &&
      _controller.selection != null &&
      !_controller.isLoading;

  String _ctaLabel(AppLocalizations l10n) {
    final ChallengeDayEntry? selectedEntry = _controller.selectedEntry;
    if (selectedEntry == null) {
      return l10n.challengePlay;
    }
    return selectedEntry.status == ChallengeDayStatus.notStarted
        ? l10n.challengePlay
        : l10n.challengeResume;
  }

  Future<void> _startOrResumeSelectedRound() async {
    final DateTime? selectedDate = _controller.selectedDate;
    if (_isStartingRound || selectedDate == null) {
      return;
    }

    setState(() {
      _isStartingRound = true;
    });

    try {
      await _repository.saveLastPlayedMonth(selectedDate);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) => PlaySudokuPage(
                roundConfig: SudokuRoundConfig(
                  difficulty: _controller.selectedDifficulty,
                  mode: SudokuRoundMode.challenge,
                  challengeDate: selectedDate,
                ),
                challengeRepository: _repository,
              ),
        ),
      );
      await _controller.refresh();
    } finally {
      if (mounted) {
        setState(() {
          _isStartingRound = false;
        });
      }
    }
  }
}
