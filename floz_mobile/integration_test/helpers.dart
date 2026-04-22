import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:floz_mobile/app.dart';

Future<void> initApp(WidgetTester tester) async {
  await Hive.initFlutter();
  await tester.pumpWidget(const ProviderScope(child: FlozApp()));
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester, String email, String password) async {
  final emailField = find.byKey(const Key('login.email'));
  final passwordField = find.byKey(const Key('login.password'));
  final submitBtn = find.byKey(const Key('login.submit'));

  expect(emailField, findsOneWidget);
  expect(passwordField, findsOneWidget);

  await tester.enterText(emailField, email);
  await tester.enterText(passwordField, password);
  await tester.tap(submitBtn);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> tapNavTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
  expect(tab, findsOneWidget);
  await tester.tap(tab);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}
