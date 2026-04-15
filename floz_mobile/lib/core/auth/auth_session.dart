import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user.dart';

class AuthSession {
  final User? user;
  final String? token;
  const AuthSession({this.user, this.token});

  bool get isAuthenticated => token != null && user != null;
  String? get role => user?.role;

  AuthSession copyWith({User? user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  static const empty = AuthSession();
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.empty;

  void setSession(User user, String token) {
    state = AuthSession(user: user, token: token);
  }

  void clear() {
    state = AuthSession.empty;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
