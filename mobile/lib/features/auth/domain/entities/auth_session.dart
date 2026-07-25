import 'auth_user.dart';

/// The result of a successful authentication: the user plus their token pair.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
}
