import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_providers.dart';

/// Coarse auth lifecycle for router redirects + gating.
enum AuthStatus { unknown, unauthenticated, needsCharacter, authenticated }

@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool isSubmitting;
  final ApiException? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? isSubmitting,
    ApiException? error,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Central auth controller. Handles bootstrap (silent session restore), all
/// sign-in paths, and logout. The router watches [status] to redirect.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
    // React to forced sign-out (refresh failure) from the Dio client.
    _ref.listen<int>(unauthorizedSignalProvider, (_, __) => _forceSignOut());
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    final hasSession = await _ref.read(secureStorageProvider).hasSession;
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final result = await _ref.read(authRepositoryProvider).currentUser();
    state = result.fold(
      onSuccess: (user) => state.copyWith(status: _statusFor(user), user: user),
      onFailure: (_) => state.copyWith(status: AuthStatus.unauthenticated),
    );
  }

  AuthStatus _statusFor(AuthUser user) =>
      user.hasCharacter ? AuthStatus.authenticated : AuthStatus.needsCharacter;

  Future<bool> loginWithEmail(String email, String password) => _run(
        () => _ref.read(loginWithEmailProvider)(email: email, password: password),
      );

  Future<bool> register(String email, String password) => _run(
        () => _ref.read(registerWithEmailProvider)(email: email, password: password),
      );

  Future<bool> loginWithGoogle() => _run(() async {
        final account = await GoogleSignIn().signIn();
        if (account == null) {
          throw const ApiException(message: 'Google sign-in was cancelled.');
        }
        final auth = await account.authentication;
        final idToken = auth.idToken;
        if (idToken == null) {
          throw const ApiException(message: 'Google did not return an id token.');
        }
        return _ref.read(loginWithGoogleProvider)(idToken);
      });

  Future<bool> loginWithApple() => _run(() async {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: const [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final token = credential.identityToken;
        if (token == null) {
          throw const ApiException(message: 'Apple did not return an identity token.');
        }
        final name = [credential.givenName, credential.familyName]
            .whereType<String>()
            .join(' ')
            .trim();
        return _ref.read(loginWithAppleProvider)(
          identityToken: token,
          fullName: name.isEmpty ? null : name,
        );
      });

  /// Marks the account as having a character (called after creation flow).
  void markCharacterCreated() {
    final user = state.user;
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user == null
          ? null
          : AuthUser(
              id: user.id,
              email: user.email,
              provider: user.provider,
              emailVerified: user.emailVerified,
              hasCharacter: true,
            ),
    );
  }

  Future<void> logout() async {
    await _ref.read(logoutUseCaseProvider)();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> _forceSignOut() async {
    await _ref.read(secureStorageProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Shared runner for the various sign-in flows: toggles [isSubmitting],
  /// maps failures into [error], and returns whether auth succeeded.
  Future<bool> _run(Future<dynamic> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await action();
      // result is Result<AuthSession>
      final session = result.valueOrNull;
      if (session == null) {
        state = state.copyWith(isSubmitting: false, error: result.errorOrNull);
        return false;
      }
      state = state.copyWith(
        isSubmitting: false,
        status: _statusFor(session.user),
        user: session.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e);
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
