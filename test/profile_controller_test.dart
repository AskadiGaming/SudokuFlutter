import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/features/profile/application/profile_controller.dart';
import 'package:hello_world_app/features/profile/data/profile_repository.dart';

void main() {
  group('ProfileController', () {
    test('shows SudokuPlayer when no username is stored', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository();
      final ProfileController profileController = ProfileController(
        repository: repository,
      );

      await profileController.initialize();

      expect(profileController.state.username, 'SudokuPlayer');
      profileController.dispose();
    });

    test('loads stored username', () async {
      final _FakeProfileRepository repository = _FakeProfileRepository(
        storedUsername: 'Alex',
      );
      final ProfileController profileController = ProfileController(
        repository: repository,
      );

      await profileController.initialize();

      expect(profileController.state.username, 'Alex');
      profileController.dispose();
    });

    test(
      'saves edited username trimmed and falls back on empty input',
      () async {
        final _FakeProfileRepository repository = _FakeProfileRepository(
          storedUsername: 'Alex',
        );
        final ProfileController profileController = ProfileController(
          repository: repository,
        );

        await profileController.initialize();
        await profileController.updateUsername('  Mila  ');
        expect(profileController.state.username, 'Mila');
        expect(repository.savedUsernames, <String>['Mila']);

        await profileController.updateUsername('   ');
        expect(profileController.state.username, 'SudokuPlayer');
        expect(repository.savedUsernames, <String>['Mila', 'SudokuPlayer']);
        profileController.dispose();
      },
    );
  });
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.storedUsername});

  final String? storedUsername;
  final List<String> savedUsernames = <String>[];

  @override
  Future<String?> loadUsername() async => storedUsername;

  @override
  Future<void> saveUsername(String username) async {
    savedUsernames.add(username);
  }
}
