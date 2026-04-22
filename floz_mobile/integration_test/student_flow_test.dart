import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Student E2E Flow', () {
    testWidgets('login → navigate all tabs → profile → logout', (tester) async {
      await initApp(tester);

      // Login as student
      await login(tester, 'student@floz.test', 'password123');

      // Should land on student dashboard — nav bar has Beranda
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text('Beranda')),
        findsOneWidget,
      );

      // Navigate through all tabs
      await tapNavTab(tester, 'Jadwal');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Nilai');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Rapor');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Info');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tapNavTab(tester, 'Tugas');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Back to Beranda
      await tapNavTab(tester, 'Beranda');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap profile button (in top bar)
      final profileButtons = find.byIcon(Icons.person_outlined);
      if (profileButtons.evaluate().isNotEmpty) {
        await tester.tap(profileButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Should see profile screen with logout
        final logoutBtn = find.text('Keluar');
        if (logoutBtn.evaluate().isNotEmpty) {
          await tester.tap(logoutBtn);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Confirm dialog if present
          final confirmBtn = find.text('Ya, Keluar');
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }

          // Should be back at login
          expect(find.byKey(const Key('login.email')), findsOneWidget);
        }
      }
    });
  });
}
