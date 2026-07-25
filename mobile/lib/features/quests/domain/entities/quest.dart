import 'quest_enums.dart';

/// Domain entity for a Quest. Mirrors the Prisma `Quest` model. Reward preview
/// helpers apply the difficulty multiplier the backend uses at completion time.
class Quest {
  const Quest({
    required this.id,
    required this.title,
    this.description,
    required this.cadence,
    required this.difficulty,
    required this.status,
    required this.xpReward,
    required this.goldReward,
    this.skillKey,
    required this.energyCost,
    this.bossId,
    required this.damage,
    this.dueAt,
    this.completedForPeriod = false,
  });

  final String id;
  final String title;
  final String? description;
  final QuestCadence cadence;
  final QuestDifficulty difficulty;
  final QuestStatus status;

  final int xpReward;
  final int goldReward;
  final String? skillKey;
  final int energyCost;

  final String? bossId;
  final int damage;
  final DateTime? dueAt;

  /// Whether the quest is already completed for the current period (day/week/
  /// month). Drives the checkbox state on the dashboard.
  final bool completedForPeriod;

  bool get isLinkedToBoss => bossId != null;

  /// XP actually awarded once the difficulty multiplier is applied.
  int get scaledXp => (xpReward * difficulty.multiplier).round();
  int get scaledGold => (goldReward * difficulty.multiplier).round();

  Quest copyWith({QuestStatus? status, bool? completedForPeriod}) => Quest(
        id: id,
        title: title,
        description: description,
        cadence: cadence,
        difficulty: difficulty,
        status: status ?? this.status,
        xpReward: xpReward,
        goldReward: goldReward,
        skillKey: skillKey,
        energyCost: energyCost,
        bossId: bossId,
        damage: damage,
        dueAt: dueAt,
        completedForPeriod: completedForPeriod ?? this.completedForPeriod,
      );
}

/// Draft used by the create/edit sheet before it becomes a persisted [Quest].
class QuestDraft {
  const QuestDraft({
    this.id,
    this.title = '',
    this.description,
    this.cadence = QuestCadence.daily,
    this.difficulty = QuestDifficulty.medium,
    this.skillKey,
    this.bossId,
  });

  final String? id;
  final String title;
  final String? description;
  final QuestCadence cadence;
  final QuestDifficulty difficulty;
  final String? skillKey;
  final String? bossId;

  bool get isEditing => id != null;

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'cadence': cadence.apiValue,
        'difficulty': difficulty.apiValue,
        if (skillKey != null) 'skillKey': skillKey,
        if (bossId != null) 'bossId': bossId,
      };

  QuestDraft copyWith({
    String? title,
    String? description,
    QuestCadence? cadence,
    QuestDifficulty? difficulty,
    String? skillKey,
    String? bossId,
  }) =>
      QuestDraft(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        cadence: cadence ?? this.cadence,
        difficulty: difficulty ?? this.difficulty,
        skillKey: skillKey ?? this.skillKey,
        bossId: bossId ?? this.bossId,
      );
}
