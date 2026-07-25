import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SecureStorage secureStorage,
  })  : _remote = remote,
        _secure = secureStorage;

  final AuthRemoteDataSource _remote;
  final SecureStorage _secure;

  Future<Result<AuthSession>> _authenticate(
    Future<AuthSession> Function() call,
  ) =>
      guardResult(() async {
        final session = await call();
        await _secure.saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        return session;
      });

  @override
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    required String password,
  }) =>
      _authenticate(() async => (await _remote.login(email, password)).toSession());

  @override
  Future<Result<AuthSession>> registerWithEmail({
    required String email,
    required String password,
  }) =>
      _authenticate(() async => (await _remote.register(email, password)).toSession());

  @override
  Future<Result<AuthSession>> loginWithGoogle(String idToken) =>
      _authenticate(() async => (await _remote.google(idToken)).toSession());

  @override
  Future<Result<AuthSession>> loginWithApple({
    required String identityToken,
    String? fullName,
  }) =>
      _authenticate(() async => (await _remote.apple(identityToken, fullName)).toSession());

  @override
  Future<Result<AuthUser>> currentUser() =>
      guardResult(() async => (await _remote.me()).toEntity());

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _secure.clear();
    }
  }
}
