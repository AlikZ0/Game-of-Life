import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../data/datasources/character_remote_datasource.dart';
import '../../data/repositories_impl/character_repository_impl.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/usecases/create_character_usecase.dart';

final characterRemoteDataSourceProvider = Provider<CharacterRemoteDataSource>(
  (ref) => CharacterRemoteDataSource(ref.watch(dioProvider)),
);

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => CharacterRepositoryImpl(
    remote: ref.watch(characterRemoteDataSourceProvider),
    localStore: ref.watch(localStoreProvider),
  ),
);

final createCharacterProvider =
    Provider((ref) => CreateCharacter(ref.watch(characterRepositoryProvider)));

/// The authenticated user's character. Screens read this for the header stats
/// (level, XP, gold, HP, energy). Refreshed after quest/boss rewards.
final myCharacterProvider = FutureProvider<Character>((ref) async {
  final result = await ref.watch(characterRepositoryProvider).getMyCharacter();
  return result.fold(
    onSuccess: (c) => c,
    onFailure: (e) => throw e,
  );
});
