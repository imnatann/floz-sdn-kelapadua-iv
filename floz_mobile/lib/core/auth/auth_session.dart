import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSession {
  final dynamic user; // tightened to User? in Task 32 after entity exists
  final String? token;
  const AuthSession({this.user, this.token});

  bool get isAuthenticated => token != null && user != null;

  AuthSession copyWith({dynamic user, String? token}) =>
      AuthSession(user: user ?? this.user, token: token ?? this.token);

  static const empty = AuthSession();
}

class AuthSessionNotifier extends Notifier<AuthSession> {
  @override
  AuthSession build() => AuthSession.empty;

  void setSession(dynamic user, String token) {
    state = AuthSession(user: user, token: token);
  }

  void clear() {
    state = AuthSession.empty;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession>(AuthSessionNotifier.new);
