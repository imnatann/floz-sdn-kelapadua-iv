import 'auth_session.dart';

class RoleGuard {
  /// Returns the redirect path if access is denied, else null.
  static String? guard({
    required AuthSession session,
    required String currentPath,
    required Set<String> allowedRoles,
  }) {
    if (!session.isAuthenticated) {
      return '/login';
    }
    final role = (session.user as dynamic)?.role as String?;
    if (role == null || !allowedRoles.contains(role)) {
      return '/login';
    }
    return null;
  }
}
