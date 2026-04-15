import 'auth_session.dart';

class RoleGuard {
  static String? guard({
    required AuthSession session,
    required String currentPath,
    required Set<String> allowedRoles,
  }) {
    if (!session.isAuthenticated) {
      return '/login';
    }
    final role = session.user?.role;
    if (role == null || !allowedRoles.contains(role)) {
      return '/login';
    }
    return null;
  }
}
