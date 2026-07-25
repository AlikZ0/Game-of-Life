import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories_impl/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

/// DI wiring for the auth feature.

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  ),
);

final loginWithEmailProvider =
    Provider((ref) => LoginWithEmail(ref.watch(authRepositoryProvider)));
final registerWithEmailProvider =
    Provider((ref) => RegisterWithEmail(ref.watch(authRepositoryProvider)));
final loginWithGoogleProvider =
    Provider((ref) => LoginWithGoogle(ref.watch(authRepositoryProvider)));
final loginWithAppleProvider =
    Provider((ref) => LoginWithApple(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider =
    Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
