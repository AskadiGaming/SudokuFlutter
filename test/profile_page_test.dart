import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/application/profile_controller.dart';
import 'package:hello_world_app/features/profile/data/profile_repository.dart';
import 'package:hello_world_app/features/profile/presentation/profile_page.dart';
import 'package:hello_world_app/features/profile/presentation/profile_scope.dart';

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
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SudokuPlayer'), findsAtLeastNWidgets(1));
    expect(find.text('Lokales Profil'), findsNothing);
    expect(find.text('bearbeiten'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(2));

    await tester.tap(find.text('bearbeiten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mila');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Mila'), findsAtLeastNWidgets(1));
    expect(repository.savedUsernames, <String>['Mila']);

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
