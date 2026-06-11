import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/sudoku/data/sudoku_puzzle_repository.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_difficulty.dart';
import 'package:hello_world_app/features/sudoku/domain/sudoku_round_config.dart';
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

void main() {
  testWidgets('hides admin solve button when feature flag is disabled', (
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
          repository: _FakeSudokuRepository(
            puzzle:
                '534678912672195348198342567859761423426853791713924856961537284287419635345286170',
          ),
          adminTestOverrideEnabled: false,
          adminSolveButtonEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-solve-sudoku-button')), findsNothing);
  });

  testWidgets(
    'admin solve button fills the sudoku except for one last editable cell',
    (WidgetTester tester) async {
      int replayCalls = 0;
      final _RecordingCompletedSudokuLogRepository historyRepository =
          _RecordingCompletedSudokuLogRepository();
      final _RecordingSudokuReplayRepository replayRepository =
          _RecordingSudokuReplayRepository();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaySudokuPage(
            roundConfig: const SudokuRoundConfig(
              difficulty: SudokuDifficulty.easy,
            ),
            repository: _FakeSudokuRepository(
              puzzle:
                  '534678912672195348198342567859761423426853791713924856961537284287419635345286100',
            ),
            completedSudokuLogRepository: historyRepository,
            replayRepository: replayRepository,
            adminTestOverrideEnabled: false,
            adminSolveButtonEnabled: true,
            onReplayRoundRequested: (
              BuildContext context,
              SudokuRoundConfig config,
            ) async {
              replayCalls++;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('admin-solve-sudoku-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('admin-solve-sudoku-button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-7')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-8')),
          matching: find.text('9'),
        ),
        findsNothing,
      );
      expect(find.text('Sudoku geloest'), findsNothing);

      final SudokuReplayDetails? replayDetails = await replayRepository
          .getReplayDetails(replayRepository.replayId!);
      expect(replayDetails, isNotNull);
      expect(replayDetails!.moves, hasLength(1));
      expect(replayDetails.moves.single.cellRow, 8);
      expect(replayDetails.moves.single.cellCol, 7);
      expect(replayDetails.moves.single.previousValue, 0);
      expect(replayDetails.moves.single.nextValue, 7);

      await tester.tap(find.byKey(const Key('number-button-9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('sudoku-cell-8-8')));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('sudoku-cell-8-8')),
          matching: find.text('9'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(seconds: 5));

      final BuildContext context = tester.element(find.byType(PlaySudokuPage));
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      expect(find.text(l10n.sudokuSolvedTitle), findsOneWidget);
      expect(historyRepository.entries, hasLength(1));

      await tester.tap(find.text(l10n.sudokuPlayAgain));
      await tester.pump();
      expect(replayCalls, 1);
    },
  );

  testWidgets('runs finish sequence, locks interaction and shows replay CTA', (
    WidgetTester tester,
  ) async {
    int replayCalls = 0;
    final _RecordingCompletedSudokuLogRepository historyRepository =
        _RecordingCompletedSudokuLogRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlaySudokuPage(
          roundConfig: const SudokuRoundConfig(
            difficulty: SudokuDifficulty.easy,
          ),
          repository: _FakeSudokuRepository(
            puzzle:
                '534678912672195348198342567859761423426853791713924856961537284287419635345286170',
          ),
          completedSudokuLogRepository: historyRepository,
          adminTestOverrideEnabled: false,
          onReplayRoundRequested: (
            BuildContext context,
            SudokuRoundConfig config,
          ) async {
            replayCalls++;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('number-button-9')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sudoku-cell-8-8')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final Finder firstCellOpacity = find.ancestor(
      of: find.byKey(const Key('sudoku-cell-0-0')),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(firstCellOpacity).opacity, 0);

    final InkWell numberPadButton = tester.widget<InkWell>(
      find.byKey(const Key('number-button-delete')),
    );
    expect(numberPadButton.onTap, isNull);

    await tester.pump(const Duration(seconds: 5));

    final BuildContext context = tester.element(find.byType(PlaySudokuPage));
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.sudokuSolvedTitle), findsOneWidget);
    expect(find.text(l10n.sudokuPlayAgain), findsOneWidget);
    expect(historyRepository.entries, hasLength(1));
    expect(historyRepository.entries.single.difficulty, SudokuDifficulty.easy);
    expect(
      historyRepository.entries.single.durationSeconds,
      greaterThanOrEqualTo(0),
    );

    await tester.tap(find.text(l10n.sudokuPlayAgain));
    await tester.pump();
    expect(replayCalls, 1);
  });
}

class _FakeSudokuRepository implements SudokuPuzzleRepository {
  _FakeSudokuRepository({required this.puzzle});

  final String puzzle;

  @override
  Future<String> getOrCreateDailyPuzzle(DateTime date) async => puzzle;

  @override
  Future<String> getRandomByDifficulty(SudokuDifficulty difficulty) async =>
      puzzle;
}

class _RecordingCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  final List<CompletedSudokuEntry> entries = <CompletedSudokuEntry>[];

  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async => entries;
}

class _RecordingSudokuReplayRepository implements SudokuReplayRepository {
  SudokuReplay? _replay;
  final List<SudokuReplayMove> _moves = <SudokuReplayMove>[];
  final List<SudokuPlaySession> _sessions = <SudokuPlaySession>[];

  int? get replayId => _replay?.id;

  @override
  Future<void> addMove({
    required int replayId,
    required int sequence,
    required int cellRow,
    required int cellCol,
    required int previousValue,
    required int nextValue,
    required int elapsedMillis,
  }) async {
    _moves.add(
      SudokuReplayMove(
        id: sequence + 1,
        replayId: replayId,
        sequence: sequence,
        cellRow: cellRow,
        cellCol: cellCol,
        previousValue: previousValue,
        nextValue: nextValue,
        elapsedMillis: elapsedMillis,
      ),
    );
  }

  @override
  Future<void> completeReplay({
    required int replayId,
    required String finalGridString,
    required int playedDurationMillis,
    required DateTime completedAt,
  }) async {
    final SudokuReplay? replay = _replay;
    if (replay == null || replay.id != replayId) {
      return;
    }
    _replay = SudokuReplay(
      id: replay.id,
      mode: replay.mode,
      difficulty: replay.difficulty,
      challengeDate: replay.challengeDate,
      sourceSudokuId: replay.sourceSudokuId,
      puzzleString: replay.puzzleString,
      finalGridString: finalGridString,
      playedDurationMillis: playedDurationMillis,
      createdAt: replay.createdAt,
      updatedAt: completedAt,
      completedAt: completedAt,
    );
  }

  @override
  Future<SudokuReplay> createReplay(SudokuReplayDraft draft) async {
    final SudokuReplay replay = SudokuReplay(
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
    _replay = replay;
    return replay;
  }

  @override
  Future<void> endSession({
    required int sessionId,
    required DateTime endedAt,
    required int activeDurationMillis,
  }) async {
    final int index = _sessions.indexWhere(
      (SudokuPlaySession session) => session.id == sessionId,
    );
    if (index == -1) {
      return;
    }
    final SudokuPlaySession session = _sessions[index];
    _sessions[index] = SudokuPlaySession(
      id: session.id,
      replayId: session.replayId,
      sessionIndex: session.sessionIndex,
      startedAt: session.startedAt,
      endedAt: endedAt,
      activeDurationMillis: activeDurationMillis,
    );
  }

  @override
  Future<SudokuReplay?> findOpenReplay(SudokuReplayRoundKey key) async => null;

  @override
  Future<SudokuReplayDetails?> getReplayDetails(int replayId) async {
    final SudokuReplay? replay = _replay;
    if (replay == null || replay.id != replayId) {
      return null;
    }
    return SudokuReplayDetails(
      replay: replay,
      moves:
          _moves
              .where((SudokuReplayMove move) => move.replayId == replayId)
              .toList(),
      sessions:
          _sessions
              .where(
                (SudokuPlaySession session) => session.replayId == replayId,
              )
              .toList(),
    );
  }

  @override
  Future<int> startSession({
    required int replayId,
    required int sessionIndex,
    required DateTime startedAt,
  }) async {
    final int sessionId = _sessions.length + 1;
    _sessions.add(
      SudokuPlaySession(
        id: sessionId,
        replayId: replayId,
        sessionIndex: sessionIndex,
        startedAt: startedAt,
        activeDurationMillis: 0,
      ),
    );
    return sessionId;
  }
}
