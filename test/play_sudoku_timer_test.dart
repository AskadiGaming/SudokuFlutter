import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/challenge/data/challenge_repository.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_month_data.dart';
import 'package:hello_world_app/features/challenge/domain/challenge_round_data.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_mode.dart';
import 'package:hello_world_app/features/sudoku/presentation/play_sudoku_page.dart';
import 'package:hello_world_app/features/sudoku_replay/data/sudoku_replay_repository.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_play_session.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_replay.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_replay_details.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_replay_draft.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_replay_move.dart';
import 'package:hello_world_app/features/sudoku_replay/domain/sudoku_replay_round_key.dart';
import 'package:hello_world_app/features/sudoku_history/data/completed_sudoku_log_repository.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_entry.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_mode.dart';

void main() {
  testWidgets('round timer starts at zero and ticks in a normal round', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(),
          completedSudokuLogRepository: _NoopCompletedSudokuLogRepository(),
          replayRepository: _MemoryReplayRepository(),
          adminTestOverrideEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sudoku-round-timer')), findsOneWidget);
    expect(find.byKey(const Key('sudoku-round-difficulty')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Leicht'), findsOneWidget);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    });
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('challenge timer resumes from existing active play time', (
    WidgetTester tester,
  ) async {
    final DateTime challengeDate = DateTime(2026, 6, 11);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
            mode: SudokuRoundMode.challenge,
            challengeDate: challengeDate,
          ),
          repository: _FakeSudokuRepository(),
          challengeRepository: _FakeChallengeRepository(
            roundData: ChallengeRoundData(
              date: challengeDate,
              difficulty: SudokuDifficulty.easy,
              sudokuId: 12,
              puzzleString: _puzzle,
              currentGridString: _puzzle,
              isCompleted: false,
              startedAt: DateTime(2026, 6, 11, 10),
            ),
          ),
          completedSudokuLogRepository: _NoopCompletedSudokuLogRepository(),
          replayRepository: _MemoryReplayRepository(
            existingReplay: SudokuReplay(
              id: 5,
              mode: CompletedSudokuMode.challenge,
              difficulty: SudokuDifficulty.easy,
              challengeDate: challengeDate,
              sourceSudokuId: 12,
              puzzleString: _puzzle,
              finalGridString: _puzzle,
              playedDurationMillis: 0,
              createdAt: DateTime(2026, 6, 11, 10),
              updatedAt: DateTime(2026, 6, 11, 10, 1),
            ),
            existingDetails: SudokuReplayDetails(
              replay: SudokuReplay(
                id: 5,
                mode: CompletedSudokuMode.challenge,
                difficulty: SudokuDifficulty.easy,
                challengeDate: challengeDate,
                sourceSudokuId: 12,
                puzzleString: _puzzle,
                finalGridString: _puzzle,
                playedDurationMillis: 0,
                createdAt: DateTime(2026, 6, 11, 10),
                updatedAt: DateTime(2026, 6, 11, 10, 1),
              ),
              moves: const <SudokuReplayMove>[],
              sessions: <SudokuPlaySession>[
                SudokuPlaySession(
                  id: 3,
                  replayId: 5,
                  sessionIndex: 0,
                  startedAt: DateTime(2026, 6, 11, 10),
                  endedAt: DateTime(2026, 6, 11, 10, 1, 5),
                  activeDurationMillis: 65000,
                ),
              ],
            ),
          ),
          adminTestOverrideEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sudoku-round-timer')), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
  });
}

const String _puzzle =
    '500000307'
    '000000000'
    '000000000'
    '000000000'
    '000000000'
    '000000000'
    '000000000'
    '000000000'
    '000000000';

class _FakeSudokuRepository implements SudokuPuzzleRepository {
  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async => _puzzle;

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async =>
      _puzzle;
}

class _FakeChallengeRepository implements ChallengeRepository {
  _FakeChallengeRepository({required this.roundData});

  final ChallengeRoundData roundData;

  @override
  Future<ChallengeMonthData> loadMonthData({
    required DateTime month,
    required SudokuDifficulty difficulty,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> loadLastPlayedMonth() async => null;

  @override
  Future<ChallengeRoundData> loadOrCreateRoundData({
    required DateTime date,
    required SudokuDifficulty difficulty,
  }) async {
    return roundData;
  }

  @override
  Future<void> saveChallengeProgress({
    required DateTime date,
    required SudokuDifficulty difficulty,
    required int sudokuId,
    required String currentGrid,
    required bool isCompleted,
  }) async {}

  @override
  Future<void> saveLastPlayedMonth(DateTime month) async {}
}

class _NoopCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {}

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async =>
      const <CompletedSudokuEntry>[];
}

class _MemoryReplayRepository implements SudokuReplayRepository {
  _MemoryReplayRepository({this.existingReplay, this.existingDetails});

  final SudokuReplay? existingReplay;
  final SudokuReplayDetails? existingDetails;

  SudokuReplay? _createdReplay;
  final List<SudokuPlaySession> _sessions = <SudokuPlaySession>[];

  @override
  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  }) async {}

  @override
  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  }) async {}

  @override
  Future<SudokuReplay> createReplay(SudokuReplayDraft draft) async {
    return _createdReplay ??= SudokuReplay(
      id: 1,
      mode: draft.mode,
      difficulty: draft.difficulty,
      challengeDate: draft.challengeDate,
      sourceSudokuId: draft.sourceSudokuId,
      puzzleString: draft.puzzleString,
      finalGridString: draft.puzzleString,
      playedDurationMillis: 0,
      createdAt: draft.createdAt,
      updatedAt: draft.createdAt,
    );
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  }) async {}

  @override
  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key) async {
    return existingReplay;
  }

  @override
  Future<SudokuReplayDetails?> getReplayDetails(int replayId) async {
    return existingDetails;
  }

  @override
  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  }) async {
    final int id = _sessions.length + 1;
    _sessions.add(
      SudokuPlaySession(
        id: id,
        replayId: replayId,
        sessionIndex: sessionIndex,
        startedAt: startedAt,
        activeDurationMillis: 0,
      ),
    );
    return id;
  }
}
