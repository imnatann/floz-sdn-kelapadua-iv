import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Edge Cases', () {
    testWidgets('empty fields show validation errors', (tester) async {
      await initApp(tester);

      // Tap submit without filling fields
      final submitBtn = find.byKey(const Key('login.submit'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });

    testWidgets('invalid email format shows error', (tester) async {
      await initApp(tester);

      await tester.enterText(find.byKey(const Key('login.email')), 'notanemail');
      await tester.enterText(find.byKey(const Key('login.password')), 'password');
      await tester.tap(find.byKey(const Key('login.submit')));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('wrong credentials show snackbar error', (tester) async {
      await initApp(tester);

      await login(tester, 'wrong@email.com', 'wrongpassword');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should still be on login screen
      expect(find.byKey(const Key('login.email')), findsOneWidget);
    });

    testWidgets('short password shows validation error', (tester) async {
      await initApp(tester);

      await tester.enterText(find.byKey(const Key('login.email')), 'test@test.com');
      await tester.enterText(find.byKey(const Key('login.password')), '123');
      await tester.tap(find.byKey(const Key('login.submit')));
      await tester.pumpAndSettle();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
    });
  });
}
