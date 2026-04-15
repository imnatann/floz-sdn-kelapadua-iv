import '../entities/user.dart';
import '../../../../core/error/result.dart';

abstract class AuthRepository {
  Future<Result<({User user, String token})>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<User>> me();
}
