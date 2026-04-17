import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_session.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/student/shared/widgets/student_shell.dart';
import '../../features/teacher/shared/widgets/teacher_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthSessionChangeNotifier(ref),
    redirect: (context, state) {
      final loggedIn = session.isAuthenticated;
      final goingToLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingToLogin) return '/login';
      if (loggedIn && goingToLogin) {
        return session.role == 'teacher' ? '/teacher' : '/student';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, _) => const StudentShell(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, _) => const TeacherShell(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, _) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri.path}')),
    ),
  );
});

class _AuthSessionChangeNotifier extends ChangeNotifier {
  _AuthSessionChangeNotifier(Ref ref) {
    ref.listen(authSessionProvider, (prev, next) => notifyListeners());
  }
}
