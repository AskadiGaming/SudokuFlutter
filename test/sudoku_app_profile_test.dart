import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/app/app.dart';
import 'package:hello_world_app/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile icon opens profile page directly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const SudokuApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Profil oeffnen'), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('SudokuPlayer'), findsAtLeastNWidgets(1));
  });
}
