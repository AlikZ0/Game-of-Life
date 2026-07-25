import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/character_class.dart';
import 'character_providers.dart';

@immutable
class CharacterCreationState {
  const CharacterCreationState({
    this.name = '',
    this.selectedClass = CharacterClassType.ranger,
    this.avatarKey = 'avatar_01',
    this.isSubmitting = false,
    this.error,
    this.created = false,
  });

  final String name;
  final CharacterClassType selectedClass;
  final String avatarKey;
  final bool isSubmitting;
  final ApiException? error;
  final bool created;

  bool get canSubmit => name.trim().length >= 2 && !isSubmitting;

  CharacterCreationState copyWith({
    String? name,
    CharacterClassType? selectedClass,
    String? avatarKey,
    bool? isSubmitting,
    ApiException? error,
    bool? created,
    bool clearError = false,
  }) =>
      CharacterCreationState(
        name: name ?? this.name,
        selectedClass: selectedClass ?? this.selectedClass,
        avatarKey: avatarKey ?? this.avatarKey,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        created: created ?? this.created,
      );
}

class CharacterCreationController extends StateNotifier<CharacterCreationState> {
  CharacterCreationController(this._ref) : super(const CharacterCreationState());

  final Ref _ref;

  void setName(String value) => state = state.copyWith(name: value, clearError: true);
  void selectClass(CharacterClassType c) => state = state.copyWith(selectedClass: c);
  void selectAvatar(String key) => state = state.copyWith(avatarKey: key);

  /// Creates the character; returns true on success so the screen can trigger
  /// the auth transition + navigation.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _ref.read(createCharacterProvider)(
      name: state.name,
      characterClass: state.selectedClass,
      avatarKey: state.avatarKey,
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSubmitting: false, created: true);
        _ref.invalidate(myCharacterProvider);
        return true;
      },
      onFailure: (e) {
        state = state.copyWith(isSubmitting: false, error: e);
        return false;
      },
    );
  }
}

final characterCreationControllerProvider =
    StateNotifierProvider.autoDispose<CharacterCreationController, CharacterCreationState>(
  (ref) => CharacterCreationController(ref),
);
