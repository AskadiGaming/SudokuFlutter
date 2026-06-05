import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/application/profile_controller.dart';
import 'package:hello_world_app/features/profile/data/profile_repository.dart';
import 'package:hello_world_app/features/profile/presentation/profile_page.dart';
import 'package:hello_world_app/features/profile/presentation/profile_scope.dart';
import 'package:hello_world_app/features/sudoku_history/data/completed_sudoku_log_repository.dart';
import 'package:hello_world_app/features/sudoku_history/domain/completed_sudoku_entry.dart';
import 'package:hello_world_app/features/sudoku_history/presentation/completed_sudoku_log_page.dart';

void main() {
  testWidgets('shows offline edit UI and updates username', (
    WidgetTester tester,
  ) async {
    final _FakeProfileRepository repository = _FakeProfileRepository();
    final ProfileController profileController = ProfileController(
      repository: repository,
    );
    await profileController.initialize();

    await tester.pumpWidget(
      ProfileScope(
        profileController: profileController,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SudokuPlayer'), findsAtLeastNWidgets(1));
    expect(find.text('Abgeschlossene Sudokus anzeigen'), findsOneWidget);
    expect(find.text('Lokales Profil'), findsNothing);
    expect(find.text('bearbeiten'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);

    await tester.tap(find.text('bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mila');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Mila'), findsAtLeastNWidgets(1));
    expect(repository.savedUsernames, <String>['Mila']);

    profileController.dispose();
  });

  testWidgets('opens completed sudoku log page from profile', (
    WidgetTester tester,
  ) async {
    final _FakeProfileRepository repository = _FakeProfileRepository();
    final ProfileController profileController = ProfileController(
      repository: repository,
    );
    await profileController.initialize();

    await tester.pumpWidget(
      ProfileScope(
        profileController: profileController,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfilePage(
            completedSudokuLogRepository: _FakeCompletedSudokuLogRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abgeschlossene Sudokus anzeigen'));
    await tester.pumpAndSettle();

    expect(find.byType(CompletedSudokuLogPage), findsOneWidget);
    expect(find.text('Noch keine abgeschlossenen Sudokus'), findsOneWidget);

    profileController.dispose();
  });
}

class _FakeProfileRepository implements ProfileRepository {
  final List<String> savedUsernames = <String>[];

  @override
  Future<String?> loadUsername() async => null;

  @override
  Future<void> saveUsername(String username) async {
    savedUsernames.add(username);
  }
}

class _FakeCompletedSudokuLogRepository
    implements CompletedSudokuLogRepository {
  @override
  Future<void> addCompletedSudoku(CompletedSudokuEntry entry) async {}

  @override
  Future<List<CompletedSudokuEntry>> getCompletedSudokus() async {
    return const <CompletedSudokuEntry>[];
  }
}
