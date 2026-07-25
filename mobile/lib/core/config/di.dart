import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/local_store.dart';
import '../storage/secure_storage.dart';

/// ── Infrastructure providers ────────────────────────────────────────────────
///
/// These are the composition root of the app. Feature repositories read [dioProvider]
/// and datasources, keeping construction wiring in one place.

/// Overridden in `main.dart` after [LocalStore.init] completes.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden in ProviderScope'),
);

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

/// Emits when a session becomes invalid (refresh failed). The auth controller
/// listens to force a logout + redirect.
final unauthorizedSignalProvider = StateProvider<int>((ref) => 0);

final dioClientProvider = Provider<DioClient>((ref) {
  final client = DioClient(
    secureStorage: ref.watch(secureStorageProvider),
    onUnauthorized: () async {
      // Bump the signal; router's refreshListenable reacts and redirects.
      ref.read(unauthorizedSignalProvider.notifier).state++;
    },
  );
  ref.onDispose(client.dio.close);
  return client;
});

final dioProvider = Provider<Dio>((ref) => ref.watch(dioClientProvider).dio);
