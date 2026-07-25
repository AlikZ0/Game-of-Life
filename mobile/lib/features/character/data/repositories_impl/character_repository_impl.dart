import '../../../../core/storage/local_store.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/character_class.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/character_remote_datasource.dart';
import '../models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  const CharacterRepositoryImpl({
    required CharacterRemoteDataSource remote,
    required LocalStore localStore,
  })  : _remote = remote,
        _local = localStore;

  final CharacterRemoteDataSource _remote;
  final LocalStore _local;

  @override
  Future<Result<Character>> getMyCharacter() => guardResult(() async {
        final model = await _remote.me();
        // Cache a snapshot for optimistic/offline reads.
        await _local.cacheCharacter(model.toJson());
        return model.toEntity();
      });

  @override
  Future<Result<Character>> createCharacter({
    required String name,
    required CharacterClassType characterClass,
    required String avatarKey,
  }) =>
      guardResult(() async {
        final model = await _remote.create(
          name: name,
          characterClass: characterClass.apiValue,
          avatarKey: avatarKey,
        );
        await _local.cacheCharacter(model.toJson());
        return model.toEntity();
      });

  /// Reads the last cached character (offline fallback), if any.
  Character? cachedCharacter() {
    final json = _local.cachedCharacter;
    return json == null ? null : CharacterModel.fromJson(json).toEntity();
  }
}
