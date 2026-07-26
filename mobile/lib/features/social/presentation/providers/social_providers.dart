import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/guild.dart';
import '../../domain/entities/pvp_challenge.dart';

/// The authenticated character's guild, if they belong to one. Returns null
/// when the user is not in a guild.
///
/// The backend exposes no `GET /guilds/me`; membership is surfaced through the
/// character profile, so until that wiring lands this resolves to "no guild"
/// and the screen renders its join/create empty state.
final myGuildProvider = FutureProvider<Guild?>((ref) async => null);

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
