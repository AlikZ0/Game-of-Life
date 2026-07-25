import '../../../../core/utils/result.dart';
import '../entities/character.dart';
import '../entities/character_class.dart';

abstract interface class CharacterRepository {
  /// Fetches the authenticated user's character (`/characters/me`).
  Future<Result<Character>> getMyCharacter();

  /// Creates the character during onboarding.
  Future<Result<Character>> createCharacter({
    required String name,
    required CharacterClassType characterClass,
    required String avatarKey,
  });
}
