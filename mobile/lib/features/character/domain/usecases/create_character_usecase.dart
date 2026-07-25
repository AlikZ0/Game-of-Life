import '../../../../core/utils/result.dart';
import '../entities/character.dart';
import '../entities/character_class.dart';
import '../repositories/character_repository.dart';

class CreateCharacter {
  const CreateCharacter(this._repo);
  final CharacterRepository _repo;

  Future<Result<Character>> call({
    required String name,
    required CharacterClassType characterClass,
    required String avatarKey,
  }) =>
      _repo.createCharacter(
        name: name.trim(),
        characterClass: characterClass,
        avatarKey: avatarKey,
      );
}
