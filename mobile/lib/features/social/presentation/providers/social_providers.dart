import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/guild.dart';
import '../../domain/entities/pvp_challenge.dart';

/// The authenticated character's guild, if they belong to one. Returns null
/// when the user is not in a guild (404 mapped to null).
final myGuildProvider = FutureProvider<Guild?>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.guildMe);
  final data = res.data;
  if (data == null || data.isEmpty) return null;

  return Guild(
    id: data['id'] as String,
    name: data['name'] as String,
    tag: data['tag'] as String? ?? '',
    description: data['description'] as String?,
    level: (data['level'] as num?)?.toInt() ?? 1,
    memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
    members: [
      for (final m in (data['members'] ?? const []) as List<dynamic>)
        GuildMember(
          characterId: m['characterId'] as String,
          name: m['name'] as String? ?? 'Member',
          role: m['role'] as String? ?? 'MEMBER',
          weeklyXp: (m['weeklyXp'] as num?)?.toInt() ?? 0,
          level: (m['level'] as num?)?.toInt() ?? 1,
        ),
    ],
    missions: [
      for (final m in (data['missions'] ?? const []) as List<dynamic>)
        GuildMission(
          id: m['id'] as String,
          title: m['title'] as String,
          targetValue: (m['targetValue'] as num).toInt(),
          currentValue: (m['currentValue'] as num?)?.toInt() ?? 0,
          metric: m['metric'] as String? ?? 'XP',
          rewardGold: (m['rewardGold'] as num?)?.toInt() ?? 0,
          expiresAt: DateTime.tryParse(m['expiresAt'] as String? ?? '') ?? DateTime.now(),
        ),
    ],
  );
});

/// The user's active/pending PvP challenges.
final pvpChallengesProvider = FutureProvider<List<PvpChallenge>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.pvpChallenges);
  final items = (res.data?['data'] ?? const []) as List<dynamic>;
  return [
    for (final c in items)
      PvpChallenge(
        id: c['id'] as String,
        opponentName: c['opponentName'] as String? ?? 'Rival',
        metric: c['metric'] as String? ?? 'XP',
        status: c['status'] as String? ?? 'ACTIVE',
        challengerScore: (c['challengerScore'] as num?)?.toInt() ?? 0,
        opponentScore: (c['opponentScore'] as num?)?.toInt() ?? 0,
        endAt: DateTime.tryParse(c['endAt'] as String? ?? '') ?? DateTime.now(),
        isChallenger: c['isChallenger'] as bool? ?? true,
      ),
  ];
});
