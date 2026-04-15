import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:floz_mobile/core/error/failure.dart';
import 'package:floz_mobile/core/error/result.dart';
import 'package:floz_mobile/features/auth/domain/entities/user.dart';
import 'package:floz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:floz_mobile/features/auth/presentation/login_screen.dart';
import 'package:floz_mobile/features/auth/providers/auth_providers.dart';

class _MockRepo extends Mock implements AuthRepository {}

Widget _wrapWithRouter(_MockRepo repo) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) =>
            const Scaffold(body: Text('Student Page')),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) =>
            const Scaffold(body: Text('Teacher Page')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(_wrapWithRouter(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('calls repository on valid submit', (tester) async {
    const user = User(
      id: 1,
      name: 'A',
      email: 'a@b.co',
      role: 'student',
      isActive: true,
    );
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => Success((user: user, token: 'tok')),
    );

    await tester.pumpWidget(_wrapWithRouter(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login.email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('login.password')), 'rahasia');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump(); // schedule async work — stop before navigation settles

    verify(
      () => repo.login(email: 'a@b.co', password: 'rahasia'),
    ).called(1);
  });

  testWidgets('shows snackbar on auth failure', (tester) async {
    when(
      () => repo.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async =>
          FailureResult(const AuthFailure('Email atau password salah.')),
    );

    await tester.pumpWidget(_wrapWithRouter(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('login.email')), 'a@b.co');
    await tester.enterText(find.byKey(const Key('login.password')), 'rahasia');
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah.'), findsOneWidget);
  });
}
