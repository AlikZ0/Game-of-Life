import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../character/presentation/providers/character_providers.dart';
import '../../data/datasources/quest_remote_datasource.dart';
import '../../data/repositories_impl/quest_repository_impl.dart';
import '../../domain/entities/quest.dart';
import '../../domain/entities/quest_reward.dart';
import '../../domain/repositories/quest_repository.dart';
import '../../domain/usecases/complete_quest_usecase.dart';

// ── DI ────────────────────────────────────────────────────────────────────
final questRemoteDataSourceProvider = Provider<QuestRemoteDataSource>(
  (ref) => QuestRemoteDataSource(ref.watch(dioProvider)),
);

final questRepositoryProvider = Provider<QuestRepository>(
  (ref) => QuestRepositoryImpl(ref.watch(questRemoteDataSourceProvider)),
);

final completeQuestProvider =
    Provider((ref) => CompleteQuest(ref.watch(questRepositoryProvider)));

/// Selected cadence filter on the dashboard (null = all).
final questCadenceFilterProvider = StateProvider<String?>((ref) => null);

/// The dashboard's quest list. An [AsyncNotifier] so it can expose imperative
/// mutations (complete/create/archive) with optimistic updates + refresh.
class QuestsController extends AsyncNotifier<List<Quest>> {
  QuestRepository get _repo => ref.read(questRepositoryProvider);

  @override
  Future<List<Quest>> build() async {
    final cadence = ref.watch(questCadenceFilterProvider);
    final result = await _repo.getQuests(cadence: cadence);
    return result.fold(onSuccess: (q) => q, onFailure: (e) => throw e);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getQuests(
        cadence: ref.read(questCadenceFilterProvider),
      );
      return result.fold(onSuccess: (q) => q, onFailure: (e) => throw e);
    });
  }

  /// Optimistically marks a quest complete, then commits the reward. On failure
  /// the previous state is restored and the error rethrown for the UI.
  Future<QuestReward> complete(String questId) async {
    final previous = state.valueOrNull ?? const <Quest>[];
    state = AsyncValue.data([
      for (final q in previous)
        if (q.id == questId) q.copyWith(completedForPeriod: true) else q,
    ]);

    final result = await ref.read(completeQuestProvider)(questId);
    return result.fold(
      onSuccess: (reward) {
        // Character stats (XP/gold/level) changed — refresh the header.
        ref.invalidate(myCharacterProvider);
        return reward;
      },
      onFailure: (e) {
        state = AsyncValue.data(previous); // rollback
        throw e;
      },
    );
  }

  Future<void> create(QuestDraft draft) async {
    final result = await _repo.createQuest(draft);
    result.fold(
      onSuccess: (quest) {
        state = AsyncValue.data([quest, ...?state.valueOrNull]);
      },
      onFailure: (ApiException e) => throw e,
    );
  }

  Future<void> saveQuest(QuestDraft draft) async {
    final result = await _repo.updateQuest(draft);
    result.fold(
      onSuccess: (updated) {
        state = AsyncValue.data([
          for (final q in state.valueOrNull ?? const <Quest>[])
            if (q.id == updated.id) updated else q,
        ]);
      },
      onFailure: (ApiException e) => throw e,
    );
  }

  Future<void> archive(String questId) async {
    final previous = state.valueOrNull ?? const <Quest>[];
    state = AsyncValue.data(previous.where((q) => q.id != questId).toList());
    final result = await _repo.archiveQuest(questId);
    result.fold(
      onSuccess: (_) {},
      onFailure: (e) {
        state = AsyncValue.data(previous);
        throw e;
      },
    );
  }
}

final questsControllerProvider =
    AsyncNotifierProvider<QuestsController, List<Quest>>(QuestsController.new);
