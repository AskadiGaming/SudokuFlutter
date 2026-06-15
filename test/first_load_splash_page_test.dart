import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/app/startup/first_load_splash_page.dart';

void main() {
  testWidgets('shows progress and first-start hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FirstLoadSplashPage(
          progress: 0.5,
          message: 'Importiere mittlere Sudokus',
          isLoading: true,
        ),
      ),
    );

    expect(find.text('Sudoku wird vorbereitet'), findsOneWidget);
    expect(find.textContaining('ersten Start'), findsOneWidget);
    expect(find.text('Importiere mittlere Sudokus'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows retry button for errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLoadSplashPage(
          progress: 0.4,
          message: 'Importiere schwere Sudokus',
          isLoading: false,
          errorMessage: 'FormatException: kaputte Datei',
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Initialisierung fehlgeschlagen'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
    expect(find.textContaining('kaputte Datei'), findsOneWidget);
  });
}
