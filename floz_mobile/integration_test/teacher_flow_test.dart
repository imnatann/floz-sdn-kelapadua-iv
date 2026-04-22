import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Teacher E2E Flow', () {
    testWidgets('login → navigate Kelas/Nilai/Rekap tabs → profile', (tester) async {
      await initApp(tester);

      // Login as teacher
      await login(tester, 'teacher@floz.test', 'password123');

      // Should land on teacher shell — nav bar has Kelas
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text('Kelas')),
        findsOneWidget,
      );

      // Navigate tabs
      await tapNavTab(tester, 'Nilai');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Rekap');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Back to Kelas
      await tapNavTab(tester, 'Kelas');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap profile
      final profileButtons = find.byIcon(Icons.person_outlined);
      if (profileButtons.evaluate().isNotEmpty) {
        await tester.tap(profileButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify profile screen loaded
        expect(find.text('Keluar'), findsOneWidget);
      }
    });
  });
}
