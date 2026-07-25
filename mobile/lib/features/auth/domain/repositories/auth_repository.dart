import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

/// Contract for authentication. Implemented in the data layer; consumed by
/// use cases and the auth controller.
abstract interface class AuthRepository {
  Future<Result<AuthSession>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> registerWithEmail({
    required String email,
    required String password,
  });

  /// Exchanges a Google id token for a Life Quest session.
  Future<Result<AuthSession>> loginWithGoogle(String idToken);

  /// Exchanges an Apple identity token (+ nonce) for a Life Quest session.
  Future<Result<AuthSession>> loginWithApple({
    required String identityToken,
    String? fullName,
  });

  /// Returns the current user if a valid session exists, else a failure.
  Future<Result<AuthUser>> currentUser();

  Future<void> logout();
}
