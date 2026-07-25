import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Single-responsibility use cases that wrap [AuthRepository]. They keep the
/// controller thin and make the intended interactions explicit + testable.

class LoginWithEmail {
  const LoginWithEmail(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) =>
      _repo.loginWithEmail(email: email.trim(), password: password);
}

class RegisterWithEmail {
  const RegisterWithEmail(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) =>
      _repo.registerWithEmail(email: email.trim(), password: password);
}

class LoginWithGoogle {
  const LoginWithGoogle(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthSession>> call(String idToken) => _repo.loginWithGoogle(idToken);
}

class LoginWithApple {
  const LoginWithApple(this._repo);
  final AuthRepository _repo;

  Future<Result<AuthSession>> call({
    required String identityToken,
    String? fullName,
  }) =>
      _repo.loginWithApple(identityToken: identityToken, fullName: fullName);
}

class LogoutUseCase {
  const LogoutUseCase(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}
