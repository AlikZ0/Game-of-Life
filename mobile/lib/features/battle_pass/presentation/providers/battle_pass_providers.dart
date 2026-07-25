import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/di.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/battle_pass.dart';

final battlePassProvider = FutureProvider<BattlePass>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.battlePass);
  final data = res.data ?? const {};

  return BattlePass(
    seasonName: data['seasonName'] as String? ?? 'Season 1',
    endAt: DateTime.tryParse(data['endAt'] as String? ?? '') ?? DateTime.now(),
    currentTier: (data['tier'] as num?)?.toInt() ?? 0,
    xp: (data['xp'] as num?)?.toInt() ?? 0,
    isPremium: data['isPremium'] as bool? ?? false,
    claimedTiers: [
      for (final t in (data['claimedTiers'] ?? const []) as List<dynamic>) (t as num).toInt(),
    ],
    tiers: [
      for (final t in (data['tiers'] ?? const []) as List<dynamic>)
        BattlePassTier(
          tier: (t['tier'] as num).toInt(),
          xpRequired: (t['xpRequired'] as num?)?.toInt() ?? 0,
          freeReward: t['freeReward']?['refKey'] as String?,
          premiumReward: t['premiumReward']?['refKey'] as String?,
        ),
    ],
  );
});
