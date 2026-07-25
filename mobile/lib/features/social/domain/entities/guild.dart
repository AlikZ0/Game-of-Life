/// Domain entities for the social feature. Mirror Prisma `Guild`,
/// `GuildMember`, `GuildMission`, and `GuildMessage`.

class Guild {
  const Guild({
    required this.id,
    required this.name,
    required this.tag,
    this.description,
    required this.level,
    required this.memberCount,
    required this.members,
    required this.missions,
  });

  final String id;
  final String name;
  final String tag;
  final String? description;
  final int level;
  final int memberCount;
  final List<GuildMember> members;
  final List<GuildMission> missions;
}

class GuildMember {
  const GuildMember({
    required this.characterId,
    required this.name,
    required this.role,
    required this.weeklyXp,
    required this.level,
  });

  final String characterId;
  final String name;
  final String role; // LEADER | OFFICER | MEMBER
  final int weeklyXp;
  final int level;
}

class GuildMission {
  const GuildMission({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.metric,
    required this.rewardGold,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final int targetValue;
  final int currentValue;
  final String metric;
  final int rewardGold;
  final DateTime expiresAt;

  double get progress =>
      targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);
}

class GuildMessage {
  const GuildMessage({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
}
