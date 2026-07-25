/// Domain entity for a PvP challenge. Mirrors Prisma `PvpChallenge`.
class PvpChallenge {
  const PvpChallenge({
    required this.id,
    required this.opponentName,
    required this.metric,
    required this.status,
    required this.challengerScore,
    required this.opponentScore,
    required this.endAt,
    this.isChallenger = true,
  });

  final String id;
  final String opponentName;
  final String metric; // XP | QUESTS_COMPLETED | STUDY_MINUTES | ...
  final String status; // PENDING | ACTIVE | FINISHED | CANCELLED
  final int challengerScore;
  final int opponentScore;
  final DateTime endAt;
  final bool isChallenger;

  int get myScore => isChallenger ? challengerScore : opponentScore;
  int get theirScore => isChallenger ? opponentScore : challengerScore;
  bool get isWinning => myScore >= theirScore;
  bool get isActive => status == 'ACTIVE';
}
